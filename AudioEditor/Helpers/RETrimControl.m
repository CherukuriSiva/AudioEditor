//
// RETrimControl.m
// RETrimControl
//
// Copyright (c) 2013 Roman Efimov (https://github.com/romaonthego)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


#import "RETrimControl.h"

#define RANGESLIDER_THUMB_SIZE 22

@implementation RETrimControl

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame resourceBundle:@"RETrimControl.bundle"];
}

- (id)initWithFrame:(CGRect)frame resourceBundle:(NSString *)resourceBundle
{
    self = [super initWithFrame:frame];
    if (self) {
        self.threshold = 22;
        _resourceBundle = resourceBundle;
        
        _maxValue = 100;
        _minValue = 0;
        
        _leftValue = 0;
        _rightValue = 100;
        
        _outerView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _outerView.image = [UIImage imageNamed:@"audio-wave-png"];
        [self addSubview:_outerView];

        _leftThumbView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, RANGESLIDER_THUMB_SIZE, frame.size.height)];
        _leftThumbView.image = [UIImage imageNamed:@"transparentImage"];
        _leftThumbView.contentMode = UIViewContentModeLeft;
        _leftThumbView.userInteractionEnabled = YES;
        _leftThumbView.clipsToBounds = YES;
        _leftThumbView.alpha = 0.4;
        [self addSubview:_leftThumbView];
        
        UIPanGestureRecognizer *leftPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftPan:)];
        [_leftThumbView addGestureRecognizer:leftPan];
        
        _rightThumbView = [[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width - RANGESLIDER_THUMB_SIZE, 0, RANGESLIDER_THUMB_SIZE, frame.size.height)];
        _rightThumbView.image = [UIImage imageNamed:@"transparentImage"];
        _rightThumbView.contentMode = UIViewContentModeRight;
        _rightThumbView.userInteractionEnabled = YES;
        _rightThumbView.clipsToBounds = YES;
        _rightThumbView.alpha = 0.4;
        [self addSubview:_rightThumbView];
        
        _innerView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _innerView.image = [[UIImage imageNamed:@"transparentImage"] stretchableImageWithLeftCapWidth:5 topCapHeight:0];
        _innerView.alpha = 0.2;
        
        [self addSubview:_innerView];
        
        UIPanGestureRecognizer *rightPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightPan:)];
        [_rightThumbView addGestureRecognizer:rightPan];
        
        _leftPopover = [[RETrimPopover alloc] initWithFrame:CGRectMake(-9, -28, 40, 28) resourceBundle:resourceBundle];
        [self addSubview:_leftPopover];
        
        _rightPopover = [[RETrimPopover alloc] initWithFrame:CGRectMake(-9, -28, 40, 28) resourceBundle:resourceBundle];
        [self addSubview:_rightPopover];
        
        _popoverViewLong = [[UIView alloc] initWithFrame:CGRectMake(-9, -28, 90, 28)];
        _popoverViewLong.backgroundColor = [UIColor colorWithPatternImage:[self bundleImageNamed:@"PopoverLong"]];
        _timeLabelLong = [[UILabel alloc] initWithFrame:CGRectMake(0, 6, 90, 10)];
        _timeLabelLong.font = [UIFont boldSystemFontOfSize:10];
        _timeLabelLong.backgroundColor = [UIColor clearColor];
        _timeLabelLong.textColor = [UIColor whiteColor];
        _timeLabelLong.textAlignment = NSTextAlignmentCenter;
        [_popoverViewLong addSubview:_timeLabelLong];
        _popoverViewLong.alpha = 0;
        [self addSubview:_popoverViewLong];
    }
    return self;
}

- (void)layoutSubviews
{
    CGFloat availableWidth = self.frame.size.width - RANGESLIDER_THUMB_SIZE;
    CGFloat inset = RANGESLIDER_THUMB_SIZE / 2;

    CGFloat range = _maxValue - _minValue;

    CGFloat left = floorf((_leftValue - _minValue) / range * availableWidth);
    CGFloat right = floorf((_rightValue - _minValue) / range * availableWidth);

    if (isnan(left)) left = 0;
    if (isnan(right)) right = 0;

    _leftThumbView.center = CGPointMake(inset + left, 50);
    _rightThumbView.center = CGPointMake(inset + right, 50);

    CGRect frame = _innerView.frame;
    frame.origin.x = _leftThumbView.frame.origin.x + _threshold;
    frame.size.width = _rightThumbView.frame.origin.x + _rightThumbView.frame.size.width - _threshold - frame.origin.x;
    _innerView.frame = frame;

}

- (UIImage *)bundleImageNamed:(NSString *)imageName
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"%@/%@", self.resourceBundle, imageName]];
}

