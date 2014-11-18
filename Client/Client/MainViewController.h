//
//  MainViewController.h
//  Client
//
//  Created by John Setting on 12/14/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GCDAsyncSocket;

@interface MainViewController : NSViewController
{
    GCDAsyncSocket *selfSocket;
    
    // Activity View
    IBOutlet id activityView;
    
    // Help Button
    IBOutlet id helpButton;
    
    // Clients and Whisper
    IBOutlet id clientView;
    IBOutlet id whisperButton;
    
    // Subscribed Chatrooms View
    IBOutlet id subscribedChatRoomsView;
    
    // Available Chatrooms View
    IBOutlet id chatRoomsView;
    IBOutlet id subscribeToChatRoomButton;

    // MessageView and SendButton
    IBOutlet id messageField;
    IBOutlet id sendButton;

}

- (id)getActivityView;
- (id)getClientView;
- (id)getSubscribedChatRoomsView;
- (id)getChatRoomsView;

- (IBAction)helpAction:(id)sender;
- (IBAction)whisperAction:(id)sender;
- (IBAction)joinChatRoomAction:(id)sender;
- (IBAction)sendAction:(id)sender;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil socket:(GCDAsyncSocket *)sock ownerName:(NSString *)name;


- (void)logError:(NSString *)msg view:(id)view;
- (void)logInfo:(NSString *)msg view:(id)view;
- (void)logMessage:(NSString *)msg view:(id)view;

@end
