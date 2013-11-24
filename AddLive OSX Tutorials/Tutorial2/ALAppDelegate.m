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
    NSMutableArray* _mics;
    NSMutableArray* _spkrs;
    NSMutableArray* _cams;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_stateLabel setStringValue:@"App Loaded."];
    [_stateLabel setStringValue:@"Initialising AddLive."];
    _mics = [[NSMutableArray alloc] init];
    _spkrs = [[NSMutableArray alloc] init];
    _cams = [[NSMutableArray alloc] init];
    _alService = [[ALService alloc] init];
    ALInitOptions* options = [[ALInitOptions alloc] init];
    options.apiKey = Consts.API_KEY;
    options.applicationId = Consts.APP_ID;
    [_alService initPlatform:options
                   responder:
     [ALResponder responderWithSelector:@selector(onPlatformReady:) object:self]];

}

- (IBAction) camChanged:(id)sender {
    ALDevice* dev = [_cams objectAtIndex:_camsSelect.indexOfSelectedItem];
    ResultBlock onCam = ^(ALError* err, id result) {
        if([self handleErrMaybe:err where:@"setVideoCaptureDevice"])
            return;
        _stateLabel.textColor = GREEN;
        [_stateLabel setStringValue:@"Camera selected."];
    };
    _stateLabel.textColor = BLACK;
    
    [_stateLabel setStringValue:
     [NSString stringWithFormat:@"Changing camera to: %@", dev.label]];
    [_alService setVideoCaptureDevice:dev.id
                            responder:[ALResponder responderWithBlock:onCam]];
}

- (IBAction) spkChanged:(id)sender {
    ALDevice* dev = [_spkrs objectAtIndex:_spkSelect.indexOfSelectedItem];
    ResultBlock onSpk = ^(ALError* err, id result) {
        if([self handleErrMaybe:err where:@"setAudioOutputDevice"])
            return;
        _stateLabel.textColor = GREEN;
        [_stateLabel setStringValue:@"Speakers selected."];
    };
    _stateLabel.textColor = BLACK;
    
    [_stateLabel setStringValue:
     [NSString stringWithFormat:@"Changing speakers to: %@", dev.label]];
    [_alService setAudioOutputDevice:dev.id
                           responder:[ALResponder responderWithBlock:onSpk]];
}

- (IBAction) micChanged:(id)sender {
    ALDevice* dev = [_mics objectAtIndex:_micSelect.indexOfSelectedItem];
    ResultBlock onMic = ^(ALError* err, id result) {
        if([self handleErrMaybe:err where:@"setAudioCaptureDevice"])
            return;
        _stateLabel.textColor = GREEN;
        [_stateLabel setStringValue:@"Mic selected."];
    };
    _stateLabel.textColor = BLACK;
    
    [_stateLabel setStringValue:
     [NSString stringWithFormat:@"Changing mic to: %@", dev.label]];
    [_alService setAudioCaptureDevice:dev.id
                           responder:[ALResponder responderWithBlock:onMic]];
}

- (void) onPlatformReady:(ALError*) error {
    if([self handleErrMaybe:error where:@"initPlatform"]) {
        return;
    }
    [self showVersion];
    [self fetchAudioCaptureDevices];
    [self fetchAudioOutputDevices];
    [self fetchVideoCaptureDevices];
}

- (void) fetchAudioCaptureDevices {
    ResultBlock onDevs = ^(ALError* err, id result) {
        [self populateDevs:result combo:_micSelect idsContainer:_mics];
    };
    [_alService getAudioCaptureDeviceNames:[ALResponder responderWithBlock:onDevs]];
}

- (void) fetchAudioOutputDevices {
    ResultBlock onDevs = ^(ALError* err, id result) {
        [self populateDevs:result combo:_spkSelect idsContainer:_spkrs];
    };
    [_alService getAudioOutputDeviceNames:[ALResponder responderWithBlock:onDevs]];
}

- (void) fetchVideoCaptureDevices {
    ResultBlock onDevs = ^(ALError* err, id result) {
        [self populateDevs:result combo:_camsSelect idsContainer:_cams];
    };
    [_alService getVideoCaptureDeviceNames:[ALResponder responderWithBlock:onDevs]];
}


- (void) populateDevs:(NSArray*) devs
               combo:(NSPopUpButton*) combo
         idsContainer:(NSMutableArray*) idsContainer {
    [combo removeAllItems];
    NSMutableArray* labels = [[NSMutableArray alloc] init];
    [idsContainer removeAllObjects];
    for(ALDevice* dev in devs) {
        [idsContainer addObject:dev];
        [labels addObject:dev.label];
    }
    [combo addItemsWithTitles:labels];
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