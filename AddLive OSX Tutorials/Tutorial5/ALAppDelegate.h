//
//  ALAppDelegate.h
//  AddLive OSX Tutorials
//
//  Created by Tadeusz Kozak on 23/11/13.
//  Copyright (c) 2013 AddLive. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddLive/AddLiveAPI.h>

@interface ALAppDelegate : NSObject <NSApplicationDelegate, ALServiceListener>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *stateLabel;

@property (weak) IBOutlet NSPopUpButton *camsSelect;
@property (weak) IBOutlet NSPopUpButton *micSelect;
@property (weak) IBOutlet NSPopUpButton *spkSelect;

@property (weak) IBOutlet NSTextField *cpuDetailsLbl;
@property (weak) IBOutlet NSLevelIndicator *micLevelIndicator;
@property (weak) IBOutlet NSButton *micActivityChckBox;

- (IBAction) camChanged:(id)sender;
- (IBAction) micChanged:(id)sender;
- (IBAction) spkChanged:(id)sender;
- (IBAction) playTestSound:(id)sender;
- (IBAction) monitorMicChanged:(id)sender;
@end
