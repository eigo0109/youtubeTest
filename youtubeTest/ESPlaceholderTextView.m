//
//  ESPlaceholderTextView.m
//  youtubeTest
//
//  Created by qiandong on 15/6/11.
//  Copyright (c) 2015年 qiandong. All rights reserved.
//

#import "ESPlaceholderTextView.h"

@interface ESPlaceholderTextView ()
{
    UILabel *_placeHolderLabel;
    NSString *_placeHolder;
}


@end

@implementation ESPlaceholderTextView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self buildPlaceHolderLabel];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self buildPlaceHolderLabel];
    }
    return self;
}

-(void)buildPlaceHolderLabel;
{
    _placeHolderLabel = [[UILabel alloc] init];
    _placeHolderLabel.frame =CGRectMake(7, 8, self.bounds.size.width, 20);
    _placeHolderLabel.text = _placeHolder;
    _placeHolderLabel.enabled = NO;//lable必须设置为不可用
    _placeHolderLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:_placeHolderLabel];
    
    self.delegate = self;

}

-(void)setPlaceHolder:(NSString *)placeHolder
{
    _placeHolder = placeHolder;
    _placeHolderLabel.text = _placeHolder;
}

-(void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length == 0) {
        _placeHolderLabel.text = _placeHolder;
    }else{
        _placeHolderLabel.text = @"";
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    _placeHolderLabel.text = @"";
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView.text.length == 0) {
        _placeHolderLabel.text = _placeHolder;
    }
}

@end
