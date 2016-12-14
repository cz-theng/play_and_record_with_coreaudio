//
//  ViewController.m
//  AudioQueueReaderDemo
//
//  Created by apollo on 07/12/2016.
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



void impAudioQueueOutputCallback(void *inUserData,AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    struct PlayerStat *playerStat = (struct PlayerStat *) inUserData;
    // step1: read data from your file
    UInt32 bufLen = playerStat->bufferByteSize;
    UInt32 numPkgs = kNumberPackages;
    OSStatus stts = AudioFileReadPacketData(playerStat->mAudioFile, NO, &bufLen, playerStat->mPacketDescs, playerStat->mCurrentPacket, &numPkgs, inBuffer->mAudioData);
    VStatus(stts, @"AudioFileReadPacketData");
    inBuffer->mAudioDataByteSize = bufLen;
    
    // step2: enqueue data buffer to AudioQueueBufferRef
    stts = AudioQueueEnqueueBuffer(playerStat->mQueue, inBuffer, numPkgs, playerStat->mPacketDescs);
    VStatus(stts, @"AudioQueueEnqueueBuffer");
    playerStat->mCurrentPacket  += numPkgs;
    
    
    // step3: decid wheather should stop the AduioQueue
    if (0 == numPkgs) {
        AudioQueueStop(playerStat->mQueue, false);
    }
}

@interface ViewController () {
    struct PlayerStat playerStat_;
}

@property (weak, nonatomic) IBOutlet UIButton *prepareBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (strong, nonatomic) MPMediaPickerController * mpPickerVC;
@property (strong, nonatomic) NSURL *musicURL;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _mpPickerVC = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];
    _mpPickerVC.prompt = @"请选择要读取的歌曲";
    _mpPickerVC.allowsPickingMultipleItems = NO;
    _mpPickerVC.showsCloudItems = NO;
    _mpPickerVC.delegate  = self;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) play {
    OSStatus stts = AudioQueueStart(playerStat_.mQueue, NULL);
    VStatus(stts, @"AudioQueueStart");
}

- (void) stop {
    OSStatus stts = AudioQueuePause(playerStat_.mQueue);
    //OSStatus stts = AudioQueueStop(playerStat_.mQueue, YES);
    VStatus(stts, @"AudioQueueStop");
}

