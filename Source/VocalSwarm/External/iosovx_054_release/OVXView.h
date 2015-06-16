//
//  OVXView.h
//  OVX SDK
//
//  Created by Indusface Telecom Pvt Ltd on 21/09/12.
//  Copyright (c) 2012 Indusface Telecom Pvt Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OVXDelegate;



@interface OVXView : UIView <UIWebViewDelegate>
{
     
    //CONFIG PARAMS -  NEED TO BE SET ONLY ONCE IN THE APP
    NSString *title;
    NSString *API_KEY;
    NSString *API_SECRET;
    NSString *BASE_URL;
    NSString *SDK_HANDLER;
    NSString *videoCodec;
    NSString *audioCodec;
    
    //CALL PARAMS - NEED TO BE SET BEFORE EVERY CALL
    NSString *userId;
    NSString *userName;
    NSString *userLocation;
    NSString *groupId;
    NSString *roomName;
    NSString *roomDescription;
    NSString *mood;
    
    NSString *screenId;
    NSString *sessionId;
    NSString *layerId;
    NSString *asiUrl;
    
    // Report/Feedback Fix
    UIViewController* mainController;
    
    //add UUID
    NSString *phoneNumber;
    
    //add dataconnection webview
    
    UIWebView *datawv;
    bool isSessionVideo;
    bool isVideoMute;
    bool webRtcProfile;
    bool endCallInitiated;
    bool voiceProfile;
    //bool useDataChannel;
    
   }


@property (nonatomic, assign) id<OVXDelegate> delegate;

@property (nonatomic, assign) BOOL debug;

//CONFIG PARAMS
@property (retain, nonatomic) NSString *title;
@property (retain, nonatomic) NSString *API_KEY;
@property (retain, nonatomic) NSString *API_SECRET;
@property (retain, nonatomic) NSString *BASE_URL;
@property (retain, nonatomic) NSString *SDK_HANDLER;
@property (retain, nonatomic) NSString *videoCodec;
@property (retain, nonatomic) NSString *audioCodec;

//CALL PARAMS
@property (retain, nonatomic) NSString *userId;
@property (retain, nonatomic) NSString *userName;
@property (retain, nonatomic) NSString *userLocation;
@property (retain, nonatomic) NSString *groupId;
@property (retain, nonatomic) NSString *roomName;
@property (retain, nonatomic) NSString *mood;
@property (retain, nonatomic) NSString *roomDescription;
@property (nonatomic, assign) BOOL showOVXMenuOnTap;
@property (nonatomic, assign) BOOL enableUserInteraction;
@property (nonatomic, assign) BOOL autoHideOnCallEnd;
@property (nonatomic, assign) BOOL webRtcProfile;
@property (nonatomic, assign) BOOL useDataChannel;
@property (nonatomic, assign) BOOL voiceProfile;
@property (nonatomic, assign) BOOL useSDKHandler;

@property (retain, nonatomic) NSString *screenId;
@property (retain, nonatomic) NSString *sessionId;
@property (retain, nonatomic) NSString *layerId;
@property (retain, nonatomic) NSString *asiUrl;
@property (retain, nonatomic) NSString *phoneNumber;




//FUNCTIONS
+ (id)sharedInstance;
-(void)call;
-(void)exitCall;
-(bool)isCallOn;
-(void)showOVXMenu;
-(void)switchLayer:(NSString *)targetLayer;
-(void)updateVideoOrientation;
-(void)switchCamera;
-(void)ovxAudioMute:(BOOL)mute; // if mute=TRUE, then Mute, else UnMute
-(void)ovxVideoMute:(BOOL)mute; // if mute=TRUE, then Mute, else UnMute
-(void)ovxVideoPause:(BOOL)pause; // if pause=TRUE, then Pause, else Resume
-(void)sendData:(NSString*)msg ofType:(NSString*)type;
-(void)showLoadingView;
-(void)hideLoadingView;
-(UIView*)getLocalCameraView;
-(UIView*)getRemoteView:(NSInteger)id;
-(void)setLayerDisplay:(NSInteger) display withLayer: (NSInteger) layer;
-(void)hideLayerDisplay:(NSInteger) display;
-(void)setActiveCalls:(NSInteger)calls;

-(void)resizeLocalCameraView;

-(BOOL) addOtherUsertoGroupChat: (NSString *)callType :(NSString*)serviceType :(NSString*)otherUserId;
-(BOOL) startDirectCall :(NSString *)dialUrl;

@end



@protocol OVXDelegate
-(void)ovxCallInitiated;
-(void)ovxCallStarted;
-(void)ovxCallTerminated:(NSString *)message;
-(void)ovxCallEnded;
-(void)ovxCallFailed:(NSString *)message;
-(void)ovxReceivedData:(NSString*)data;

@end
