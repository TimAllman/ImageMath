//
//  Parameters.m
//  ImageMath
//
//  Created by Tim Allman on 2014-11-18.
//
//

#import "Parameters.h"
#import "UserDefaults.h"


@implementation Parameters

@synthesize loggerLevel;
@synthesize operation;
@synthesize series1Index;
@synthesize series2Index;
@synthesize seriesDescription1;
@synthesize seriesDescription2;
@synthesize seriesDescriptionResult;

- (id)init
{
    self = [super init];
    if (self)
    {
        // Set the values based upon the user defaults
//        UserDefaults* def = [UserDefaults sharedInstance];
//        self.loggerLevel = [def integerForKey:LoggerLevelKey];
    }

    return self;
}

@end
