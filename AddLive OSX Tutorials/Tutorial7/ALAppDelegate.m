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
            withService:(ALService*) service
        withStatusLabel:(NSTextField*) statusLabel ;

- (void) onUserEvent:(ALUserStateChangedEvent*) event;

@end


@implementation ALAppDelegate {
    ALService*        _alService;
    NSArray*          _screenSources;
    ALEventsListener* _listener;
    BOOL              _connected;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_stateLabel setStringValue:@"App Loaded."];
    [_stateLabel setStringValue:@"Initialising AddLive."];
    _connected = NO;
    _alService = [[ALService alloc] init];
    ALInitOptions* options = [[ALInitOptions alloc] init];
    options.apiKey = Consts.API_KEY;
    options.applicationId = Consts.APP_ID;
    [_alService initPlatform:options
                   responder:
     [ALResponder responderWithSelector:@selector(onPlatformReady:) object:self]];

}


- (IBAction) connect:(id)sender {
    ALConnectionDescriptor* descr = [[ALConnectionDescriptor alloc] init];
    descr.scopeId = Consts.SCOPE_ID;
        
    descr.autopublishAudio = NO;
    descr.autopublishVideo = NO;
    descr.videoStream.maxFps = 15;
    descr.videoStream.maxWidth = 480;
    descr.videoStream.maxHeight = 640;
    descr.authDetails.userId = rand() % 10000;
    descr.authDetails.salt = @"some super random string";
    descr.authDetails.expires = time(0) + 60 * 60;
    ResultBlock onConnect = ^(ALError* err, id nothing) {
        if([self handleErrMaybe:err where:@"connect"])
            return;
        _connected = YES;
        _stateLabel.textColor = GREEN;
        [_stateLabel setStringValue:@"Connected."];
        // Trigger the sources change event to force publish of the
        // screen sharing feed
        [self srcChanged:nil];
        _connectBtn.hidden = YES;
        _disconnectBtn.hidden = NO;
    };
    _stateLabel.textColor = BLACK;
    [_stateLabel setStringValue:@"Connecting..."];

    [_alService connect:descr responder:[ALResponder responderWithBlock:onConnect]];
}

- (IBAction) disconnect:(id)sender {
    [_alService disconnect:Consts.SCOPE_ID responder:nil];
    _connected = NO;
    _connectBtn.hidden = NO;
    _disconnectBtn.hidden = YES;
    _stateLabel.textColor = BLACK;
    [_stateLabel setStringValue:@"Disconnected."];

}


- (IBAction) refreshSrcs:(id)sender {
    [self fetchScreenSharingSources];
}
- (IBAction) srcChanged:(id)sender {
    NSUInteger selectedSrc = _sourcesSelect.indexOfSelectedItem;
    NSLog(@"Got source: %lu", (unsigned long)selectedSrc);
    ALScreenCaptureSource* src = [_screenSources objectAtIndex:selectedSrc];
    _srcPreviewWell.image = src.image;
    if(_connected) {
        ResultBlock onPublished = ^(ALError* err, id nothing) {
            if([self handleErrMaybe:err where:@"publish"])
                return;
            _stateLabel.textColor = BLACK;
            [_stateLabel setStringValue:@"Source published..."];

        };
        ResultBlock onUnpublished = ^(ALError* err, id nothing) {
            NSLog(@"Screen sharing feed unpublished. Publishing back");
            ALMediaPublishOptions* options = [[ALMediaPublishOptions alloc] init];
            options.nativeWidth = 640;
            options.windowId = src.sourceId;
            [_alService publish:Consts.SCOPE_ID
                           what:ALMediaType.kScreen options:options
                      responder:[ALResponder responderWithBlock:onPublished]];
        };
        [_alService unpublish:Consts.SCOPE_ID
                         what:ALMediaType.kScreen
                    responder:[ALResponder responderWithBlock:onUnpublished]];
    }
}


- (void) onPlatformReady:(ALError*) error {
    if([self handleErrMaybe:error where:@"initPlatform"]) {
        return;
    }
    [self setListener];
}

