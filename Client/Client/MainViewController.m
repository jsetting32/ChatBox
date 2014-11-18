//
//  MainViewController.m
//  Client
//
//  Created by John Setting on 12/14/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import "MainViewController.h"
#import "GCDAsyncSocket.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil socket:(GCDAsyncSocket *)sock ownerName:(NSString *)name
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        selfSocket = sock;
        selfSocket.socketOwnerName = name;
    }
    return self;
}

- (void)viewWillLoad
{
    [self writeCommand:[NSString stringWithFormat:@"/user %@\r\n", selfSocket.socketOwnerName] tag:0];
}

- (void)viewDidLoad
{
    
}

- (void)loadView
{
    [self viewWillLoad];
    [super loadView];
    [self viewDidLoad];
}

- (IBAction)helpAction:(id)sender
{
    [self writeCommand:@"/help\r\n" tag:0];
}

- (IBAction)whisperAction:(id)sender
{
    
}

- (IBAction)joinChatRoomAction:(id)sender
{

}

- (IBAction)sendAction:(id)sender
{
    [self writeCommand:[NSString stringWithFormat:@"%@\r\n", [messageField stringValue]] tag:0];
    [messageField setStringValue:@""];
}

-(void) writeCommand:(NSString *)cmd tag:(long)theTag
{
    NSData *data = [cmd dataUsingEncoding:NSUTF8StringEncoding];
    [selfSocket writeData:data  withTimeout:-1 tag:theTag];
}


- (id)getActivityView {
    return activityView;
}

- (id)getClientView {
    return clientView;
}

- (id)getSubscribedChatRoomsView {
    return subscribedChatRoomsView;
}

- (id)getChatRoomsView {
    return chatRoomsView;
}

#pragma mark - Subviews Text Storage and Manipulation Functions

- (void)scrollToBottom:(id)view
{
	NSScrollView *scrollView = [view enclosingScrollView];
	NSPoint newScrollOrigin;
	
	if ([[scrollView documentView] isFlipped])
		newScrollOrigin = NSMakePoint(0.0F, NSMaxY([[scrollView documentView] frame]));
	else
		newScrollOrigin = NSMakePoint(0.0F, 0.0F);
	
	[[scrollView documentView] scrollPoint:newScrollOrigin];
}

- (void)logError:(NSString *)msg view:(id)view
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	
	[[view textStorage] appendAttributedString:as];
	[self scrollToBottom:view];
}

- (void)logInfo:(NSString *)msg view:(id)view
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor purpleColor] forKey:NSForegroundColorAttributeName];
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	
	[[view textStorage] appendAttributedString:as];
	[self scrollToBottom:view];
}

- (void)logMessage:(NSString *)msg view:(id)view
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	
	[[view textStorage] appendAttributedString:as];
	[self scrollToBottom:view];
}

@end
