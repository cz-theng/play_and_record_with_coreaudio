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
        NSLog(@"[ERR:%d]:%@", err, (msg));\
        return ;\
    }\
} while(0)

#define VStatusBOOL(err, msg) do {\
    if(noErr != err) {\
        NSLog(@"[ERR:%d]:%@", err, (msg));\
        return NO;\
    }\
} while(0)


void impAudioQueueInputCallback ( void * inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp * inStartTime, UInt32 inNumberPacketDescriptions, const AudioStreamPacketDescription *inPacketDescs)
{
    struct RecorderStat *recorderStat = (struct RecorderStat *) inUserData;
    
    if (! recorderStat->mIsRunning) {
        OSStatus stts = AudioQueueStop(recorderStat->mQueue, true);
        VStatus(stts, @"AudioQueueStop error");
        AudioFileClose(recorderStat->mAudioFile);
        return ;
    }
    
    if (0 == inNumberPacketDescriptions && recorderStat->mDataFormat.mBytesPerPacket != 0) { // for CBR
        inNumberPacketDescriptions = recorderStat->bufferByteSize/recorderStat->mDataFormat.mBytesPerPacket;
    }
    
    OSStatus stt = AudioFileWritePackets(recorderStat->mAudioFile, false, recorderStat->bufferByteSize, inPacketDescs, recorderStat->mCurrentPacket, &inNumberPacketDescriptions, inBuffer->mAudioData);
    VStatus(stt, @"AudioFileWritePackets error");
    
    recorderStat->mCurrentPacket += inNumberPacketDescriptions;
    stt = AudioQueueEnqueueBuffer(recorderStat->mQueue, inBuffer, 0, NULL);
    VStatus(stt, @"AudioQueueEnqueueBuffer error");
}

@interface ViewController () {
    struct RecorderStat recorderStat_;
}

@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *prepareBtn;
@property (strong, nonatomic) NSString *filePath;
@property (strong, nonatomic) AVAudioPlayer *player;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _filePath = [NSString stringWithFormat:@"%@/%@", docDir, @"voice.wav"];
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
        category = AVAudioSessionCategorySoloAmbient;
    }
    
    [[AVAudioSession sharedInstance] setCategory:category error:&error];
    if (nil != error) {
        NSLog(@"AudioSession setCategory(AVAudioSessionCategoryPlayAndRecord) error:%@", error.localizedDescription);
        return;
    } else {
        NSLog(@"set category to %@", category);
    }
}

- (BOOL) preparePlayer: (NSURL *) fileName {
    NSError *error = nil;
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileName error:&error];
    if (nil != error) {
        NSLog(@"create player[%@] error:%@", fileName, error.localizedDescription);
        return NO;
    }
    _player.delegate= self;
    _player.numberOfLoops = 999;
    BOOL rst = [_player prepareToPlay];
    NSLog(@"Prepare with %d", rst);
    NSLog(@"file length is %g", _player.duration);
    NSLog(@"channle number %d", _player.numberOfChannels);
    return YES;
}



- (BOOL) prepareAudioRecorder {
    OSStatus stts  = noErr;
    // step 1: set up the format of recording
    recorderStat_.mDataFormat.mFormatID =  kAudioFormatLinearPCM;
    recorderStat_.mDataFormat.mSampleRate = 44100.0;
    recorderStat_.mDataFormat.mChannelsPerFrame = 2;
    recorderStat_.mDataFormat.mBitsPerChannel = 16;
    recorderStat_.mDataFormat.mFramesPerPacket = 1;
    recorderStat_.mDataFormat.mBytesPerFrame = recorderStat_.mDataFormat.mChannelsPerFrame * recorderStat_.mDataFormat.mBitsPerChannel / 8;
    recorderStat_.mDataFormat.mBytesPerPacket = recorderStat_.mDataFormat.mBytesPerFrame * recorderStat_.mDataFormat.mFramesPerPacket;
    recorderStat_.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsBigEndian;

    // step 2: create audio intpu queue
    stts = AudioQueueNewInput(&recorderStat_.mDataFormat, impAudioQueueInputCallback, &recorderStat_,CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &recorderStat_.mQueue);
    VStatusBOOL(stts, @"AudioQueueNewInput");
    
    // step 3: get the detail format
    UInt32 dataFormatSize = sizeof (recorderStat_.mDataFormat);
    stts = AudioQueueGetProperty(recorderStat_.mQueue, kAudioQueueProperty_StreamDescription, &recorderStat_.mDataFormat, &dataFormatSize);
    VStatusBOOL(stts, @"AudioQueueGetProperty-AudioQueueGetProperty");
    
    // step 4: create audio file
    NSURL * tmpURL = [NSURL URLWithString:_filePath];
    CFURLRef url = (__bridge CFURLRef) tmpURL;    
    stts = AudioFileCreateWithURL(url, kAudioFileAIFFType, &recorderStat_.mDataFormat, kAudioFileFlags_EraseFile, &recorderStat_.mAudioFile);
    VStatusBOOL(stts, @"AudioFileOpenURL");    
    NSLog(@"open file %@ success!", url);
    
    // step 5: prepare buffers and buffer queue
    recorderStat_.bufferByteSize = kNumberPackages * recorderStat_.mDataFormat.mBytesPerPacket;
    for (int i=0; i<kNumberBuffers; i++) {
        AudioQueueAllocateBuffer(recorderStat_.mQueue, recorderStat_.bufferByteSize, &recorderStat_.mBuffers[0]);
        AudioQueueEnqueueBuffer(recorderStat_.mQueue, recorderStat_.mBuffers[i], 0, NULL);
    }

    return YES;
}

- (BOOL) disposeAudioRecorder {
    if (recorderStat_.mQueue) {
        AudioQueueDispose(recorderStat_.mQueue, false);
        recorderStat_.mQueue = NULL;
    }

    if (recorderStat_.mAudioFile) {
        AudioFileClose(recorderStat_.mAudioFile);
        recorderStat_.mAudioFile = NULL;
    }

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
    OSStatus stts =  AudioQueueStart(recorderStat_.mQueue, NULL);
    VStatus(stts, @"AudioQueueStart error");
    recorderStat_.mIsRunning = true;
}

- (void) stopRecord {
    [self setAudioSession:2];

    recorderStat_.mIsRunning = false;
}

- (IBAction)onPlay:(id)sender {
    [self setAudioSession:2];
    [self preparePlayer:[NSURL URLWithString:_filePath]];

    BOOL rst = [_player play];
    NSLog(@"Play with %d", rst);
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

#pragma mark AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"audioPlayerDidFinishPlaying rst: %d", flag);
}


- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error {
    NSLog(@"audioPlayerDecodeErrorDidOccur error:%@", error.localizedDescription);
}

@end
