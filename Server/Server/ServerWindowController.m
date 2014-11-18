//
//  ServerWindowController.m
//  Server
//
//  Created by John Setting on 12/11/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import "ServerWindowController.h"
#import "GradientLayer.h"

#define WELCOME_MSG		0
#define ECHO_MSG		1
#define WARNING_MSG		2
#define BROADCAST_MSG	3
#define HELP_MSG        4
#define ADMIN_MSG       5

#define READ_TIMEOUT			60.0 * 60.0		// 60 mins
#define READ_TIMEOUT_EXTENSION	60.0 * 5.0		// 5 mins

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

@interface ServerWindowController (PrivateAPI)

- (void)logError:(NSString *)msg window:(id)window;
- (void)logInfo:(NSString *)msg window:(id)window;
- (void)logMessage:(NSString *)msg window:(id)window withSock:(id)sock;
- (void)logAdminMessage:(NSString *)msg window:(id)window;

@end

@interface ServerWindowController ()

@end

@implementation ServerWindowController
@synthesize startingColor;
@synthesize endingColor;
@synthesize angle;

- (id)initWithWindowNibName:(NSString *)windowNibName {
    if (self = [super initWithWindowNibName:windowNibName]) {
        //[DDLog addLogger:[DDTTYLogger sharedInstance]];
		socketQueue = dispatch_queue_create("socketQueue", NULL);
		mainSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
		connectedClients = [[NSMutableArray alloc] initWithCapacity:1];
        chatRooms = [NSMutableDictionary dictionary];
        [chatRooms setObject:[NSMutableArray array] forKey:@"Lobby"];
		isRunning = NO;

    }
    return self;
}

- (void)awakeFromNib
{
	[logView setString:@""];
    [logView setEditable:NO];
    [clientsView setEditable:NO];
    [chatRoomsView setEditable:NO];
}

- (void) windowDidLoad
{
    [super windowDidLoad];
    [[self window] setBackgroundColor:[NSColor blueColor]];
}

- (IBAction)startStop:(id)sender
{
	if(!isRunning) {
        
		int port = [portField intValue];
		
		if (port < 0 || port > 65535) {
			[portField setStringValue:@""];
			port = 0;
		}
		
		NSError *error = nil;
		if(![mainSocket acceptOnPort:port error:&error]) {
			[self logError:FORMAT(@"Error starting server: %@", error) window:logView];
			return;
		}
		
        NSMutableString * chatRoomsStringForLog = [NSMutableString string];
        for(NSString *key in chatRooms) {
            NSString *formattedString = [NSString stringWithFormat:@"%@\n", key];
            [chatRoomsStringForLog appendString:formattedString];
        }
        [self logMessage:chatRoomsStringForLog window:chatRoomsView withSock:nil];
		[self logInfo:FORMAT(@"Server started on port %hu with host address %@", [mainSocket localPort], [mainSocket localHost]) window:logView];
		isRunning = YES;
		
		[portField setEnabled:NO];
		[startStopButton setTitle:@"Stop"];
        
    } else {
        
        // Stop accepting connections
		[mainSocket disconnect];
		
		// Stop any client connections
		@synchronized(connectedClients)
		{
			NSUInteger i;
			for (i = 0; i < [connectedClients count]; i++)
			{
				// Call disconnect on the socket,
				// which will invoke the socketDidDisconnect: method,
				// which will remove the socket from the list.
				[[connectedClients objectAtIndex:i] disconnect];
			}
		}
        
        //[self logMessage:@"" window:clientsView];
        [self logMessage:@"" window:chatRoomsView withSock:nil];
        [self logInfo:@"Stopped Server" window:logView];
        
        isRunning = false;
		
		[portField setEnabled:YES];
		[startStopButton setTitle:@"Start"];
	}
}


#pragma mark - GCDAsyncSocket Delegate Methods

