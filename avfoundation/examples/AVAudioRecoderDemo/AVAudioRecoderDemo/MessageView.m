//
//  MessageView.m
//  AVAudioRecoderDemo
//
//  Created by apollo on 08/11/2016.
//  Copyright © 2016 projm. All rights reserved.
//

#import "MessageView.h"

@interface MessageView()
@property (strong, nonatomic) UILabel *durationLbl;
@end

@implementation MessageView

static int step = 20;

- (instancetype) init {
    if (self = [super init]) {

    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor yellowColor]];
        self.layer.cornerRadius = 5;
        
        _durationLbl = [[UILabel alloc] initWithFrame: self.bounds];
        _durationLbl.textAlignment = NSTextAlignmentRight;
        _durationLbl.textColor = [UIColor blueColor];
        [self addSubview:_durationLbl];
    }
    return self;
}

- (void) setDuration:(int)duration {
    [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, step * duration, self.frame.size.height)];
    [_durationLbl setFrame:CGRectMake(_durationLbl.frame.origin.x, _durationLbl.frame.origin.y, step*duration, _durationLbl.frame.size.height)];
    _durationLbl.text = [NSString stringWithFormat:@"%d''", duration];
}

@end
