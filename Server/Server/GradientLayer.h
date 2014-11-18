//
//  GradientLayer.h
//  Schedules
//
//  Created by John Setting on 10/30/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface ColorGradientView : NSView
{
    NSColor *startingColor;
    NSColor *endingColor;
    int angle;
}

// Define the variables as properties
@property(nonatomic, retain) NSColor *startingColor;
@property(nonatomic, retain) NSColor *endingColor;
@property(assign) int angle;

@end
