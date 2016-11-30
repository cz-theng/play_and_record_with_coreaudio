//
//  ViewController.m
//  AudioFileServicesDemo
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

@interface ViewController (){
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

- (IBAction)onPick:(id)sender {
    [self presentViewController:_mpPickerVC animated:YES completion:^{
        //
    }];
}

#pragma mark AudioFile

- (IBAction)onOpenFile:(id)sender {
    CFURLRef url = (__bridge CFURLRef) _musicURL;
    if (nil == url) {
        url = (__bridge CFURLRef) [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"01" ofType:@"caf"]];
    }
    OSStatus stts = AudioFileOpenURL(url, kAudioFileReadPermission, 0, &musicFD_);
    VStatus(stts, @"AudioFileOpenURL");
    NSLog(@"open file %@ success!", _musicURL);
}

- (IBAction)onCloseFile:(id)sender {
    OSStatus stts;
    stts = AudioFileClose(musicFD_);
    VStatus(stts, @"AudioFileClose");
    NSLog(@"Close File Success");
}

- (IBAction)onReadProperty:(id)sender {
    OSStatus stts;
    
    UInt32 audioFilePropertyFileFormatSize = 0;
    UInt32 audioFilePropertyFileFormatIsWritable = 0;
    stts = AudioFileGetPropertyInfo(musicFD_, kAudioFilePropertyFileFormat, &audioFilePropertyFileFormatSize, &audioFilePropertyFileFormatIsWritable);
    VStatus(stts, @"kAudioFilePropertyFileFormat");
    if (audioFilePropertyFileFormatSize >4) {
        NSLog(@"format name length > 4");
        return ;
    }
    memset(format_, 0, 5);
    stts = AudioFileGetProperty(musicFD_, kAudioFilePropertyFileFormat, &audioFilePropertyFileFormatSize, format_);
    NSLog(@"Audio's format is %s", format_);
    
    UInt32 audioFilePropertyMaximumPacketSize = 0;
    UInt32 audioFilePropertyMaximumPacketSizeWritable = 0;
    stts = AudioFileGetPropertyInfo(musicFD_, kAudioFilePropertyMaximumPacketSize, &audioFilePropertyMaximumPacketSize, &audioFilePropertyMaximumPacketSizeWritable);
    VStatus(stts, @"kAudioFilePropertyMaximumPacketSize");
    char *audioFilePropertyMaximumPacketSizeBuf = (char *)malloc(audioFilePropertyMaximumPacketSize+1);
    if (NULL == audioFilePropertyMaximumPacketSizeBuf) {
        NSLog(@"audioFilePropertyMaximumPacketSizeBuf is NULL");
        return ;
    }
    memset(audioFilePropertyMaximumPacketSizeBuf, 0, audioFilePropertyMaximumPacketSize+1);
    stts = AudioFileGetProperty(musicFD_, kAudioFilePropertyMaximumPacketSize, &audioFilePropertyMaximumPacketSize, audioFilePropertyMaximumPacketSizeBuf);
    maxPkgSize_ = *(int *)audioFilePropertyMaximumPacketSizeBuf;
    NSLog(@"Audio's max packet size  is %d", maxPkgSize_);
    
    UInt32 audioFilePropertyAudioDataPacketCountSize = 0;
    UInt32 audioFilePropertyAudioDataPacketCountSizeWritable = 0;
    stts = AudioFileGetPropertyInfo(musicFD_, kAudioFilePropertyAudioDataPacketCount, &audioFilePropertyAudioDataPacketCountSize, &audioFilePropertyAudioDataPacketCountSizeWritable);
    VStatus(stts, @"kAudioFilePropertyAudioDataPacketCount");
    if (audioFilePropertyAudioDataPacketCountSize>sizeof(UInt64)) {
        NSLog(@"what a big number");
        return;
    }
    pkgNum_ = 0;
    stts = AudioFileGetProperty(musicFD_, kAudioFilePropertyAudioDataPacketCount, &audioFilePropertyAudioDataPacketCountSize, &pkgNum_);
    NSLog(@"Audio's  packet number  is %llu", pkgNum_);
}

