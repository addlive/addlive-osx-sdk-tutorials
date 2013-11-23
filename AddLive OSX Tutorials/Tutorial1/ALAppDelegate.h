//
//  ALAppDelegate.h
//  AddLive OSX Tutorials
//
//  Created by Tadeusz Kozak on 23/11/13.
//  Copyright (c) 2013 AddLive. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ALAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *stateLabel;
@property (weak) IBOutlet NSButton *platformInitBtn;
@property (weak) IBOutlet NSButton *platformDisposeBtn;

- (IBAction) initAddLive:(id)sender;
- (IBAction) disposeAddLive:(id)sender;


@end
