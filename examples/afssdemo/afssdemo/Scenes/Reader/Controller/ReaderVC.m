/*******************************************************************************\
** afssdemo:ReaderVC.m
** Created by CZ(cz.devnet@gmail.com) on 16/6/29
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
                                NSLog(@"[ERR-%d]:%@", err, (msg));\
                                return ;\
                            }\
                        } while(0)

void audioFileStream_PropertyListenerProc ( void *inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, UInt32 *ioFlags )
{
    NSLog(@"[%@]audioFileStream_PropertyListenerProc with flags %u", [NSThread currentThread], *ioFlags);
}

void audioFileStream_PacketsProc ( void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData, AudioStreamPacketDescription *inPacketDescriptions )
{
    NSLog(@"[%@]audioFileStream_PacketsProc with %u packets(%d bytes)", [NSThread currentThread], inNumberPackets, inNumberBytes);
}

@interface ReaderVC () {
    AudioFileStreamID streamID_;
}

@end




@implementation ReaderVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onOpen:(id)sender {
    AudioFileTypeID hint = kAudioFileAIFFType;
    OSStatus stts;
    stts = AudioFileStreamOpen((__bridge void * _Nullable)(self), audioFileStream_PropertyListenerProc, audioFileStream_PacketsProc , hint, &streamID_);
    VStatus(stts, @"AudioFileStreamOpen");
    NSLog(@"Open Stream success !");
}

- (IBAction)onPlay:(id)sender {
    NSFileHandle *audioFD;
    NSString *audioURL = [[NSBundle mainBundle] pathForResource:@"01" ofType:@"caf"];
    audioFD = [NSFileHandle fileHandleForReadingAtPath:audioURL];
    if (nil == audioFD) {
        NSLog(@"audio fd is null");
        return ;
    }
    NSLog(@"open audio fd success ");
    
    for (;;) {
        NSData *cntnt = [audioFD readDataOfLength:1024];
        if (NULL == cntnt || 0 == [cntnt length]) {
            NSLog(@"Read EOF!");
            break ;
        }
        NSLog(@"[%@]have read %lu", [NSThread currentThread], (unsigned long)[cntnt length]);
        OSStatus stts;
        stts = AudioFileStreamParseBytes(streamID_, (UInt32) [cntnt length], [cntnt bytes], 0);
        VStatus(stts, @"AudioFileStreamParseBytes");
    }
    NSLog(@"after read file");
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