/**
 * This method is called immediately prior to socket:didAcceptNewSocket:.
 * It optionally allows a listening socket to specify the socketQueue for a new accepted socket.
 * If this method is not implemented, or returns NULL, the new accepted socket will create its own default queue.
 *
 * Since you cannot autorelease a dispatch_queue,
 * this method uses the "new" prefix in its name to specify that the returned queue has been retained.
 *
 * Thus you could do something like this in the implementation:
 * return dispatch_queue_create("MyQueue", NULL);
 *
 * If you are placing multiple sockets on the same queue,
 * then care should be taken to increment the retain count each time this method is invoked.
 *
 * For example, your implementation might look something like this:
 * dispatch_retain(myExistingQueue);
 * return myExistingQueue;
 **/
- (dispatch_queue_t)newSocketQueueForConnectionFromAddress:(NSData *)address onSocket:(GCDAsyncSocket *)sock {
    NSLog(@"New Socket Queue For Connection From Address:%@ on socket:%@", address, sock);

    return socketQueue;
}

/**
 * Called when a socket accepts a connection.
 * Another socket is automatically spawned to handle it.
 *
 * You must retain the newSocket if you wish to handle the connection.
 * Otherwise the newSocket instance will be released and the spawned connection will be closed.
 *
 * By default the new socket will have the same delegate and delegateQueue.
 * You may, of course, change this at any time.
 **/
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
	// This method is executed on the socketQueue (not the main thread)
	
	@synchronized(connectedClients) {
        [connectedClients addObject:newSocket];
	}
    
	NSString *host = [newSocket connectedHost];
	UInt16 port = [newSocket connectedPort];
	dispatch_async(dispatch_get_main_queue(), ^{
		@autoreleasepool {
			[self logInfo:FORMAT(@"Accepted client %@:%hu", host, port) window:logView];
            NSString * result = [connectedClients componentsJoinedByString:@"\n"];
            [self logInfo:result window:clientsView];
		}
	});
	
	NSString *welcomeMsg = @"\r\nWelcome to the Server!\r\nTo distinguish yourself from others type '/user followed by the name you would like others to see you as.\r\nNote: The name cannot have spaces.\r\nEx. /user someDisplayName\r\n";
	NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
	
	[newSocket writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
	[newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
}

/**
 * Called when a socket disconnects with or without error.
 *
 * If you call the disconnect method, and the socket wasn't already disconnected,
 * this delegate method will be called before the disconnect method returns.
 **/
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    
    @synchronized(connectedClients) {
        [connectedClients removeObject:sock];
	}
    
	NSString *host = [sock connectedHost];
	UInt16 port = [sock connectedPort];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		@autoreleasepool {
			[self logError:FORMAT(@"Client %@:%hu has left the server", host, port) window:logView];
            NSString * clients = [connectedClients componentsJoinedByString:@"\n"];
            [self logInfo:clients window:clientsView];
		}
	});
    
    if ([err isKindOfClass:[NSNull class]]) {
        NSLog(@"Error when disconnecting Socket:%@\n", sock);
    } else {
        NSLog(@"Socket disconnected:%@", sock);
    }
    
}

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 *
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
}
 */
 
/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
   
	// This method is executed on the socketQueue (not the main thread)
	dispatch_async(dispatch_get_main_queue(), ^{
		@autoreleasepool {
			NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
			NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
            NSLog(@"Did Read data from socket: \"%@\" with tag:%ld", msg, tag);
            if (msg) {
                [self processMessage:msg socket:sock];
			} else {
				[self logError:@"Error converting received data into UTF-8 String" window:logView];
			}
		}
	});
	[sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
}

