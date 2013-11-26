//
//  ALAppDelegate.h
//  AddLive OSX Tutorials
//
//  Created by Tadeusz Kozak on 23/11/13.
//  Copyright (c) 2013 AddLive. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddLive/AddLiveAPI.h>

@interface ALAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *stateLabel;

@property (weak) IBOutlet NSButton *disconnectBtn;
@property (weak) IBOutlet NSButton *connectBtn;
@property (weak) IBOutlet NSTextField *remoteUserIdLbl;
@property (weak) IBOutlet NSTextField *messageInp;
@property (unsafe_unretained) IBOutlet NSTextView *msgsSink;


- (IBAction) connect:(id)sender;
- (IBAction) disconnect:(id)sender;
- (IBAction) sendMsg:(id)sender;


@end
