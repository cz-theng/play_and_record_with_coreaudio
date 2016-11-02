//
//  MusicBarView.m
//  AVAudioPlayerDemo
//
//  Created by apollo on 27/10/2016.
//  Copyright © 2016 projm. All rights reserved.
//

#import "MusicBarView.h"

@interface MusicBarView()
@property float unitWidth;
@property int count;
@property (strong, nonatomic) NSMutableArray *volumes;
@property (strong, nonatomic) NSMutableArray *volumeViews;
@end

@implementation MusicBarView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void) initIvars {
    _count = 7;
    [self layoutIfNeeded];
    _unitWidth = self.frame.size.width / (2*_count + 1);
    _volumes = [[NSMutableArray alloc] init];
    _volumeViews = [[NSMutableArray alloc] init];
    for (int i =0; i<_count; i++) {
        UIView *view = [[UIView alloc ] initWithFrame:CGRectMake((2*i+1)*_unitWidth, self.frame.size.height-self.frame.size.height/(i+1), _unitWidth, self.frame.size.height/(i+1))];
        [view setBackgroundColor: [UIColor blueColor]];
        [_volumeViews addObject: view];
        [self addSubview:view];
    }
}

-(instancetype ) init {
    self = [super init];
    if (nil != self) {
        [self initIvars];
    }
    return self;
}

-(instancetype ) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (nil != self) {
        [self initIvars];
    }
    return self;
}

-(instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (nil != self) {
        [self initIvars];
    }
    return  self;
}

-(void) addValue: (float) value {
    if (nil != _volumes && [_volumes count]<(_count) ) {
        [_volumes addObject:[NSNumber numberWithFloat:value]];
    } else {
        [_volumes addObject:[NSNumber numberWithFloat:value]];
        [_volumes removeObjectAtIndex:0];
    }
}

-(void) clear {
    for (UIView *v in _volumeViews) {
        v.alpha = 0;
    }
}

-(void) updateUI {
    
    for (int i=0; i<_count && i<[_volumes count]; i++) {
        UIView *view = [_volumeViews objectAtIndex:i];
        view.alpha = 1;
        float volume = [((NSNumber *)[_volumes objectAtIndex:i]) floatValue] * self.frame.size.height;
        [view setFrame:CGRectMake((2*i+1)*_unitWidth, self.frame.size.height-volume, _unitWidth, volume )];
    }
}

@end