- (IBAction)onReadGlobalInfo:(id)sender {
    OSStatus stts;
    UInt32 infoSize = 0;
    stts = AudioFileGetGlobalInfoSize(kAudioFileGlobalInfo_AllMIMETypes, 0, NULL, &infoSize);
    VStatus(stts, @"AudioFileGetGlobalInfoSize");
    
    NSArray *MIMEs;
    stts = AudioFileGetGlobalInfo(kAudioFileGlobalInfo_AllMIMETypes, 0, NULL, &infoSize, &MIMEs);
    VStatus(stts, @"AudioFileGetGlobalInfo");
    NSLog(@"fileType is %@", MIMEs);
    
    
    UInt32 propertySize;
    OSType readOrwrite = kAudioFileGlobalInfo_ReadableTypes;
    // kAudioFileGlobalInfo_ReadableTypes : kAudioFileGlobalInfo_WritableTypes;
    
    stts = AudioFileGetGlobalInfoSize(readOrwrite, 0, NULL, &propertySize);
    VStatus(stts, @"AudioFileGetGlobalInfoSize");
    
    OSType *types = (OSType*)malloc(propertySize);
    stts = AudioFileGetGlobalInfo(readOrwrite, 0, NULL, &propertySize,  types);
    VStatus(stts, @"AudioFileGetGlobalInfo");
    
    UInt32 numTypes = propertySize / sizeof(OSType);
    for (UInt32 i=0; i<numTypes; ++i){
        CFStringRef name;
        UInt32 outSize = sizeof(name);
        stts = AudioFileGetGlobalInfo(kAudioFileGlobalInfo_FileTypeName, sizeof(OSType), types+i, &outSize, &name);
        VStatus(stts, @"AudioFileGetGlobalInfo");
        NSLog(@"readalbe types: %@", name);
    }
    
}

- (IBAction)onReadUserData:(id)sender {
    OSStatus stts;
    UInt32 userDataCount = 0;
    UInt32 format = 0;
    if (! strcmp(format_, "EVAW")) {
        format = kAudioFileWAVEType;
    } else if (! strcmp(format_, "3GPM")) {
        format = kAudioFileMP3Type;
    } else {
        NSLog(@"Unsupport format");
        ;
    }
    stts = AudioFileCountUserData(musicFD_, kCAF_AudioDataChunkID, &userDataCount);
    VStatus(stts, @"AudioFileCountUserData");
    NSLog(@"AudioFileCountUserData get count %d", userDataCount);
    
    UInt32 userDataSize = 0;
    stts = AudioFileGetUserDataSize(musicFD_, kCAF_AudioDataChunkID, 0, &userDataSize);
    VStatus(stts, @"AudioFileGetUserDataSize");
    NSLog(@"AudioFileGetUserDataSize with size %d", userDataSize);
    
}

- (IBAction)onReadFileContent:(id)sender {
    
    OSStatus stts;
    
    char *packetBuf = (char *) malloc( maxPkgSize_ *2);
    char *byteBuf = (char *)malloc(maxPkgSize_);
    if (NULL == packetBuf || NULL == byteBuf) {
        NSLog(@"NULL == packetBuf || NULL == byteBuf");
        return ;
    }
    
    for (int i=0;i<pkgNum_ ;i+=2 ) {
        
        UInt32 packetBufLen = maxPkgSize_*2;
        memset(packetBuf, packetBufLen, 0);
        memset(byteBuf, maxPkgSize_, 0);
        
        AudioStreamPacketDescription aspDesc[2];
        
        
        UInt32 pktNum = 2;
        if ((i+2)>pkgNum_) {
            pktNum = 1;
        }
        stts = AudioFileReadPacketData(musicFD_, NO, &packetBufLen, aspDesc, i, &pktNum, packetBuf);
        if (kAudioFileEndOfFileError == stts) {
            NSLog(@"End of File");
            break;
        }
        VStatus(stts, @"AudioFileReadPacketData");
        NSLog(@"[%d/%lld]Read two packet data,desc is %d,%d [packetBufLen:%d], [pktNum:%d]", i+2, pkgNum_, aspDesc[0].mDataByteSize, aspDesc[1].mDataByteSize, packetBufLen, pktNum);
    }
    
    if (NULL != packetBuf) {
        free(packetBuf);
        packetBuf = NULL;
    }
    if (NULL != byteBuf) {
        free(byteBuf);
        byteBuf = NULL;
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
