//
//  ViewController.m
//  OpenALCarGoDemo
//
//  Created by CZ on 12/8/16.
//  Copyright © 2016 projm. All rights reserved.
//

#import "ViewController.h"
#include "wav_helper.h"

@import OpenAL;
@import AVFoundation;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (strong, nonatomic) NSTimer *ms100Timer;
@property (weak, nonatomic) IBOutlet UIButton *dogPlayBtn;
@end

@implementation ViewController{
    ALCdevice *defaultDevice;
    ALCcontext *mainContext;
    ALuint carBuffer;
    ALuint dogBuffer;
    ALuint carSource;
    ALuint dogSource;
}

- (void) initAudioSession{
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initAudioSession];
    
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

-(BOOL) initBuffers{
    /** car **/
    alGenBuffers(1, &carBuffer);
    if (alGetError() != AL_NO_ERROR) {
        return NO;
    }
    
    void *data= NULL;
    size_t size;
    size_t freq;
    load_wav_file([[[NSBundle mainBundle] pathForResource:@"car" ofType:@"wav"] cStringUsingEncoding:NSUTF8StringEncoding], &data, &size, &freq);
    alBufferData(carBuffer, AL_FORMAT_MONO16, data, size, freq);
    
    ALenum error;
    if ((error=alGetError()) != AL_NO_ERROR) {
        NSLog(@"alBufferData error");
    }
    
    /** dog **/
    alGenBuffers(1, &dogBuffer);
    if (alGetError() != AL_NO_ERROR) {
        return NO;
    }
    
    load_wav_file([[[NSBundle mainBundle] pathForResource:@"dog" ofType:@"wav"] cStringUsingEncoding:NSUTF8StringEncoding], &data, &size, &freq);
    alBufferData(dogBuffer, AL_FORMAT_MONO16, data, size, freq);
    
    if ((error=alGetError()) != AL_NO_ERROR) {
        NSLog(@"alBufferData error");
    }
    
    return YES;
}

-(BOOL) initSource {
    ALenum error ;
    /** car **/
    alGenSources(1, &carSource);
    if (alGetError() != AL_NO_ERROR) {
        NSLog(@"alGenSources(1, &carSource)");
        return NO;
    }
    
    alSource3f(carSource, AL_DIRECTION, -1, 0, 0);
    alSource3f(carSource, AL_POSITION, 0, 0, 0);
    alSourcei(carSource, AL_BUFFER, carBuffer);
    
    /** dog **/
    alGenSources(1, &dogSource);
    if (alGetError() != AL_NO_ERROR) {
        NSLog(@"alGenSources(1, &dogSource");
        return NO;
    }
    
    alSource3f(dogSource, AL_DIRECTION, -1, 0, 0);
    alSource3f(dogSource, AL_POSITION, 0, 0, 0);
    alSourcei(dogSource, AL_BUFFER, dogBuffer);
    if (alGetError() != AL_NO_ERROR) {
        NSLog(@"alSourcei error");
        return NO;
    }

    return YES;
}

-(BOOL) initListeners {
    return YES;
    ALfloat listenerOri[] = { 1.0f, 0.0f, 0.0f, -1.0f, 0.0f, 0.0f };
    
    alListener3f(AL_POSITION, 0, 0, 0);
    alListener3f(AL_VELOCITY, 0, 0, 0);
    alListenerfv(AL_ORIENTATION, listenerOri);
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) timer_100ms: (id) sender {
    float srcPost[3] = {0};
    float velocity[3] = {1, 0, 0};
    alGetSource3f(carSource, AL_POSITION, &srcPost[0], &srcPost[1], &srcPost[2]);
    
    for (int i=0; i<3; i++) {
        srcPost[i] += velocity[i];
    }
    alSource3f(carSource, AL_POSITION, srcPost[0], srcPost[1], srcPost[2]);
}

-(void) play {
    alSourcePlay(carSource);
    //_ms100Timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timer_100ms:) userInfo:nil repeats:YES];
    ALenum error;
    if ((error = alGetError() )!= AL_NO_ERROR) {
        NSLog(@"play error with %d", error);
        return;
    }
}
- (IBAction)onPlayDogVoice:(id)sender {
    static BOOL once = NO;
    if (!once) {
        [_dogPlayBtn setImage:[UIImage imageNamed:@"btn_pause"] forState:UIControlStateNormal];
        [self playDogVoice];
        once = YES;
    } else {
        [_dogPlayBtn setImage:[UIImage imageNamed:@"btn_play"] forState:UIControlStateNormal];
        [self stopDogVoice];
        once = NO;
    }
}

- (void) playDogVoice {
    alSourcePlay(dogSource);
    ALenum error;
    if ((error = alGetError() )!= AL_NO_ERROR) {
        NSLog(@"play error with %d", error);
        return;
    }
}

- (void) stopDogVoice {
    alSourceStop(dogSource);
    ALenum error;
    if ((error = alGetError() )!= AL_NO_ERROR) {
        NSLog(@"stop error with %d", error);
        return;
    }
}

-(void) stop {
    alSourceStop(carSource);
    [_ms100Timer invalidate];
    ALenum error;
    if ((error = alGetError() )!= AL_NO_ERROR) {
        NSLog(@"stop error with %d", error);
        return;
    }
}

- (IBAction)onPlay:(id)sender {
    static BOOL once = NO;
    if (!once) {
        [_playBtn setImage:[UIImage imageNamed:@"btn_pause"] forState:UIControlStateNormal];
        [self play];
        once = YES;
    } else {
        [_playBtn setImage:[UIImage imageNamed:@"btn_play"] forState:UIControlStateNormal];
        [self stop];
        once = NO;
    }
}

@end
