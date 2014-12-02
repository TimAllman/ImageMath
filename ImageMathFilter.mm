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
    dialogController = [[DialogController alloc] initWithFilter:self];
    [dialogController showWindow:self];

    return 0; // No Errors
}

- (ViewerController*)copy4DViewer:(ViewerController*)viewer
{
    NSLog(@"copy4DViewer");

    // each pixel contains either a 32-bit float or a 32-bit ARGB value
    const int ELEMENT_SIZE = 4;

    ViewerController *new4DViewer = nil;
    float* volumePtr = nil;

    // First calculate the amount of memory needed for the new series
    NSArray* pixList0 = [viewer pixList:0];
    DCMPix* pix0 = [pixList0 objectAtIndex:0];
    size_t memSize = [pix0 pheight] * [pix0 pwidth] * [pixList0 count] * ELEMENT_SIZE ;

    // We will read our current series, and duplicate it by creating a new series!
    unsigned numImages = viewer.maxMovieIndex;
    for (unsigned timeIdx = 0; timeIdx < numImages; timeIdx++)
    {
        // First calculate the amount of memory needed for the new series
        NSArray* pixList = [viewer pixList:timeIdx];
        DCMPix* curPix = nil;

        if (memSize > 0)
        {
            // block of memory for new image series.
            volumePtr = (float*)malloc(memSize);

            // Copy the source series in the new one.
            memcpy(volumePtr, [viewer volumePtr:timeIdx], memSize);

            // Create a NSData object to control the new pointer.
            // Assumes that malloc has been used to allocate memory.
            NSData *volData = [[[NSData alloc]initWithBytesNoCopy:volumePtr
                                                           length:memSize
                                                     freeWhenDone:YES] autorelease];

            // Now copy the DCMPix with the new volumePtr
            NSMutableArray *newPixList = [NSMutableArray array];
            for (unsigned i = 0; i < [pixList count]; i++)
            {
                curPix = [[[pixList objectAtIndex:i] copy] autorelease];
                unsigned offset = [curPix pheight] * [curPix pwidth] * i;//ELEMENT_SIZE * i;
                float* fImage = volumePtr + offset;
                [curPix setfImage:fImage];
                [newPixList addObject: curPix];
            }

            // We don't need to duplicate the DicomFile array, because it is identical.

            // A 2D Viewer window needs 3 things:
            //     a mutable array composed of DCMPix objects
            //     a mutable array composed of DicomFile objects
            //         (The number of DCMPix and DicomFile objects has to be EQUAL.)
            //     volumeData containing the images, represented in the DCMPix objects
            NSMutableArray* fileList = [viewer fileList:timeIdx];
            if (new4DViewer == nil)
            {
                new4DViewer = [viewer newWindow:newPixList :fileList :volData];
                [new4DViewer roiDeleteAll:self];
            }
            else
            {
                [new4DViewer addMovieSerie:newPixList :fileList :volData];
            }
        }
    }
    
    return new4DViewer;
}

@end
