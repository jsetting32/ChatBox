//
//  MainWindowController.m
//  Client
//
//  Created by John Setting on 12/14/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import "MainWindowController.h"
#import "GCDAsyncSocket.h"

#define WELCOME_MSG         0
#define ECHO_MSG            1
#define WARNING_MSG         2
#define BROADCAST_MSG       3
#define DISPLAYNAME_MSG     4
#define LIST_FRIENDS_MSG	5

#define READ_TIMEOUT			60.0 * 60.0		// 60 mins
#define READ_TIMEOUT_EXTENSION	60.0 * 5.0		// 5 mins

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

@interface MainWindowController ()

@end

@implementation MainWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        socketQueue = dispatch_queue_create("socketQueue", NULL);
        selfSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [[self window] setBackgroundColor:[NSColor yellowColor]];
}

- (void)awakeFromNib
{
    [self setIsRunning:NO];
}


- (IBAction)connectAction:(id)sender
{
    if(!isRunning) {
        
		NSError *error = nil;
		if(![selfSocket connectToHost:[(LoginViewController *)subViewController getHostField] onPort:[(LoginViewController *)subViewController getPortField] error:&error]) {
			NSLog(@"Error connecting to host: %@ on port %li with error %@", [(LoginViewController *)subViewController getHostField], (long)[(LoginViewController *)subViewController getPortField], error);
			return;
		}
        
        [self setIsRunning:YES];
        [connectButton setTitle:@"Disconnect"];
        
    } else {
        
		[selfSocket disconnect];
        [self setIsRunning:NO];
        [connectButton setTitle:@"Connect"];

	}
}


- (void)setIsRunning:(BOOL)running
{
    isRunning = running;
    [self changeViewController:running];
}

// -----------------------------------------------------------------------------------
//	Change the current NSViewController to a new one based on a parameter isConnected.
// -----------------------------------------------------------------------------------
- (void)changeViewController:(BOOL)isConnected
{
	// we are about to change the current view controller,
	// this prepares our title's value binding to change with it
	[self willChangeValueForKey:@"viewController"];
	
	if ([subViewController view] != nil)
		[[subViewController view] removeFromSuperview];	// remove the current view
    
	if (!isConnected) {
        _loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        if (_loginViewController != nil) {
            subViewController = _loginViewController;	// keep track of the current view controller
            [subViewController setTitle:@"Login"];
        }
    } else {
        _mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil socket:selfSocket ownerName:[(LoginViewController *)subViewController getDisplayNameField]];
        if (_mainViewController != nil) {
            subViewController = _mainViewController;	// keep track of the current view controller
            [subViewController setTitle:@"Main"];
        }
        [selfSocket readDataWithTimeout:-1 tag:0];
    }
    
	// embed the current view to our host view
	[subView addSubview: [subViewController view]];
	
	// make sure we automatically resize the controller's view to the current window size
	[[subViewController view] setFrame: [subView bounds]];
	
	// set the view controller's represented object to the number of subviews in that controller
	// (our NSTextField's value binding will reflect this value)
	[subViewController setRepresentedObject:[NSNumber numberWithLong:[[[subViewController view] subviews] count]]];
	
	[self didChangeValueForKey:@"viewController"];	// this will trigger the NSTextField's value binding to change
}


#pragma mark - GCDAsyncSocket Delegate Methods

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"Successful connection to host: %@ on port %hu", host , port);
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag {
    dispatch_async(dispatch_get_main_queue(), ^{
		@autoreleasepool {
			NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 1)];
            NSString* message = [NSString stringWithUTF8String:[strData bytes]];
			if (message) {
                [self processMessage:message socket:sender];
			} else {
				[self.mainViewController logError:@"Error converting received data into UTF-8 String" view:[self.mainViewController getActivityView]];
			}
		}
	});
}

- (void) processMessage:(NSString *)message socket:(GCDAsyncSocket *)sock {
    [self.mainViewController logMessage:message view:[self.mainViewController getActivityView]];
    [sock readDataWithTimeout:-1 tag:0];
}

/**
 * Called when a socket has read in data, but has not yet completed the read.
 * This would occur if using readToData: or readToLength: methods.
 * It may be used to for things such as updating progress bars.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    NSLog(@"Did Read Partial Data of Length:%lu with tag:%ld", (unsigned long)partialLength, tag);

}

/**
 * Called when a socket has completed writing the requested data. Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"Did Write Data with Tag: %ld", tag);
    [sock readDataWithTimeout:-1 tag:0];
}

/**
 * Called when a socket has written some data, but has not yet completed the entire write.
 * It may be used to for things such as updating progress bars.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    NSLog(@"Did Write Partial Data of Length: %lu with Tag: %ld", (unsigned long)partialLength, tag);
    [sock readDataWithTimeout:-1 tag:0];
}

/**
 * Called if a read operation has reached its timeout without completing.
 * This method allows you to optionally extend the timeout.
 * If you return a positive time interval (> 0) the read's timeout will be extended by the given amount.
 * If you don't implement this method, or return a non-positive time interval (<= 0) the read will timeout as usual.
 *
 * The elapsed parameter is the sum of the original timeout, plus any additions previously added via this method.
 * The length parameter is the number of bytes that have been read so far for the read operation.
 *
 * Note that this method may be called multiple times for a single read if you return positive numbers.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    NSLog(@"Should Timeout Read with Tag: %ld elapsed: %f bytesDone: %lu", tag, elapsed, (unsigned long)length);
    return elapsed;
}
/**
 * Called if a write operation has reached its timeout without completing.
 * This method allows you to optionally extend the timeout.
 * If you return a positive time interval (> 0) the write's timeout will be extended by the given amount.
 * If you don't implement this method, or return a non-positive time interval (<= 0) the write will timeout as usual.
 *
 * The elapsed parameter is the sum of the original timeout, plus any additions previously added via this method.
 * The length parameter is the number of bytes that have been written so far for the write operation.
 *
 * Note that this method may be called multiple times for a single write if you return positive numbers.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    NSLog(@"Should Timeout Write with Tag: %ld elapsed: %f bytesDone: %lu", tag, elapsed, (unsigned long)length);
    return elapsed;
}

/**
 * Conditionally called if the read stream closes, but the write stream may still be writeable.
 *
 * This delegate method is only called if autoDisconnectOnClosedReadStream has been set to NO.
 * See the discussion on the autoDisconnectOnClosedReadStream method for more information.
 **/
- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    NSLog(@"Socket Did Close Read Stream on socket: %@", sock);
}

/**
 * Called when a socket disconnects with or without error.
 *
 * If you call the disconnect method, and the socket wasn't already disconnected,
 * this delegate method will be called before the disconnect method returns.
 **/
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    if (err) {
        NSLog(@"Error disconnecting socket: %@ with error: %@", sock, err);
    } else {
        NSLog(@"Socket %@ successfully disconnected!", sock);
    }
}


/**
 * Called after the socket has successfully completed SSL/TLS negotiation.
 * This method is not called unless you use the provided startTLS method.
 *
 * If a SSL/TLS negotiation fails (invalid certificate, etc) then the socket will immediately close,
 * and the socketDidDisconnect:withError: delegate method will be called with the specific SSL error code.
 **/
- (void)socketDidSecure:(GCDAsyncSocket *)sock {
    NSLog(@"Socket %@ successfully completed SSL/TLS negotiation.", sock);

}


@end
