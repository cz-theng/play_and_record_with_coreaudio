//
//  ViewController.m
//  OpenALPlayerDemo
//
//  Created by CZ on 12/1/16.
//  Copyright © 2016 projm. All rights reserved.
//

#import "ViewController.h"
#include "wav_helper.h"
@import OpenAL;
@import AVFoundation;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *playBtn;

@end

@implementation ViewController {
    ALCdevice *defaultDevice;
    ALCcontext *mainContext;
    ALuint buffers;
    ALuint sources;
}

- (void) initAudioSession{
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initAudioSession];
    
    [self enumDevices];
    if (! [self initDevice]) {
        NSLog(@"open default device error.");
    }
    
    if (![self initBuffers]) {
        NSLog(@"init buffers error.");
        return ;
    }
    
    if (![self initSource]) {
        NSLog(@"Init Source error");
        return;
    }
    
    if (![self initListeners]) {
        NSLog(@"Init Listener Error");
        return;
    }
    

}

-(void) play {
    alSourcePlay(sources);
    ALenum error;
    if ((error = alGetError() )!= AL_NO_ERROR) {
        NSLog(@"play error with %d", error);
        return;
    }
}

-(void) stop {
    alSourceStop(sources);
    ALenum error;
    if ((error = alGetError() )!= AL_NO_ERROR) {
        NSLog(@"stop error with %d", error);
        return;
    }
}

- (BOOL) initDevice {
    defaultDevice = alcOpenDevice(NULL);
    if (NULL == defaultDevice) {
        return NO;
    }
    
    mainContext = alcCreateContext(defaultDevice, NULL);
    if (NULL == defaultDevice) {
        return NO;
    }
    if( !alcMakeContextCurrent(mainContext) ) {
        return NO;
    }
    return YES;
}

- (void) enumDevices {
    ALboolean enumeration;
    
    enumeration = alcIsExtensionPresent(NULL, "ALC_ENUMERATION_EXT");
    if (enumeration == AL_FALSE) {
        NSLog(@"iOS dosn't support ALC_ENUMERATION_EXT");
        return;
    }
    
    ALCchar * devices = alcGetString(NULL, ALC_DEVICE_SPECIFIER);
    //ALCchar * devices = alcGetString(NULL, ALC_DEFAULT_ALL_DEVICES_SPECIFIER);
    const ALCchar *device = devices, *next = devices + 1;
    size_t len = 0;
    
    NSLog(@"Devices list:\n");
    while (device && *device != '\0' ) {
        NSLog(@"    -> %s", device);
        len = strlen(device);
        device += (len + 1);
        next += (len + 2);
    }
}

-(BOOL) initBuffers{
    
    
    
    alGetError(); // for clear
    alGenBuffers(1, &buffers); // only one buffer
    if (alGetError() != AL_NO_ERROR) {
        return NO;
    }
    
    void *data= NULL;
    size_t size;
    size_t freq;
    load_wav_file([[[NSBundle mainBundle] pathForResource:@"car" ofType:@"wav"] cStringUsingEncoding:NSUTF8StringEncoding], &data, &size, &freq);
    alBufferData(buffers, AL_FORMAT_MONO16, data, size, freq);
    
    ALenum error;
    if ((error=alGetError()) != AL_NO_ERROR) {
        NSLog(@"alBufferData error");
    }
    
    return YES;
}

-(BOOL) initSource {
    alGetError(); // for clear
    alGenSources(1, &sources); // only one source
    if (alGetError() != AL_NO_ERROR) {
        return NO;
    }
    /*
    alSourcef(sources, AL_PITCH, 1);
    // check for errors
    alSourcef(sources, AL_GAIN, 1);
    // check for errors
    alSource3f(sources, AL_POSITION, 0, 0, 0);
    // check for errors
    alSource3f(sources, AL_VELOCITY, 0, 0, 0);
    // check for errors
    alSourcei(sources, AL_LOOPING, AL_FALSE);
    */
    alSourcei(sources, AL_BUFFER, buffers); // bind buffer[0] to source[0]
    if (alGetError() != AL_NO_ERROR) {
        return NO;
    }
    

    
    return YES;
}

-(BOOL) initListeners {
    return YES;
    ALfloat listenerOri[] = { 0.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f };
    
    alListener3f(AL_POSITION, 0, 0, 1.0f);
    // check for errors
    alListener3f(AL_VELOCITY, 0, 0, 0);
    // check for errors
    alListenerfv(AL_ORIENTATION, listenerOri);
    return YES;
}

- (IBAction)onPlay:(id)sender {
    static BOOL once = NO;
    if (!once) {
        [_playBtn setImage:[UIImage imageNamed:@"btn_pause"] forState:UIControlStateNormal];
        once = YES;
        [self play];
    } else {
        [_playBtn setImage:[UIImage imageNamed:@"btn_play"] forState:UIControlStateNormal];
        [self stop];
        once = NO;
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    alDeleteSources(1, &sources);
    if (alGetError() != AL_NO_ERROR) {
        NSLog(@"alDeleteSources error");
        return;
    }
    // you'd better check the error
    alDeleteBuffers(1, &buffers);
    if (alGetError() != AL_NO_ERROR) {
        NSLog(@"alDeleteBuffers error");
        return;
    }
    ALCdevice *device = alcGetContextsDevice(mainContext);
    if (NULL == device) {
        NSLog(@"alcGetContextsDevice error");
        return ;
    }
    alcMakeContextCurrent(NULL);
    if (alGetError() != AL_NO_ERROR) {
        NSLog(@"alcMakeContextCurrent error");
        return;
    }
    alcDestroyContext(mainContext);
    if (alGetError() != AL_NO_ERROR) {
        NSLog(@"alcDestroyContext error");
        return;
    }
    alcCloseDevice(device);
    if (alGetError() != AL_NO_ERROR) {
        NSLog(@"alcCloseDevice error");
        return;
    }
}


@end
