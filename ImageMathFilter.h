//
//  ImageMathFilter.h
//  ImageMath
//
//  Copyright (c) 2014 Tim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>

@class DialogController;

@interface ImageMathFilter : PluginFilter
{
    DialogController* dialogController;
}

- (long) filterImage:(NSString*) menuName;

/**
 * Duplicates a 4D viewer.
 * @returns The new 4D viewer instance
 */
- (ViewerController*)copy4DViewer:(ViewerController*)viewer;

@end