- (void)processMessage:(NSString*)message socket:(GCDAsyncSocket *)sock {
    
    [self logMessage:message window:logView withSock:sock];
    
    if ([message length] == 0) {
        return;
    }
    
    NSString *checker = [message substringToIndex:1];
    if ([checker isEqualToString:@"/"]) {
        if ([message length] == 1) {
            [self errorCommand:message withSock:sock];
        } else if ([message length] == 4) {

            if ([[message substringToIndex:4] isEqualToString:@"/bye"]) [sock disconnect];
            else [self errorCommand:message withSock:sock];
        
        } else if ([message length] == 5){
            
            NSString *cmd = [message substringToIndex:5];
            if ([cmd isEqualToString:@"/help"]) {
            
                [sock writeData:[self help] withTimeout:-1 tag:HELP_MSG];
            
            } else if ([cmd isEqualToString:@"/shut"]) {
            
                NSString *message = @"/shut is not implemented yet\n";
                NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
                [sock writeData:data withTimeout:-1 tag:HELP_MSG];
            
            } else if ([cmd isEqualToString:@"/lssu"]) {
                [self listSubscribedChatrooms:message withSock:sock];
            } else if ([cmd isEqualToString:@"/lsrc"]) {
                [self listChatrooms:message withSock:sock];
            } else if ([cmd isEqualToString:@"/read"]) {
                NSString *message = @"/read is not implemented yet\n";
                NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
                [sock writeData:data withTimeout:-1 tag:HELP_MSG];
            } else if ([cmd isEqualToString:@"/writ"]) {
                NSString *message = @"/writ is not implemented yet\n";
                NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
                [sock writeData:data withTimeout:-1 tag:HELP_MSG];
            } else {
                [self errorCommand:message withSock:sock];
            }
        } else if ([message length] > 5) {
            if ([[message substringToIndex:5] isEqualToString:@"/user"]) {
                [self assignUsername:message withSock:sock];
			} else if ([[message substringToIndex:5] isEqualToString:@"/crea"]) {
                [self createChatroom:message withSock:sock];
            } else if ([[message substringToIndex:5] isEqualToString:@"/subs"]) {
                [self subscribeUser:message withSock:sock];
            } else if ([[message substringToIndex:5] isEqualToString:@"/unsu"]) {
                [self unsubscribeUser:message withSock:sock];
            } else if ([[message substringToIndex:5] isEqualToString:@"/defa"]) {
                [self defaultChatroom:message withSock:sock];
            } else if ([[message substringToIndex:8] isEqualToString:@"/whisper"]) {
                [self whisperUser:message withSock:sock];
            } else if ([[message substringToIndex:8] isEqualToString:@"/lstusrs"]) {
                [self listUsers:sock];
            } else {
                [self errorCommand:message withSock:sock];
            }
        } else {
            [self errorCommand:message withSock:sock];
        }
        return;
    }
    
    // If the data sent from the client is not a command,
    // echo the message to all other clients in the same
    // chatroom as the one who sent the message.
    [self echoMessage:message withSock:sock];
}

/**
 * Called when a socket has read in data, but has not yet completed the read.
 * This would occur if using readToData: or readToLength: methods.
 * It may be used to for things such as updating progress bars.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    NSLog(@"Did Read Partial Data from Length from socket: %lu\nwith tag:%ld", (unsigned long)partialLength, tag);
}

/**
 * Called when a socket has completed writing the requested data. Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"Did Write Data with tag:%ld", tag);
    
    if (tag == ECHO_MSG) {
        
		[sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
	
    } else if (tag == WARNING_MSG) {
        
    } else if (tag == HELP_MSG) {
        
    } else if (tag == ECHO_MSG) {
        
    } else if (tag == ECHO_MSG) {
        
    }
}

/**
 * Called when a socket has written some data, but has not yet completed the entire write.
 * It may be used to for things such as updating progress bars.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    NSLog(@"Did Read Partial Data from Length from socket: %lu\nwith tag:%ld", (unsigned long)partialLength, tag);
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
    NSLog(@"Socket should timeout read operation with tag:%lu\nelapsed:%f\nbytes done:%lu", tag, elapsed, (unsigned long)length);
	if (elapsed <= READ_TIMEOUT)
	{
		NSString *warningMsg = @"Are you still there?\r\n";
		NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
		
		[sock writeData:warningData withTimeout:-1 tag:WARNING_MSG];
		
		return READ_TIMEOUT_EXTENSION;
	}
	
	return 0.0;}

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
    NSLog(@"Socket should timeout write operation with tag:%lu\nelapsed:%f\nbytes done:%lu", tag, elapsed, (unsigned long)length);
    return 1;
}

/**
 * Conditionally called if the read stream closes, but the write stream may still be writeable.
 *
 * This delegate method is only called if autoDisconnectOnClosedReadStream has been set to NO.
 * See the discussion on the autoDisconnectOnClosedReadStream method for more information.
 **/
- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    NSLog(@"Socket:%@ closed read stream!", sock);
}