- (void) setListener {
    _listener = [[ALEventsListener alloc]
                 initWithRenderer:_remoteVideo
                 withUserLabel:_remoteUserIdLbl
                 withService:_alService
                 withStatusLabel:_stateLabel
                 ];
    ResultBlock onListener = ^(ALError* err, id nothing) {
        [self showVersion];
        [self fetchScreenSharingSources];
    };
    [_alService addServiceListener:_listener responder:[ALResponder responderWithBlock:onListener]];
}

- (void) fetchScreenSharingSources {
    ResultBlock onSrcs = ^(ALError* err, id srcs) {
        if([self handleErrMaybe:err where:@"getScreenCaptureSources"])
            return;
        _screenSources = srcs;
        [_sourcesSelect removeAllItems];
        NSMutableArray* labels = [[NSMutableArray alloc] init];
        for(ALScreenCaptureSource* src in _screenSources) {
            [labels addObject:src.title];
        }
        [_sourcesSelect addItemsWithTitles:labels];
        _sourcesSelect.intValue = 0;
        ALScreenCaptureSource* src = [_screenSources objectAtIndex:0];
        _srcPreviewWell.image = src.image;
    };
    [_alService getScreenCaptureSources:@320 responder:[ALResponder responderWithBlock:onSrcs]];
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

@implementation ALEventsListener {
    ALVideoView* _renderer;
    NSTextField* _label;
    NSTextField* _statusLbl;
    ALService*   _service;
}

- (id) initWithRenderer:(ALVideoView*) renderer
          withUserLabel:(NSTextField*) userLabel
            withService:(ALService*) service
        withStatusLabel:(NSTextField*) statusLabel {
    self = [super init];
    if(self) {
        _renderer = renderer;
        _label = userLabel;
        _service = service;
        _statusLbl = statusLabel;
    }
    return self;
}

- (void) onUserEvent:(ALUserStateChangedEvent*) event {
    NSLog(@"Got remote user event: %@", event);
    if(event.isConnected) {
        NSLog(@"Got new user");
        [_label setStringValue:[NSString stringWithFormat:@"%lld", event.userId]];
        if(event.screenPublished) {
            ResultBlock onStopped = ^(ALError* err, id nothing) {
                [_renderer setupWithService:_service withSink:event.screenSinkId];
                [_renderer start:nil];
                _renderer.hidden = NO;
            };
            [_renderer stop:[ALResponder responderWithBlock:onStopped]];
        }
    } else {
        _renderer.hidden = YES;
        [_label setStringValue:@"None"];
    }
}

- (void) onMediaStreamEvent:(ALUserStateChangedEvent*) event {
    NSLog(@"Got media stream event");
    if([event.mediaType isEqualToString:ALMediaType.kScreen]) {
        if(event.screenPublished) {
            [_renderer setupWithService:_service withSink:event.screenSinkId];
            [_renderer start:nil];
            _renderer.hidden = NO;
        } else {
            [_renderer stop:nil];
            _renderer.hidden = YES;
        }
    }
    
}

- (void) onMediaStreamFailure:(ALMediaStreamFailureEvent*) event {
    if(![event.mediaType isEqualToString:ALMediaType.kScreen]) {
        return;
    }
    if(event.errCode == kMediaSharedWindowClosed) {
        _statusLbl.textColor = RED;
        _statusLbl.stringValue = @"The shared window was closed. Select other one.";
    } else {
        _statusLbl.textColor = RED;
        _statusLbl.stringValue = [NSString stringWithFormat:@"Screen sharing feed failed: %@ (%d)",
                                  event.errMessage, event.errCode];
    }
    [_service unpublish:Consts.SCOPE_ID what:ALMediaType.kScreen responder:nil];
}

@end


@implementation Consts

+ (NSNumber*) APP_ID {
    // TODO update this to use some real value
    return @1;
}

+ (NSString*) API_KEY {
    // TODO update this to use some real value
    return @"AddLiveSuperSecret";
}

+ (NSString*) SCOPE_ID {
    return @"OSX_Test";
}


@end