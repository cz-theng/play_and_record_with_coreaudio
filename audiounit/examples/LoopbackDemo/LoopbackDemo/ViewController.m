//
//  ViewController.m
//  LoopbackDemo
//
//  Created by CZ on 12/23/16.
//  Copyright © 2016 projm. All rights reserved.
//

#import "ViewController.h"


#define VErr(err, msg)  do {\
    if(nil != err) {\
        NSLog(@"[ERR]:%@--%@", (msg), [err localizedDescription]);\
        return ;\
    }\
} while(0)

#define VStatus(err, msg) do {\
    if(noErr != err) {\
        NSLog(@"[ERR-%d]:%@", err, (msg));\
        return ;\
    }\
} while(0)

#define VStatusBOOL(err, msg) do {\
    if(noErr != err) {\
        NSLog(@"[ERR-%d]:%@", err, (msg));\
        return NO;\
    }\
} while(0)

@interface ViewController ()

@end

@implementation ViewController {
    AUGraph _processingGraph;
    AUNode _remoteIONode;
    AudioUnit _remoteIOUnit;
    AudioComponentDescription _remoteIODesc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupAudioSession];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupAudioSession{
    NSError *error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [session setActive:YES error:&error];
    if (nil != error) {
        NSLog(@"AudioSession setActive error:%@", error.localizedDescription);
        return;
    }
    
    error = nil;
    NSString *category = AVAudioSessionCategoryPlayAndRecord;
    
    [[AVAudioSession sharedInstance] setCategory:category error:&error];
    if (nil != error) {
        NSLog(@"AudioSession setCategory(AVAudioSessionCategoryPlayAndRecord) error:%@", error.localizedDescription);
        return;
    } else {
        NSLog(@"set category to %@", category);
    }
}


- (void) buildAUGraph {
    OSStatus stts;
    NewAUGraph (&_processingGraph);
    VStatus(stts, @"NewAUGraph Error!");
    _remoteIODesc.componentType = kAudioUnitType_Output;
    _remoteIODesc.componentSubType = kAudioUnitSubType_RemoteIO;
    _remoteIODesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    _remoteIODesc.componentFlags = _remoteIODesc.componentFlagsMask = 0;
    
    
    stts = AUGraphAddNode(_processingGraph, &_remoteIODesc, &_remoteIONode);
    VStatus(stts, @"Add Node Error!");
    stts = AUGraphOpen (_processingGraph);
    VStatus(stts, @"Open Graph Error!");
    stts = AUGraphNodeInfo (_processingGraph, _remoteIONode, NULL, &_remoteIOUnit);
    VStatus(stts, @"Get Node Info Error!");
    
    UInt32 one = 1;
    stts = AudioUnitSetProperty(_remoteIOUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
    VStatus(stts, @"could not enable input on AURemoteIO");
    stts = AudioUnitSetProperty(_remoteIOUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one));
    VStatus(stts, @"could not enable output on AURemoteIO");
    
    
    struct AudioStreamBasicDescription inFmt;
    inFmt.mFormatID = kAudioFormatLinearPCM; // pcm data
    inFmt.mBitsPerChannel = 16; // 16bit
    inFmt.mChannelsPerFrame = 2; // double channel
    inFmt.mSampleRate = 44100; // 44.1kbps sample rate
    inFmt.mFramesPerPacket =1 ;
    inFmt.mBytesPerFrame =inFmt.mBitsPerChannel*inFmt.mChannelsPerFrame/8;
    inFmt.mBytesPerPacket = inFmt.mBytesPerFrame * inFmt.mFramesPerPacket;
    stts = AudioUnitSetProperty(_remoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &inFmt, sizeof(inFmt));
    VStatus(stts, @"set kAudioUnitProperty_StreamFormat of input error");
    
    struct AudioStreamBasicDescription outFmt = inFmt;
    stts = AudioUnitSetProperty(_remoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &outFmt, sizeof(outFmt));
    VStatus(stts, @"set kAudioUnitProperty_StreamFormat of output error");
}




- (IBAction)onRecord:(id)sender {
    
}

- (IBAction)onPlayer:(id)sender {
    
}

@end