/**
 * Called after the socket has successfully completed SSL/TLS negotiation.
 * This method is not called unless you use the provided startTLS method.
 *
 * If a SSL/TLS negotiation fails (invalid certificate, etc) then the socket will immediately close,
 * and the socketDidDisconnect:withError: delegate method will be called with the specific SSL error code.
 **/
- (void)socketDidSecure:(GCDAsyncSocket *)sock {
    NSLog(@"Socket completed SSL/TSL negotiation:%@", sock);
}


#pragma mark - Help Command
- (NSData *)help {
    NSString *join = @"/join - This is the first message that the command-process of the client sends after it connects to the server.\n";
    NSString *bye = @"/bye  - The client is about to terminate (bye.).\n";
    NSString *crea = @"/crea - Create a new chat-room. The name of the chat-room and its description will follow.\n";
    NSString *subs = @"/subs - Client requests to be subscribed to an already existing chat-room. The name of the desired chat-room will follow.\n";
    NSString *unsu = @"/unsu - Unsubscribe the client from a chat-room. The name of the chat-room will follow.\n";
    NSString *shut = @"/shut - Only the administrator-client sends this command. Shutdown the server.\n";
    NSString *defa = @"/defa - Change the client\'s default chat-room. The name of the desired chat-room will follow.\n";
    NSString *lsrc = @"/lsrc - List chat-rooms. The server should provide a list of available chat-rooms to the client.\n";
    NSString *lssu = @"/lssu - List chat-rooms that the client has subscribed to.\n";
    NSString *read = @"/read - The command is issued by the client\'s read-process. The incoming connection should be used by the chat-server for writing messages that are directed to this client.\n";
    NSString *writ = @"/writ - The command is issued by the client\'s write-process. The incomming connection should be used by the chat-server to read client's chat-messages.\n";
    NSString *wisp = @"/whisper - Send a private message to a client who has a display name. Type /whisper displayname message. The displayname cannot have a space.\n";
    NSString *list = @"/lstusrs - List all the clients who are currently connected to the server.\n";
    NSString *help = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@", join, bye, crea, subs, unsu, shut, defa, lsrc, lssu, read, writ, wisp, list];
	NSData *helpData = [help dataUsingEncoding:NSUTF8StringEncoding];
    return helpData;
}

#pragma mark - Text View and Log Methods
- (void)scrollToBottom:(id)window
{
	NSScrollView *scrollView = [window enclosingScrollView];
	NSPoint newScrollOrigin;
	
	if ([[scrollView documentView] isFlipped])
		newScrollOrigin = NSMakePoint(0.0F, NSMaxY([[scrollView documentView] frame]));
	else
		newScrollOrigin = NSMakePoint(0.0F, 0.0F);
	
	[[scrollView documentView] scrollPoint:newScrollOrigin];
}

- (void)logError:(NSString *)msg window:(id)window
{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
    [[window textStorage] appendAttributedString:as];
    [self scrollToBottom:window];
}

- (void)logInfo:(NSString *)msg window:(id)window
{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];

    if (window == logView) {
        [attributes setObject:[NSColor greenColor] forKey:NSForegroundColorAttributeName];
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
        [[window textStorage] appendAttributedString:as];
    } else if (window == clientsView) {
        [attributes setObject:[NSColor orangeColor] forKey:NSForegroundColorAttributeName];
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
        [[window textStorage] setAttributedString:as];
    } else if (window == chatRoomsView) {
        [attributes setObject:[NSColor blueColor] forKey:NSForegroundColorAttributeName];
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
        [[window textStorage] setAttributedString:as];
    }
    
    [self scrollToBottom:window];
}

