//
//  NetworkRequestProgressCell.h
//  NetworkManager
//
//  Created by Robert Ryan on 6/9/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//
//  This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
//  http://creativecommons.org/licenses/by-sa/4.0/

#import <UIKit/UIKit.h>

@interface NetworkRequestProgressCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *networkRequestLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@end
