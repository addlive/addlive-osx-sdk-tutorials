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

+ (NSString*) SCOPE_ID;
@end

@interface ALEventsListener : NSObject<ALServiceListener>

- (id) initWithRenderer:(ALVideoView*) renderer
          withUserLabel:(NSTextField*) userLabel
            withService:(ALService*) service;

- (void) onUserEvent:(ALUserStateChangedEvent*) event;

@end


@implementation ALAppDelegate {
    ALService*        _alService;
    NSMutableArray*   _spkrs;
    NSMutableArray*   _mics;
    BOOL              _isConnected;
    NSArray*          _videoQualityProfiles;
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_stateLabel setStringValue:@"App Loaded."];
    [_stateLabel setStringValue:@"Initialising AddLive."];
    _mics = [[NSMutableArray alloc] init];
    _spkrs = [[NSMutableArray alloc] init];
    
    _alService = [[ALService alloc] init];
    
    ALInitOptions* options = [[ALInitOptions alloc] init];
    options.apiKey = Consts.API_KEY;
    options.applicationId = Consts.APP_ID;
    options.streamerEndpointResolver = @"http://cnc-beta.addlive.com/resolve_streamer.do";
    [_alService initPlatform:options
                   responder:
     [ALResponder responderWithSelector:@selector(onPlatformReady:) object:self]];

}

- (IBAction) connect:(id)sender {
    ALConnectionDescriptor* descr = [[ALConnectionDescriptor alloc] init];

    descr.scopeId = Consts.SCOPE_ID;
    descr.url = [NSString stringWithFormat:@"dev01.addlive.com:8004/%@", Consts.SCOPE_ID];
    descr.autopublishAudio = YES;
    descr.autopublishVideo = NO;
    descr.authDetails.userId = rand() % 10000;
    descr.authDetails.salt = @"some super random string";
    descr.authDetails.expires = time(0) + 60 * 60;
    ResultBlock onConnect = ^(ALError* err, id nothing) {
        [self onConnectionConnected:err];
    };
    _stateLabel.textColor = BLACK;
    [_stateLabel setStringValue:@"Connecting..."];

    [_alService connect:descr responder:[ALResponder responderWithBlock:onConnect]];
}

- (IBAction) disconnect:(id)sender {
    ResultBlock onDisconnected = ^(ALError* err, id nothing) {
        [self onDisconnected];
        _disconnectBtn.hidden = YES;
        _connectBtn.hidden = NO;
        _stateLabel.textColor = BLACK;
        [_stateLabel setStringValue:@"Disconnected."];
    };
    [_alService disconnect:Consts.SCOPE_ID responder:[ALResponder responderWithBlock:onDisconnected]];
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
    [self setListener];
}

- (void) setListener {
    ResultBlock onListener = ^(ALError* err, id nothing) {
        [self showVersion];
        [self fetchAudioCaptureDevices];
        [self fetchAudioOutputDevices];
    };
    [_alService addServiceListener:self responder:[ALResponder responderWithBlock:onListener]];
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

- (void) onConnectionConnected:(ALError*) err {
    if([self handleErrMaybe:err where:@"connect"])
        return;
    _isConnected = YES;
    // Store the scope id so the disconnect and publish/unpublish methods operate propertly

    _disconnectBtn.hidden = NO;
    _connectBtn.hidden = YES;
    _stateLabel.textColor = GREEN;
    [_stateLabel setStringValue:@"Connected."];
    [_alService monitorSpeechActivity:Consts.SCOPE_ID enable:YES responder:nil];
    
}


- (void) onDisconnected {
    _isConnected = NO;
    _disconnectBtn.hidden = YES;
    _connectBtn.hidden = NO;
}


/// ALServiceListener methods

- (void) onMediaConnTypeChanged:(ALMediaConnTypeChangedEvent*) event {
}

- (void) onUserEvent:(ALUserStateChangedEvent*) event {
    NSLog(@"Got remote user event: %@", event);
}

- (void) onMediaStreamEvent:(ALUserStateChangedEvent*) event {
    NSLog(@"Got media stream event");
}

- (void) onConnectionLost:(ALConnectionLostEvent*) event {
    _stateLabel.textColor = RED;
    _stateLabel.stringValue = @"Connection lost.";
    [self onDisconnected];
}

- (void) onSessionReconnected:(ALSessionReconnectedEvent*) event {
    [self onConnectionConnected:nil];
}


- (void) onMediaStats:(ALMediaStatsEvent*) event {
    NSLog(@"Got media stats event: %@", event);
}

- (void) onSpeechActivity:(ALSpeechActivityEvent*) e {
    NSLog(@"Got speech activity: %@", e);
}

@end



@implementation Consts

+ (NSNumber*) APP_ID {
    // TODO update this to use some real value
    return @1;
}

+ (NSString*) API_KEY {
    // TODO update this to use some real value
    return @"";
}

+ (NSString*) SCOPE_ID {
    // TODO update this to use some real value
    return @"ADL_TUT9";
}




@end