/*******************************************************************************\
** afsdemo:ReaderVC.m
** Created by CZ(cz.devnet@gmail.com) on 16/6/15
**
**  Copyright © 2016年 projm. All rights reserved.
\*******************************************************************************/


#import "ReaderVC.h"


#define VErr(err, msg)  do {\
                            if(nil != err) {\
                                NSLog(@"[ERR]:%@--%@", (msg), [err localizedDescription]);\
                                return ;\
                            }\
                        } while(0)

#define VStatus(err, msg) do {\
                            if(noErr != err) {\
                                NSLog(@"[ERR]:%@", (msg));\
                                return ;\
                            }\
                        } while(0)


@interface ReaderVC () {
    AudioFileID musicFD_;
}
@property (strong, nonatomic) MPMediaPickerController * mpPickerVC;
@property (strong, nonatomic) NSURL *musicURL;

@end

@implementation ReaderVC

- (void)viewDidLoad {
    [super viewDidLoad];

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

- (IBAction)onReadFileInfo:(id)sender {

    CFURLRef url = (__bridge CFURLRef) _musicURL;
    OSStatus stts = AudioFileOpenURL(url, kAudioFileReadPermission, 0, &musicFD_);
    VStatus(stts, @"AudioFileOpenURL");
    UInt32 audioFilePropertyFileFormatSize = 0;
    UInt32 audioFilePropertyFileFormatIsWritable = 0;
    stts = AudioFileGetPropertyInfo(musicFD_, kAudioFilePropertyFileFormat, &audioFilePropertyFileFormatSize, &audioFilePropertyFileFormatIsWritable);
    VStatus(stts, @"kAudioFilePropertyFileFormat");
    char *audioFilePropertyFileFormatBuf = (char *)malloc(audioFilePropertyFileFormatSize+1);
    if (NULL == audioFilePropertyFileFormatBuf) {
        NSLog(@"audioFilePropertyFileFormatBuf is NULL");
        return ;
    }
    memset(audioFilePropertyFileFormatBuf, 0, audioFilePropertyFileFormatSize+1);
    stts = AudioFileGetProperty(musicFD_, kAudioFilePropertyFileFormat, &audioFilePropertyFileFormatSize, audioFilePropertyFileFormatBuf);
    NSLog(@"Audio's format is %s", audioFilePropertyFileFormatBuf);
    if (NULL != audioFilePropertyFileFormatBuf) {
        free(audioFilePropertyFileFormatBuf);
        audioFilePropertyFileFormatBuf = NULL;
    }
    
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
    NSLog(@"Audio's max packet size  is %d", *(int *)audioFilePropertyMaximumPacketSizeBuf);

    int maxPktSize = *(int *)audioFilePropertyMaximumPacketSizeBuf;
    char *packetBuf = (char *) malloc( maxPktSize);
    char *byteBuf = (char *)malloc(maxPktSize);
    if (NULL == packetBuf || NULL == byteBuf) {
        NSLog(@"NULL == packetBuf || NULL == byteBuf");
        return ;
    }
    if (NULL != audioFilePropertyMaximumPacketSizeBuf) {
        free(audioFilePropertyMaximumPacketSizeBuf);
        audioFilePropertyMaximumPacketSizeBuf = NULL;
    }
    UInt32 packetBufLen = maxPktSize*2;
    UInt32 byteBufLen = maxPktSize;
    memset(packetBuf, packetBufLen, 0);
    memset(byteBuf, maxPktSize, 0);
    

    /*
    stts = AudioFileReadBytes(musicFD_, true, 0, &byteBufLen, byteBuf);
    VStatus(stts, @"AudioFileReadBytes"); 
     */
    AudioStreamPacketDescription aspDesc[2];
    UInt32 pktNum = 2;
    stts = AudioFileReadPacketData(musicFD_, NO, &packetBufLen, &aspDesc, 0, &pktNum, packetBuf);
    VStatus(stts, @"AudioFileReadPacketData");

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
