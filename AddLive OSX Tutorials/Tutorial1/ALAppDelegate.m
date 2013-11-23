//
//  ALAppDelegate.m
//  AddLive OSX Tutorials
//
//  Created by Tadeusz Kozak on 23/11/13.
//  Copyright (c) 2013 AddLive. All rights reserved.
//

#import "ALAppDelegate.h"
#import <AddLive/AddLiveAPI.h>


#define RED  [NSColor colorWithDeviceRed:255 green:0 blue:0 alpha:1];
#define GREEN  [NSColor colorWithDeviceRed:0 green:255 blue:0 alpha:1];
#define BLACK  [NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:1];

/**
 * Interface defining application constants. In our case it is just the
 * Application id and API key.
 */
@interface Consts : NSObject

+ (NSNumber*) APP_ID;

+ (NSString*) API_KEY;

@end


@implementation ALAppDelegate {
    ALService* _alService;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_stateLabel setStringValue:@"App Loaded."];
}

- (IBAction) initAddLive:(id)sender {
    [_stateLabel setStringValue:@"Initialising AddLive."];
    _alService = [[ALService alloc] init];
    ALInitOptions* options = [[ALInitOptions alloc] init];
    options.apiKey = Consts.API_KEY;
    options.applicationId = Consts.APP_ID;
    [_platformInitBtn setHidden:YES];
    [_alService initPlatform:options
                   responder:
     [ALResponder responderWithSelector:@selector(onPlatformReady:) object:self]];
}

- (IBAction) disposeAddLive:(id)sender {
    [_platformDisposeBtn setHidden:YES];
    [_platformInitBtn setHidden:NO];
    [_alService releasePlatform];
    [_stateLabel setStringValue:@"Ready."];
    _stateLabel.textColor = BLACK;
    _alService = nil;
}

- (void) onPlatformReady:(ALError*) error {
    if([self handleErrMaybe:error where:@"initPlatform"]) {
        return;
    }
    [_platformDisposeBtn setHidden:NO];
    [self showVersion];
}

- (void) showVersion {
    ResultBlock onVersion = ^(ALError* err, id value) {
        NSString* stateLbl = [NSString stringWithFormat:@"Service ready. SDK v%@", value];
        _stateLabel.textColor = GREEN;
        [_stateLabel setStringValue:stateLbl];
    };
    [_alService getVersion:[ALResponder responderWithBlock:onVersion]];
}

- (BOOL) handleErrMaybe:(ALError*) err where:(NSString*) where {
    if(!err)
        return NO;
    _stateLabel.textColor = RED;
    [_stateLabel setStringValue:[NSString stringWithFormat:@"Got an error with method %@: %@", where, err]];
    return YES;
}

@end

@implementation Consts

+ (NSNumber*) APP_ID {
    // TODO update this to use some real value
    return @1;
}

+ (NSString*) API_KEY {
    // TODO update this to use some real value
    return @"SomeApiKey";
}
@end