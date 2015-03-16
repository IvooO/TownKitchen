//
//  DaySelectAnimationController.h
//  TownKitchen
//
//  Created by Peter Bai on 3/15/15.
//  Copyright (c) 2015 The Town Kitchen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DaySelectAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

@property (strong, nonatomic) UITableViewCell *selectedCell;
@property (assign, nonatomic) CGPoint contentOffset;

@end