- (void)logMessage:(NSString *)msg window:(id)window withSock:(GCDAsyncSocket *)sock
{

    if (window == logView) {
	
		NSString *paragraph;

		if (!sock.socketOwnerName)
			paragraph = [NSString stringWithFormat:@"%@: %@\n", sock, msg];
		else
			paragraph = [NSString stringWithFormat:@"%@:%@: %@\n", sock.socketOwnerName, sock, msg];
		
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
        [attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
        [[window textStorage] appendAttributedString:as];
    } else if (window == clientsView) {
        NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
        [attributes setObject:[NSColor orangeColor] forKey:NSForegroundColorAttributeName];
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
        [[window textStorage] setAttributedString:as];
    } else if (window == chatRoomsView) {
        NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
        [attributes setObject:[NSColor blueColor] forKey:NSForegroundColorAttributeName];
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
        [[window textStorage] setAttributedString:as];
    }

    
    [self scrollToBottom:window];
}

- (void)logAdminMessage:(NSString *)msg window:(id)window
{
    NSString *paragraph = [NSString stringWithFormat:@"Admin: %@\n", msg];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
    [[window textStorage] appendAttributedString:as];
}


- (IBAction)sendMessage:(id)sender
{
    if (isRunning && ![[adminMessageField stringValue] isEqualToString:@""]) {
        NSData *warningData = [[NSString stringWithFormat:@"\nAdmin: %@\n", [adminMessageField stringValue]] dataUsingEncoding:NSUTF8StringEncoding];
        for (GCDAsyncSocket *sock in connectedClients) {
            [sock writeData:warningData withTimeout:-1 tag:ADMIN_MSG];
        }
        [self logAdminMessage:[adminMessageField stringValue] window:logView];
        [adminMessageField setStringValue:@""];
    }
}


#pragma mark - Client Commands - Implementation

- (void) unsubscribeUser:(NSString *)message withSock:(GCDAsyncSocket *)sock {
    NSString *chatRoom = [message substringWithRange:NSMakeRange(6, [message length] - 6)];
    BOOL checker = NO;
    if (chatRooms[chatRoom]) {
        
        for (GCDAsyncSocket *selfSock in chatRooms[chatRoom])
            if ([selfSock isEqual:sock])
                checker = YES;
        if (checker) {
            [chatRooms[chatRoom] removeObject:sock];
            NSString *chatRoomResponse = [NSString stringWithFormat:@"You have successfully unsubscribed to chatroom : %@ \n", chatRoom];
            NSData *data = [chatRoomResponse dataUsingEncoding:NSUTF8StringEncoding];
            [sock writeData:data withTimeout:-1 tag:HELP_MSG];
            
            for (GCDAsyncSocket *userInTheSubscribedChatroom in chatRooms[chatRoom]) {
                if (sock != userInTheSubscribedChatroom) {
                    NSString *chatRoomResponse;
                    if (sock.socketOwnerName)
                        chatRoomResponse = [NSString stringWithFormat:@"'%@' has left the chatroom %@.\n", sock.socketOwnerName, chatRoom];
                    else
                        chatRoomResponse = [NSString stringWithFormat:@"'%@' has left the chatroom %@.\n", sock, chatRoom];
                    NSData *data = [chatRoomResponse dataUsingEncoding:NSUTF8StringEncoding];
                    [userInTheSubscribedChatroom writeData:data withTimeout:-1 tag:HELP_MSG];
                }
            }
            
        } else {
            NSString *chatRoomResponse = [NSString stringWithFormat:@"You are not subscribed to chatroom : %@ \n", chatRoom];
            NSData *data = [chatRoomResponse dataUsingEncoding:NSUTF8StringEncoding];
            [sock writeData:data withTimeout:-1 tag:HELP_MSG];
        }
    } else {
        NSString *chatRoomResponse = [NSString stringWithFormat:@"%@ was not created. We cannot subscribe you to a non-existent chatroom.\n", chatRoom];
        NSData *data = [chatRoomResponse dataUsingEncoding:NSUTF8StringEncoding];
        [sock writeData:data withTimeout:-1 tag:HELP_MSG];
    }
}

- (void) defaultChatroom:(NSString *)message withSock:(GCDAsyncSocket *)sock {
    NSString *msg = @"/defa is not implemented yet\n";
    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    [sock writeData:data withTimeout:-1 tag:HELP_MSG];
}

- (void) subscribeUser:(NSString *)message withSock:(GCDAsyncSocket *)sock {
    NSString *chatRoom = [message substringWithRange:NSMakeRange(6, [message length] - 6)];
    BOOL checker = NO;
    
    if (chatRooms[chatRoom]) {
        
        for (GCDAsyncSocket *selfSock in chatRooms[chatRoom])
            if ([selfSock isEqual:sock])
                checker = YES;
        
        if (checker) {
            NSString *chatRoomResponse = [NSString stringWithFormat:@"You are already subscribed to chatroom : %@ \n", chatRoom];
            NSData *data = [chatRoomResponse dataUsingEncoding:NSUTF8StringEncoding];
            [sock writeData:data withTimeout:-1 tag:HELP_MSG];
        } else {
            [chatRooms[chatRoom] insertObject:sock atIndex:0];
            NSString *chatRoomResponse = [NSString stringWithFormat:@"You are now subscribed to chatroom : %@ \n", chatRoom];
            NSData *data = [chatRoomResponse dataUsingEncoding:NSUTF8StringEncoding];
            [sock writeData:data withTimeout:-1 tag:HELP_MSG];
            
            for (GCDAsyncSocket *userInTheSubscribedChatroom in chatRooms[chatRoom]) {
                if (sock != userInTheSubscribedChatroom) {
                    NSString *chatRoomResponse;
                    if (sock.socketOwnerName)
                        chatRoomResponse = [NSString stringWithFormat:@"'%@' has connected to %@.\n", sock.socketOwnerName, chatRoom];
                     else
                        chatRoomResponse = [NSString stringWithFormat:@"'%@' has connected to %@.\n", sock, chatRoom];
                    NSData *data = [chatRoomResponse dataUsingEncoding:NSUTF8StringEncoding];
                    [userInTheSubscribedChatroom writeData:data withTimeout:-1 tag:HELP_MSG];
                }
            }
        }
    } else {
        NSString *chatRoomResponse = [NSString stringWithFormat:@"%@ was not created. We cannot subscribe you to a non-existent chatroom.\n", chatRoom];
        NSData *data = [chatRoomResponse dataUsingEncoding:NSUTF8StringEncoding];
        [sock writeData:data withTimeout:-1 tag:HELP_MSG];
    }
}

- (void)listUsers:(GCDAsyncSocket *)sock {
    NSMutableString *astring = [NSMutableString string];
    if ([connectedClients count] == 1) {
        NSString *newMessage = @"\nYou are the only one connected to the server!\n\n";
        NSData *data = [newMessage dataUsingEncoding:NSUTF8StringEncoding];
        [sock writeData:data withTimeout:-1 tag:HELP_MSG];
    } else {
        
        [astring appendString:[NSString stringWithFormat:@"\n%lu connected clients:\n", (unsigned long)[connectedClients count]]];
        for (GCDAsyncSocket *sock in connectedClients) {
            
            if (!sock.socketOwnerName) {
                NSString *string = [NSString stringWithFormat:@"%@='This client has no justified displayname.' \n", sock];
                [astring appendString:string];
            } else {
                NSString *string = [NSString stringWithFormat:@"%@='%@' \n", sock, sock.socketOwnerName];
                [astring appendString:string];
            }
        }
        [astring appendString:@"\n"];
        NSData *data = [astring dataUsingEncoding:NSUTF8StringEncoding];
        [sock writeData:data withTimeout:-1 tag:HELP_MSG];
    }
}

- (void)createChatroom:(NSString *)message withSock:(GCDAsyncSocket *)sock {
    // Parse the message the user sent
    // Want to parse the chat room name the user typed in
    NSString *newChatRoom = [message substringWithRange:NSMakeRange(6, [message length] - 6)];
    
    if (!chatRooms[newChatRoom]) {
        
        // Create a response string to send back to the client
        // for a successful chat room creation
        NSString *chatRoomResponse = [NSString stringWithFormat:@"Chat room %@ was successfully created.\n", newChatRoom];
        
        // Encode the string to allow it to pass through the socket buffer.
        NSData *data = [chatRoomResponse dataUsingEncoding:NSUTF8StringEncoding];
        
        // Write the data to the socket who sent the command.
        [sock writeData:data withTimeout:-1 tag:HELP_MSG];
        
        // Now we have to add the chatroom name to the NSMutableDictionary
        // 'chatRooms', whose keys will be the name of the chatroom and whose
        // values will be the clients subscribed to the chatroom.
        NSMutableArray *array = [[NSMutableArray alloc] initWithObjects:sock, nil];
        [chatRooms setObject:array forKey:newChatRoom];
        
        NSMutableString * chatRoomsStringForLog = [NSMutableString string];
        for(NSString *key in chatRooms) {
            NSString *formattedString = [NSString stringWithFormat:@"%@\n", key];
            [chatRoomsStringForLog appendString:formattedString];
        }
        
        [self logMessage:chatRoomsStringForLog window:chatRoomsView withSock:nil];
        
    } else {
        
        NSString *chatRoomResponse = [NSString stringWithFormat:@"Chat room %@ is already created. Please choose a different name.\n", newChatRoom];
        
        // Encode the string to allow it to pass through the socket buffer.
        NSData *data = [chatRoomResponse dataUsingEncoding:NSUTF8StringEncoding];
        
        // Write the data to the socket who sent the command.
        [sock writeData:data withTimeout:-1 tag:HELP_MSG];
    }
}

- (void)assignUsername:(NSString *)message withSock:(GCDAsyncSocket *)sock {
    
    NSString *userName = [message substringWithRange:NSMakeRange(6, [message length] - 6)];
    BOOL checker = NO;
    
    for (GCDAsyncSocket *selfSock in connectedClients) {
        if ([selfSock.socketOwnerName isEqualToString:userName]) {
            checker = YES;
            break;
        }
    }
    
    if (checker) {
        
        NSString *usedNameMessage = [NSString stringWithFormat:@"There is currently a client already using the display name: %@\n", userName];
        NSData *data = [usedNameMessage dataUsingEncoding:NSUTF8StringEncoding];
        [sock writeData:data withTimeout:-1 tag:HELP_MSG];
        
    } else {
        
        sock.socketOwnerName = userName;
        NSString *chatRoomResponse = [NSString stringWithFormat:@"You are now known as '%@'\n", sock.socketOwnerName];
        NSData *data = [chatRoomResponse dataUsingEncoding:NSUTF8StringEncoding];
        [sock writeData:data withTimeout:-1 tag:HELP_MSG];
    }
}

- (void)whisperUser:(NSString *)message withSock:(GCDAsyncSocket *)sock {
    id whispering;
    NSArray *fullMessage = [message componentsSeparatedByString:@" "];
    whispering = fullMessage[1];
    if ([whispering isEqualToString:sock.socketOwnerName]) {
        
        NSString *newMessage = @"Your whispering yourself silly. Try using the /listusers\ncommand to show all the users that are able to be whispered to.\n";
        NSData *data = [newMessage dataUsingEncoding:NSUTF8StringEncoding];
        [sock writeData:data withTimeout:-1 tag:HELP_MSG];
        
    } else {
        for (GCDAsyncSocket *client in connectedClients) {
            if (client != sock) {
                if ([whispering isEqualToString:client.socketOwnerName]) {
                    NSString *yup = [message substringWithRange:NSMakeRange([[message substringToIndex:8] length] + [whispering length] + 2, [message length] - ([[message substringToIndex:8] length] + [whispering length]) - 2)];
                    NSString *formatted = [NSString stringWithFormat:@"%@ whispered: %@\n", sock.socketOwnerName ,yup];
                    NSData *data = [formatted dataUsingEncoding:NSUTF8StringEncoding];
                    [client writeData:data withTimeout:-1 tag:HELP_MSG];
                }
            }
        }
    }
}

- (void) errorCommand:(NSString *)message withSock:(GCDAsyncSocket *)sock {
    NSString *newMessage = [NSString stringWithFormat:@"%@ is not a command that is implemented yet. Please type /help to see all commands.\n", message];
    NSData *data = [newMessage dataUsingEncoding:NSUTF8StringEncoding];
    [sock writeData:data withTimeout:-1 tag:HELP_MSG];
}

- (void) listSubscribedChatrooms:(NSString *)message withSock:(GCDAsyncSocket *)sock {
    
    if (!([chatRooms count] == 0)) {
        
        NSMutableString *rooms = [NSMutableString string];
        int n = 0;
        // First, iterate through all the Chatrooms
        // Inefficient implementation but works.
        for (NSString * chatRoom in chatRooms) {
            // Create a checker to see what chatrooms the user is subscribed to
            BOOL checker = NO;
            
            // Iterate through all the clients in each chatroom.
            for (GCDAsyncSocket * user in chatRooms[chatRoom]) {
                // If the messanger is a client in the current chatroom, set the checker
                if (user == sock) {
                    checker = YES;
                    n++;
                    break;
                }
            }
            if (checker) {
                [rooms appendString:[NSString stringWithFormat:@"%@\n", chatRoom]];
            }
        }
        
        NSString *message;
        switch (n) {
            case 0:
                message = @"\nYou are not subscribed to any chatrooms at the moment.\n\n";
                break;
            case 1:
                message = [NSString stringWithFormat:@"\nYou are currently subscribed to %d chatroom.\nChatroom: \n%@\n", n,rooms];
                break;
            default:
                message = [NSString stringWithFormat:@"\nYou are currently subscribed to %d chatrooms.\nChatrooms: \n%@\n", n,rooms];
                break;
        }
        NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
        [sock writeData:data withTimeout:-1 tag:HELP_MSG];
        
    } else {
        
        NSString *message = @"\nThere are currently no chatrooms created. Just the lobby.\nYou can create a new chatroom by typing /crea followed by the name of the chatroom.\n\n";
        NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
        [sock writeData:data withTimeout:-1 tag:HELP_MSG];
        
    }
}

- (void)echoMessage:(NSString *)message withSock:(GCDAsyncSocket *)sock {
    NSString *paragraph;
    
	if (!sock.socketOwnerName)
		paragraph = [NSString stringWithFormat:@"%@: %@\n", sock, message];
	else
		paragraph = [NSString stringWithFormat:@"%@: %@\n", sock.socketOwnerName, message];
    
	// First, iterate through all the Chatrooms
	// Inefficient implementation but works.
	for (NSString * chatRoom in chatRooms) {
		// Create a checker to see what chatrooms the user is subscribed to
		BOOL checker = NO;
		
		// Iterate through all the clients in each chatroom.
		for (GCDAsyncSocket * user in chatRooms[chatRoom]) {
			// If the messanger is a client in the current chatroom, set the checker
			if (user == sock) {
				checker = YES;
				break;
			}
		}
		
		// Now that we iterated through each chatroom to check if the messager is
		// in the chatroom, we will echo the message to all clients in each chatroom
		// that isnt the messager
		if (checker) {
			for (GCDAsyncSocket * user in chatRooms[chatRoom]) {
				if (!(sock == user))
					[user writeData:[paragraph dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:ECHO_MSG];
			}
		}
	}
}

- (void)listChatrooms:(NSString *)message withSock:(GCDAsyncSocket *)sock {
    
    if (!([chatRooms count] == 0)) {
        
        NSMutableString * chatRoomsStringForLog = [NSMutableString string];
        NSString *chatRoomsCount = [NSString stringWithFormat:@"\nThere are currently %lu chatrooms.\n\n", (unsigned long)[chatRooms count]];
        [chatRoomsStringForLog appendString:chatRoomsCount];
        for( NSString *key in chatRooms ) {
            
            NSString *formattedString = [NSString stringWithFormat:@"Title: %@\nClients:\n", key];
            [chatRoomsStringForLog appendString:formattedString];
            NSArray *value = [chatRooms objectForKey:key];
            for (GCDAsyncSocket *sock in value) {
                
                NSString *formattedString2;
                if (!sock.socketOwnerName) {
                    formattedString2 = [NSString stringWithFormat:@"%@='No assigned Display name'\n", sock];
                } else {
                    formattedString2 = [NSString stringWithFormat:@"%@='%@'\n", sock, sock.socketOwnerName];
                }
                
                [chatRoomsStringForLog appendString:formattedString2];
            }
            
            [chatRoomsStringForLog appendString:@"\n"];
            
        }
        
        NSData *data = [chatRoomsStringForLog dataUsingEncoding:NSUTF8StringEncoding];
        [sock writeData:data withTimeout:-1 tag:HELP_MSG];
        
    } else {
        
        NSString *message = @"\nThere are currently no chatrooms created. Just the lobby.\nYou can create a new chatroom by typing /crea followed by the name of the chatroom.\n\n";
        NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
        [sock writeData:data withTimeout:-1 tag:HELP_MSG];
        
    }
}

@end
