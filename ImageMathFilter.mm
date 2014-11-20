//
//  ImageMathFilter.m
//  ImageMath
//
//  Copyright (c) 2014 Tim. All rights reserved.
//

#import <Log4m/Log4m.h>

#import "ImageMathFilter.h"
#import "UserDefaults.h"
#import "Parameters.h"
#import "DialogController.h"

#include "ProjectDefs.h"
#include "LoggerUtils.h"

@implementation ImageMathFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
    dialogController = [[DialogController alloc] initWithViewers:self.viewerControllersList
                                                       andFilter:self];
    [dialogController loadWindow];

    return 0; // No Errors
}

@end
