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

- (id) initWithMsgsSink:(NSTextView*) msgsSink;

- (void) onUserEvent:(ALUserStateChangedEvent*) event;

@end


@implementation ALAppDelegate {
    ALService* _alService;
    ALEventsListener* _listener;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_stateLabel setStringValue:@"App Loaded."];
    [_stateLabel setStringValue:@"Initialising AddLive."];
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
    
    descr.url = [NSString stringWithFormat:@"127.0.0.1:7000/%@", descr.scopeId];
    descr.autopublishAudio = NO;
    descr.autopublishVideo = NO;
    descr.authDetails.userId = rand() % 10000;
    descr.authDetails.salt = @"some super random string";
    descr.authDetails.expires = time(0) + 60 * 60;
    ResultBlock onConnect = ^(ALError* err, id nothing) {
        if([self handleErrMaybe:err where:@"connect"])
            return;
        _stateLabel.textColor = GREEN;
        [_stateLabel setStringValue:@"Connected."];
    };
    _stateLabel.textColor = BLACK;
    [_stateLabel setStringValue:@"Connecting..."];

    [_alService connect:descr responder:[ALResponder responderWithBlock:onConnect]];
}

- (IBAction) disconnect:(id)sender {
    
}

- (IBAction) sendMsg:(id)sender {
    NSString* msg = _messageInp.stringValue;
    _messageInp.stringValue = @"";
    [_alService sendMessage:Consts.SCOPE_ID
                    message:[msg dataUsingEncoding:NSUTF8StringEncoding]
                recipientId:nil
                  responder:nil];
}

- (void) onPlatformReady:(ALError*) error {
    if([self handleErrMaybe:error where:@"initPlatform"]) {
        return;
    }
    [self setListener];
}

- (void) setListener {
    _listener = [[ALEventsListener alloc] initWithMsgsSink:_msgsSink];
    ResultBlock onListener = ^(ALError* err, id nothing) {
        [self showVersion];
    };
    [_alService addServiceListener:_listener responder:[ALResponder responderWithBlock:onListener]];
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
    NSTextView* _msgsSink;
}

- (id) initWithMsgsSink:(NSTextView*) msgsSink {
    self = [super init];
    if(self) {
        _msgsSink = msgsSink;
        [self appendMsg:@"You just joined the chat"];
    }
    return self;
}

- (void) onUserEvent:(ALUserStateChangedEvent*) event {
    NSLog(@"Got remote user event: %@", event);
    if(event.isConnected) {
        [self appendMsg:[NSString stringWithFormat:@"User %lld just joined the chat", event.userId]];
    } else {
        [self appendMsg:[NSString stringWithFormat:@"User %lld just left the chat", event.userId]];
    }
}

- (void) onMessage:(ALMessageEvent*) event {
    NSString* msg = [[NSString alloc] initWithData:event.data encoding:NSUTF8StringEncoding];
    NSString* msgFormatted = [NSString stringWithFormat:@"New message from %lld: %@", event.srcUserId, msg];
    [self appendMsg:msgFormatted];
}

- (void) appendMsg:(NSString*) msg {
    NSTextStorage *storage = [_msgsSink textStorage];
    [storage beginEditing];
    NSString* msgFormatted = [NSString stringWithFormat:@"%@\n", msg];
    [storage appendAttributedString:[[NSAttributedString alloc] initWithString:msgFormatted]];
    [storage endEditing];
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
    return @"";
}


@end