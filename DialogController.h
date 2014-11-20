//
//  DialogController.h
//  ImageMath
//
//  Created by Tim Allman on 2014-11-18.
//
//

#import <Cocoa/Cocoa.h>

@class ImageMathFilter;
@class Logger;
@class Parameters;

@interface DialogController : NSWindowController <NSWindowDelegate>
{
    Logger* logger;
    ImageMathFilter* parentFilter;
    NSArray* viewers;

    IBOutlet Parameters *params;
}

- (id)initWithViewers:(NSArray*)viewerArray andFilter:(ImageMathFilter*)filter;

@end