#pragma mark -
#pragma mark Styling

- (void)setFont:(UIFont *)font
{
    _font = font;
    _timeLabelLong.font = font;
    _rightPopover.timeLabel.font = font;
    _leftPopover.timeLabel.font = font;
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    _timeLabelLong.textColor = textColor;
    _rightPopover.timeLabel.textColor = textColor;
    _leftPopover.timeLabel.textColor = textColor;
}

- (void)setTextBackgroundColor:(UIColor *)textBackgroundColor
{
    _textBackgroundColor = textBackgroundColor;
    _timeLabelLong.backgroundColor = textBackgroundColor;
    _rightPopover.timeLabel.backgroundColor = textBackgroundColor;
    _leftPopover.timeLabel.backgroundColor = textBackgroundColor;
}

- (void)setTextVerticalOffset:(NSInteger)textVerticalOffset
{
    _textVerticalOffset = textVerticalOffset;
    _timeLabelLong.frame = CGRectMake(0, 6 + textVerticalOffset, 90, 10);
    _rightPopover.timeLabel.frame = CGRectMake(0, 6 + textVerticalOffset, 40, 10);
    _leftPopover.timeLabel.frame = CGRectMake(0, 6 + textVerticalOffset, 40, 10);
}

#pragma mark -
#pragma mark UIGestureRecognizer delegates

- (void)handleLeftPan:(UIPanGestureRecognizer *)gesture
{       
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:self];
        CGFloat range = _maxValue - _minValue;
        CGFloat availableWidth = self.frame.size.width - RANGESLIDER_THUMB_SIZE;
        _leftValue += translation.x / availableWidth * range;
        if (_leftValue < 0) _leftValue = 0;
        if (_rightValue - _leftValue < 10) _leftValue = _rightValue - 9;

        [gesture setTranslation:CGPointZero inView:self];

        [self setNeedsLayout];

        _leftPopover.alpha = 1;
        CGRect frame = _leftPopover.frame;
        frame.origin.x = _leftThumbView.frame.origin.x - 9;
        _leftPopover.frame = frame;

        _rightPopover.timeLabel.text = [self stringFromTime:_rightValue * _length / 100.0f];
        _leftPopover.timeLabel.text = [self stringFromTime:_leftValue * _length / 100.0f];


        [self notifyDelegate];
    }

    if (gesture.state == UIGestureRecognizerStateEnded)
        [self hidePopover:_leftPopover];
}

- (void)handleRightPan:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:self];
        CGFloat range = _maxValue - _minValue;
        CGFloat availableWidth = self.frame.size.width - RANGESLIDER_THUMB_SIZE;
        _rightValue += translation.x / availableWidth * range;

        if (_rightValue > 100) _rightValue = 100;
        if (_rightValue - _leftValue < 10) _rightValue = _leftValue + 9;

        [gesture setTranslation:CGPointZero inView:self];

        [self setNeedsLayout];

        _rightPopover.alpha = 1;
        CGRect frame = _rightPopover.frame;
        frame.origin.x = _rightThumbView.frame.origin.x - 9;
        _rightPopover.frame = frame;
        
        _rightPopover.timeLabel.text = [self stringFromTime:_rightValue * _length / 100.0f];
        _leftPopover.timeLabel.text = [self stringFromTime:_leftValue * _length / 100.0f];

        [self notifyDelegate];
    }

    if (gesture.state == UIGestureRecognizerStateEnded)
        [self hidePopover:_rightPopover];
}

#pragma mark -
#pragma mark Utilities

- (NSString *)stringFromTime:(NSInteger)time
{
    NSInteger minutes = floor(time / 60);
    NSInteger seconds = time - minutes * 60;
    NSString *minutesStr = [NSString stringWithFormat:minutes >= 10 ? @"%li" : @"0%li", (long)minutes];
    NSString *secondsStr = [NSString stringWithFormat:seconds >= 10 ? @"%li" : @"0%li", (long)seconds];
    return [NSString stringWithFormat:@"%@:%@", minutesStr, secondsStr];
}

- (void)hidePopover:(UIView *)popover
{    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                     animations:^(void) {

                         popover.alpha = 0;
                     }
                     completion:nil];
}

- (void)notifyDelegate
{
    if ([_delegate respondsToSelector:@selector(trimControl:didChangeLeftValue:rightValue:)])
        [_delegate trimControl:self didChangeLeftValue:_leftPopover.timeLabel.text rightValue:_rightPopover.timeLabel.text];
}

#pragma mark -
#pragma mark Properties

- (CGFloat)leftValue
{
    return _leftValue * _length / 100.0f;
}

- (CGFloat)rightValue
{
    return _rightValue * _length / 100.0f;
}

@end
