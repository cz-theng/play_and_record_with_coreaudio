//
//  ViewController.m
//  ExtAudioFileServicesDemo
//
//  Created by apollo on 30/11/2016.
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



@interface ViewController () {
    AudioFileID musicFD_;
    ExtAudioFileRef extMusicFD_;
    char format_[5];
    UInt32  maxPkgSize_;
    UInt32 extMaxPktSize_;
    UInt64 pkgNum_;
    AudioStreamBasicDescription desc_;
}
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

- (IBAction)onPickMusic:(id)sender {
    [self presentViewController:_mpPickerVC animated:YES completion:^{
        //
    }];
}

- (IBAction)onExtOpen:(id)sender {
    OSStatus stts ;
    CFURLRef url = (__bridge CFURLRef) _musicURL;
    if (nil == url) {
        url = (__bridge CFURLRef) [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"01" ofType:@"caf"]];
    }
    stts = ExtAudioFileOpenURL(url, &extMusicFD_);
    VStatus(stts, @"ExtAudioFileOpenURL");
    NSLog(@"open file %@ success!", _musicURL);
}

- (IBAction)onExtClose:(id)sender {
    OSStatus stts;
    stts = ExtAudioFileDispose(extMusicFD_);
    VStatus(stts, @"ExtAudioFileDispose");
    NSLog(@"close ext file success");
}

- (IBAction)onReadProperity:(id)sender {
    //ExtAudioFilePropertyID
    OSStatus stts;
    UInt32 descSize = sizeof(desc_);
    stts = ExtAudioFileGetProperty(extMusicFD_, kExtAudioFileProperty_FileDataFormat, &descSize, &desc_);
    VStatus(stts, @"ExtAudioFileGetProperty");
    
    UInt32 maxPktSize = 0;
    UInt32 maxPktSizeLen = sizeof(maxPktSize);
    stts = ExtAudioFileGetProperty(extMusicFD_, kExtAudioFileProperty_FileMaxPacketSize, &maxPktSizeLen, &maxPktSize);
    VStatus(stts, @"ExtAudioFileGetProperty");
    extMaxPktSize_ = maxPktSize;
    
    
    // set the output format
    AudioStreamBasicDescription outDesc = desc_;
    outDesc.mSampleRate = 44100;
    outDesc.mFormatID = kAudioFormatLinearPCM;
    outDesc.mFormatFlags = kLinearPCMFormatFlagIsFloat;
    outDesc.mBitsPerChannel = 16; // 16bit sample depth
    outDesc.mChannelsPerFrame = 2;
    outDesc.mBytesPerFrame = outDesc.mChannelsPerFrame * outDesc.mBitsPerChannel/8;
    outDesc.mFramesPerPacket = 1;
    outDesc.mBytesPerPacket = outDesc.mFramesPerPacket * outDesc.mBytesPerFrame;
    UInt32 outDescSize = sizeof(outDesc);
    
    stts = ExtAudioFileSetProperty(extMusicFD_, kExtAudioFileProperty_ClientDataFormat, &outDescSize, &outDesc);
    VStatus(stts, @"ExtAudioFileSetProperty");
    

}

- (IBAction)onRead:(id)sender {
    OSStatus stts;
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mNumberChannels = desc_.mChannelsPerFrame;
    bufferList.mBuffers[0].mDataByteSize = extMaxPktSize_;
    bufferList.mBuffers[0].mData = malloc(extMaxPktSize_);
    if (NULL ==bufferList.mBuffers[0].mData ) {
        NSLog(@"malloc bufferList.mBuffers[0].mData nullptr");
        return ;
    }
    
    UInt32 frameNum = 1;
    stts = ExtAudioFileRead(extMusicFD_, &frameNum, &bufferList);
    VStatus(stts, @"AudioBufferList"); // also need free
    
    if (NULL !=bufferList.mBuffers[0].mData) {
        free(bufferList.mBuffers[0].mData);
        bufferList.mBuffers[0].mData = NULL;
    }
    NSLog(@"ExtAudioFileRead frame[%d] with %d", frameNum, bufferList.mBuffers[0].mDataByteSize);

}

- (IBAction)onSeek:(id)sender {
    OSStatus stts;
    SInt64 curPos = 0;
    
    stts = ExtAudioFileTell(extMusicFD_, &curPos);
    VStatus(stts, @"ExtAudioFileTell");
    NSLog(@"before current position %lld", curPos);
    
    stts = ExtAudioFileSeek(extMusicFD_, 2 );
    VStatus(stts, @"ExtAudioFileSeek");
    
    stts = ExtAudioFileTell(extMusicFD_, &curPos);
    VStatus(stts, @"ExtAudioFileTell");
    NSLog(@"after current position %lld", curPos);
    
    [self onRead:nil ];
    
    stts = ExtAudioFileTell(extMusicFD_, &curPos);
    VStatus(stts, @"ExtAudioFileTell");
    NSLog(@"after read current position %lld", curPos);
    
    [self onRead:nil ];
    
    stts = ExtAudioFileTell(extMusicFD_, &curPos);
    VStatus(stts, @"ExtAudioFileTell");
    NSLog(@"after 2 read current position %lld", curPos);
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
