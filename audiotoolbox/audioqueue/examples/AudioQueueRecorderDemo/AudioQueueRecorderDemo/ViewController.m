//
//  ViewController.m
//  AudioQueueRecorderDemo
//
//  Created by apollo on 14/12/2016.
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


void impAudioQueueInputCallback ( void * inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp * inStartTime, UInt32                          inNumberPacketDescriptions, const AudioStreamPacketDescription *inPacketDescs)
{
    struct RecorderStat *recorderStat = (struct RecorderStat *) inUserData;
}

@interface ViewController () {
    struct RecorderStat recorderStat_;
}

@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *prepareBtn;
@property (strong, nonatomic) NSString *filePath;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _filePath = [NSString stringWithFormat:@"%@/%@", docDir, @"voice.mp3"];
}

- (void) setAudioSession: (int) mode {
    NSError *error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:&error];
    if (nil != error) {
        NSLog(@"AudioSession setActive error:%@", error.localizedDescription);
        return;
    }
    
    
    error = nil;
    NSString *category;
    if (1 == mode) {
        category = AVAudioSessionCategoryRecord;
    } else {
        category = AVAudioSessionCategoryAmbient;
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&error];
    if (nil != error) {
        NSLog(@"AudioSession setCategory(AVAudioSessionCategoryPlayAndRecord) error:%@", error.localizedDescription);
        return;
    }
}


- (BOOL) prepareAudioRecorder {
    // step 1: set up the format of recording
    recorderStat_.mDataFormat.mFormatID =  kAudioFormatMPEGLayer3;
    recorderStat_.mDataFormat.mSampleRate = 441000;
    recorderStat_.mDataFormat.mChannelsPerFrame = 2;
    recorderStat_.mDataFormat.mBitsPerChannel = 16;
    recorderStat_.mDataFormat.mFramesPerPacket = 1;
    recorderStat_.mDataFormat.mBytesPerFrame = recorderStat_.mDataFormat.mChannelsPerFrame * recorderStat_.mDataFormat.mBitsPerChannel / 8;
    recorderStat_.mDataFormat.mBytesPerPacket = recorderStat_.mDataFormat.mBytesPerFrame * recorderStat_.mDataFormat.mFramesPerPacket;
    
    // step 2: create audio file
    NSURL * tmpURL = [NSURL URLWithString:_filePath];
    CFURLRef url = (__bridge CFURLRef) tmpURL;
    OSStatus stts = AudioFileOpenURL(url, kAudioFileWritePermission, 0, &recorderStat_.mAudioFile);
    VStatusBOOL(stts, @"AudioFileOpenURL");
    NSLog(@"open file %@ success!", url);
    
    // step 3: create audio intpu queue
    stts = AudioQueueNewInput(&recorderStat_.mDataFormat, impAudioQueueInputCallback, &recorderStat_,CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &recorderStat_.mQueue);
    VStatusBOOL(stts, @"AudioQueueNewInput");
    
    return YES;
}

- (BOOL) disposeAudioRecorder {
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onPrepare:(id)sender {
    static BOOL once = NO;
    if (! once ) {
        if (![self prepareAudioRecorder]) {
            NSLog(@"prepare Audio Recorder Error");
            return ;
        }
        
        [_prepareBtn setTitle:@"Dispose" forState:UIControlStateNormal];
        once = YES;
    } else {
        if(![self disposeAudioRecorder]) {
            NSLog(@"dispose Audio Recoder Error");
            return ;
        }
        
        [_prepareBtn setTitle:@"Prepare" forState:UIControlStateNormal];
        once = NO;
    }
}

- (void) startRecord {
    [self setAudioSession:1];
}

- (void) stopRecord {
    [self setAudioSession:2];
}

- (IBAction)onPlay:(id)sender {
    [self setAudioSession:2];
}

- (IBAction)onRecord:(id)sender {
    static BOOL once = NO;
    if (! once ) {
        [self startRecord];
        [_recordBtn setImage:[UIImage imageNamed:@"btn_microphone_closed"] forState:UIControlStateNormal];
        once = YES;
    } else {
        [self stopRecord];
        [_recordBtn setImage:[UIImage imageNamed:@"btn_microphone_open"] forState:UIControlStateNormal];
        once = NO;
    }
}

@end
