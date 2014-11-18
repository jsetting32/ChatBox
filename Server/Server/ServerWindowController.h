//
//  ServerWindowController.h
//  Server
//
//  Created by John Setting on 12/11/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GCDAsyncSocket.h"

@interface ServerWindowController : NSWindowController
{
    GCDAsyncSocket *mainSocket;
    dispatch_queue_t socketQueue;
    
	NSMutableArray *connectedClients;
    NSMutableDictionary *chatRooms;
    
    BOOL isRunning;

    IBOutlet id chatRoomsView;
    IBOutlet id clientsView;
	IBOutlet id logView;
	IBOutlet id portField;
	IBOutlet id startStopButton;

    IBOutlet id adminMessageField;
	IBOutlet id submitAdminMessage;
    
    NSColor *startingColor;
    NSColor *endingColor;
    int angle;
}




// Define the variables as properties
@property(nonatomic, retain) NSColor *startingColor;
@property(nonatomic, retain) NSColor *endingColor;
@property(assign) int angle;



- (IBAction)startStop:(id)sender;
- (IBAction)sendMessage:(id)sender;

@end
