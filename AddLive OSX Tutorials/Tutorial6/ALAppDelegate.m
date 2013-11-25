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

@interface ALEventsListener : NSObject<ALServiceListener>

- (id) initWithRenderer:(ALVideoView*) renderer
          withUserLabel:(NSTextField*) userLabel
            withService:(ALService*) service;

- (void) onUserEvent:(ALUserStateChangedEvent*) event;

@end


@implementation ALAppDelegate {
    ALService*        _alService;
    NSMutableArray*   _mics;
    NSMutableArray*   _spkrs;
    NSMutableArray*   _cams;
    BOOL              _isConnected;
    NSString*         _scopeId;
    
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
    options.streamerEndpointResolver = @"http://cnc-beta.addlive.com/resolve_streamer.do";
    [_alService initPlatform:options
                   responder:
     [ALResponder responderWithSelector:@selector(onPlatformReady:) object:self]];

}


- (IBAction) connect:(id)sender {
    ALConnectionDescriptor* descr = [[ALConnectionDescriptor alloc] init];

    descr.scopeId = _scopeIdTxtField.stringValue;
    descr.autopublishAudio = !!_publishAudioChckBx.integerValue;
    descr.autopublishVideo = !!_publishVideoChckBx.integerValue;
    descr.videoStream.maxFps = 15;
    descr.videoStream.maxWidth = 480;
    descr.videoStream.maxHeight = 640;
    descr.authDetails.userId = rand() % 10000;
    descr.authDetails.salt = @"some super random string";
    descr.authDetails.expires = time(0) + 60 * 60;
    ResultBlock onConnect = ^(ALError* err, id nothing) {
        if([self handleErrMaybe:err where:@"connect"])
            return;
        _isConnected = YES;
        // Store the scope id so the disconnect and publish/unpublish methods operate propertly
        _scopeId = descr.scopeId;
        _disconnectBtn.hidden = NO;
        _connectBtn.hidden = YES;
        _stateLabel.textColor = GREEN;
        [_stateLabel setStringValue:@"Connected."];
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
    [_alService disconnect:_scopeId responder:[ALResponder responderWithBlock:onDisconnected]];
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

- (IBAction) publishAudioChanged:(id)sender {
    if(!_isConnected)
        return;
    if(_publishAudioChckBx.intValue)
        [_alService publish:_scopeId what:ALMediaType.kAudio options:nil responder:nil];
    else
        [_alService unpublish:_scopeId what:ALMediaType.kAudio responder:nil];
    
}

- (IBAction) publishVideoChanged:(id)sender {
    if(!_isConnected)
        return;
    if(_publishVideoChckBx.intValue)
        [_alService publish:_scopeId what:ALMediaType.kVideo options:nil responder:nil];
    else
        [_alService unpublish:_scopeId what:ALMediaType.kVideo responder:nil];
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
        [self fetchVideoCaptureDevices];
        [self startLocalVideo];
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

- (void) startLocalVideo {
    ResultBlock onVideoStarted = ^(ALError* err, id sinkId) {
        if([self handleErrMaybe:err where:@"startLocalVideo"])
            return;
        [_localVideo setupWithService:_alService withSink:sinkId withMirror:YES];
        [_localVideo start:nil];
    };
    [_alService startLocalVideo:[ALResponder responderWithBlock:onVideoStarted]];
}


- (BOOL) handleErrMaybe:(ALError*) err where:(NSString*) where {
    if(!err)
        return NO;
    _stateLabel.textColor = RED;
    [_stateLabel setStringValue:[NSString stringWithFormat:@"Got an error with method %@: %@", where, err]];
    return YES;
}

- (void) onDisconnected {
    _isConnected = NO;
    [_remoteVideo stop:nil];
    _remoteVideo.hidden = YES;
    _connTypeLbl.stringValue = @"Not Connected";
    _remoteUserIdLbl.stringValue = @"None";
    _disconnectBtn.hidden = YES;
    _connectBtn.hidden = NO;
}


/// ALServiceListener methods

- (void) onMediaConnTypeChanged:(ALMediaConnTypeChangedEvent*) event {
    _connTypeLbl.stringValue = event.connectionType;
}

- (void) onUserEvent:(ALUserStateChangedEvent*) event {
    NSLog(@"Got remote user event: %@", event);
    if(event.isConnected) {
        NSLog(@"Got new user");
        [_remoteUserIdLbl setStringValue:[NSString stringWithFormat:@"%lld", event.userId]];
        if(event.videoPublished) {
            [self renderRemoteSink:event.videoSinkId];
        }
    } else {
        _remoteVideo.hidden = YES;
        [_remoteUserIdLbl setStringValue:@"None"];
    }
    _noAudioLbl.hidden = event.audioPublished;
    _noVideoLabel.hidden = event.videoPublished;
}

- (void) onMediaStreamEvent:(ALUserStateChangedEvent*) event {
    NSLog(@"Got media stream event");
    if([event.mediaType isEqualToString:ALMediaType.kVideo]) {
        _noVideoLabel.hidden = event.videoPublished;
        if(event.videoPublished) {
            [self renderRemoteSink:event.videoSinkId];
        } else {
            [_remoteVideo stop:nil];
            _remoteVideo.hidden = YES;
        }
    } else {
        _noAudioLbl.hidden = event.audioPublished;
    }
    
}

- (void) onConnectionLost:(ALConnectionLostEvent*) event {
    _stateLabel.textColor = RED;
    _stateLabel.stringValue = @"Connection lost.";
    [self onDisconnected];
}


- (void) renderRemoteSink:(NSString*) sinkId {
    ResultBlock onStopped = ^(ALError* err, id nothing) {
        [_remoteVideo setupWithService:_alService withSink:sinkId];
        [_remoteVideo start:nil];
        _remoteVideo.hidden = NO;
    };
    [_remoteVideo stop:[ALResponder responderWithBlock:onStopped]];
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


@end