- (BOOL) prepareAudioFile {
    [self setAudioSession];
    
    // step 1: open a file
    
    CFURLRef url = (__bridge CFURLRef) _musicURL;
    if (nil == url) {
        url = (__bridge CFURLRef) [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"01" ofType:@"caf"]];
    }
    OSStatus stts = AudioFileOpenURL(url, kAudioFileReadPermission, 0, &playerStat_.mAudioFile);
    VStatusBOOL(stts, @"AudioFileOpenURL");
    NSLog(@"open file %@ success!", url);
    
    // step 2: read file's properity
    UInt32 descSize = sizeof(playerStat_.mDataFormat);

    stts =  AudioFileGetProperty(playerStat_.mAudioFile, kAudioFilePropertyDataFormat, &descSize, &playerStat_.mDataFormat);
    VStatusBOOL(stts, @"AudioFileGetProperty-kAudioFilePropertyDataFormat");
    
    // step 3: create a buffer queue
    stts = AudioQueueNewOutput(&playerStat_.mDataFormat, impAudioQueueOutputCallback, &playerStat_, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &playerStat_.mQueue);
    VStatusBOOL(stts, @"AudioFileGetProperty-kAudioFilePropertyDataFormat");
    
    // step 4: allocat memeory for pacakge's dscription
    UInt32 maxPacketSize;
    UInt32 propertySize = sizeof (maxPacketSize);
    stts =  AudioFileGetProperty(playerStat_.mAudioFile, kAudioFilePropertyPacketSizeUpperBound, &propertySize, &maxPacketSize);
    VStatusBOOL(stts, @"AudioFileGetProperty-kAudioFilePropertyDataFormat");
    playerStat_.bufferByteSize = kNumberPackages * maxPacketSize;
    playerStat_.mPacketDescs =(AudioStreamPacketDescription *) malloc(kNumberPackages * sizeof(AudioStreamPacketDescription));
    
    // step 5: deal magic cookie data
    UInt32 cookieSize = sizeof(UInt32);
    bool couldNotGetProperty = AudioFileGetPropertyInfo (playerStat_.mAudioFile, kAudioFilePropertyMagicCookieData,&cookieSize,  NULL);
    
    if (!couldNotGetProperty && cookieSize) {
        char* magicCookie = (char *) malloc (cookieSize);
        AudioFileGetProperty ( playerStat_.mAudioFile, kAudioFilePropertyMagicCookieData, &cookieSize, magicCookie);
        AudioQueueSetProperty ( playerStat_.mQueue,  kAudioQueueProperty_MagicCookie,  magicCookie,  cookieSize);
        free (magicCookie);
    }
    
    // step 6: setup buffer queues
    playerStat_.mCurrentPacket = 0;
    
    for (int i = 0; i < kNumberBuffers; ++i) {
        AudioQueueAllocateBuffer (playerStat_.mQueue, playerStat_.bufferByteSize, &playerStat_.mBuffers[i]);
        impAudioQueueOutputCallback(&playerStat_, playerStat_.mQueue, playerStat_.mBuffers[i]);
    }
    
    
    // set gain
    
    Float32 gain = 1.0;
    AudioQueueSetParameter ( playerStat_.mQueue, kAudioQueueParam_Volume, gain );

    return YES;
}
- (IBAction)onPrepare:(id)sender {
    static BOOL once = NO;
    if (! once ) {
        if (! [self prepareAudioFile]) {
            NSLog(@"dipose error!");
            return ;
        }
        [_prepareBtn setTitle:@"Dispose" forState:UIControlStateNormal];
        once = YES;
    } else {
        if (! [self dipose]) {
            NSLog(@"dipose error!");
            return ;
        }
        [_prepareBtn setTitle:@"Prepare" forState:UIControlStateNormal];
        once = NO;
    }
    
}


- (BOOL) dipose {
    if (playerStat_.mQueue) {
        AudioQueueDispose(playerStat_.mQueue, YES);
    }
    
    if (playerStat_.mAudioFile) {
        AudioFileClose(playerStat_.mAudioFile);
    }

    if (playerStat_.mPacketDescs) {
        free(playerStat_.mPacketDescs);
        playerStat_.mPacketDescs = NULL;
    }
    
    return YES;
}

- (void) setAudioSession {
    NSError *error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:&error];
    if (nil != error) {
        NSLog(@"AudioSession setActive error:%@", error.localizedDescription);
        return;
    }
    
    
    error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:&error];
    if (nil != error) {
        NSLog(@"AudioSession setCategory(AVAudioSessionCategoryPlayAndRecord) error:%@", error.localizedDescription);
        return;
    }

    
}

- (IBAction)onPickMusic:(id)sender {
    
    [self presentViewController:_mpPickerVC animated:YES completion:^{
        //
    }];
}

- (IBAction)onPlay:(id)sender {
    static BOOL once = NO;
    if (! once) {
        [self play];
        [_playBtn setImage:[UIImage imageNamed:@"btn_pause"] forState:UIControlStateNormal];
        once = YES;
    } else {
        [self stop];
        [_playBtn setImage:[UIImage imageNamed:@"btn_play"] forState:UIControlStateNormal];
        once = NO;
    }
}

#pragma mark  MPMediaPickerControllerDelegate

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    if (NULL == mediaItemCollection) {
        NSLog(@"mediaItemCollection is null");
        return ;
    }
    for (MPMediaItem *item in [mediaItemCollection items]) {
        if (NULL == item) {
            NSLog(@"item is null");
            continue;
        }
        NSString *title = [item valueForKey:MPMediaItemPropertyTitle];
        _musicURL = [item valueForKey:MPMediaItemPropertyAssetURL];
        NSLog(@"select with sound: %@ with url %@ artist is %@", title, _musicURL, [item valueForKey:MPMediaItemPropertyArtist]);
        break ;
    }
    [_mpPickerVC dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    NSLog(@"Cancel");
    [_mpPickerVC dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

@end
