//
//  DialogController.m
//  ImageMath
//
//  Created by Tim Allman on 2014-11-18.
//
//

#import "DialogController.h"
#import "Parameters.h"
#import "UserDefaults.h"

#include "ProjectDefs.h"
#include "LoggerUtils.h"

#import <OsiriXAPI/Notifications.h>
#import <OsirixAPI/ViewerController.h>
#import <OsiriXAPI/DCMPix.h>

#import <Log4m/Log4m.h>

@interface DialogController ()

@end

@implementation DialogController

- (id)initWithViewers:(NSArray *)viewerArray andFilter:(ImageMathFilter *)filter
{
    self = [super initWithWindowNibName:@"MainDialog"];
    if (self)
    {
        viewers = viewerArray;
        parentFilter = filter;
    }
    return self;
}

- (void)awakeFromNib
{
    //Make sure to catch the viewer closing and changing events.
    [[NSNotificationCenter defaultCenter]  addObserver:self
                                              selector:@selector(viewerWillClose:)
                                                  name:OsirixCloseViewerNotification
                                                object:nil];

    [[NSNotificationCenter defaultCenter]  addObserver:self
                                              selector:@selector(viewerWillChange:)
                                                  name:OsirixViewerWillChangeNotification
                                                object:nil];

    [[NSNotificationCenter defaultCenter]  addObserver:self
                                              selector:@selector(viewerDidChange:)
                                                  name:OsirixViewerDidChangeNotification
                                                object:nil];

    // Set up logging ASAP
    [self setupSystemLogger];
    [self setupLogger];
}

- (void) setupLogger
{
    NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                            stringByAppendingString:@".DialogController"];
    logger = [[Logger newInstance:loggerName] retain];
}

/**
 Sets up the Log4m logger.
 */
- (void)setupSystemLogger
{
    UserDefaults* defaults = [UserDefaults sharedInstance];

    params.loggerLevel = [defaults integerForKey:LoggerLevelKey];
    SetupLogger(LOGGER_NAME, params.loggerLevel);
}

#pragma mark -
#pragma mark Notification handlers

// Our viewer is about to close.
- (void)viewerWillClose:(NSNotification*)notification
{
    LOG4M_DEBUG(logger, @"viewerWillClose: %@", [notification name]);

    //    [panelController close];
    //    [panelController release];
    //    panelController = nil;
}

// Our viewer is about to change
- (void)viewerWillChange:(NSNotification*)notification
{
    LOG4M_DEBUG(logger, @"viewerWillChange: %@", [notification name]);

    //    [panelController close];
    //    [panelController release];
    //    panelController = nil;
}

// There is a new viewer to attach to.
- (void)viewerDidChange:(NSNotification*)notification
{
    LOG4M_DEBUG(logger, @"viewerDidChange: %@", [notification name]);

    //    panelController = [[PanelController alloc]
    //                       initWithViewerController: viewerController andFilter:self];
    //    [panelController showWindow:self];
}

- (void)showConformanceAlert:(NSString*)informMsg
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];

    [alert addButtonWithTitle:@"Close"];
    [alert setMessageText:@"ImageMath plugin."];
    [alert setInformativeText:informMsg];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:self.window
                      modalDelegate:self
                     didEndSelector:nil
                        contextInfo:nil];
}

- (SeriesStatus)checkSeriesConformance
{
    if (viewers.count != 2)
    {
        NSString* informText = nil;
        if (viewers.count == 1)
            informText = [NSString stringWithFormat:@"Curently %d image is open. There must be two images open to proceed.", 1];
        else
            informText = [NSString stringWithFormat:@"Curently %d images are open. There must be two images open to proceed.", (int)viewers.count];

        [self showConformanceAlert:informText];
        LOG4M_DEBUG(logger, informText);
        return viewers.count < 2 ? TOO_FEW : TOO_MANY;
    }

    // We go through the two series and check for conformance
    ViewerController* v0 = [viewers objectAtIndex:0];
    ViewerController* v1 = [viewers objectAtIndex:1];

    unsigned numTimeImages = (unsigned)[v0 maxMovieIndex];
    if (numTimeImages != [v1 maxMovieIndex])
    {
        NSString* informText = [NSString stringWithFormat:@"Number of dynamics do not match: %d, %d",
                                (int)[v0 maxMovieIndex], (int)[v1 maxMovieIndex]];
        [self showConformanceAlert:informText];
        LOG4M_DEBUG(logger, informText);
        return NONCONFORMANT;
    }

    unsigned slicesPerImage = [[v0 pixList] count];
    if (slicesPerImage != [[v1 pixList] count])
    {
        NSString* informText = [NSString stringWithFormat:@"Number of slices per image do not match: %d, %d",
                                (int)[[v0 pixList] count], (int)[[v1 pixList] count]];
        [self showConformanceAlert:informText];
        LOG4M_DEBUG(logger, informText);
        return NONCONFORMANT;
    }

    NSArray* firstImage0 = [v0 pixList:0];
    NSArray* firstImage1 = [v1 pixList:0];
    DCMPix* firstPix0 = [firstImage0 objectAtIndex:0];
    DCMPix* firstPix1 = [firstImage1 objectAtIndex:0];
    unsigned sliceHeight = firstPix0.pheight;
    unsigned sliceWidth = firstPix0.pwidth;
    if ((sliceHeight != firstPix1.pheight) || (sliceWidth != firstPix1.pwidth))
    {
        NSString* informText = [NSString stringWithFormat:@"Image dimensions do not match."];
        [self showConformanceAlert:informText];
        LOG4M_DEBUG(logger, informText);
        return NONCONFORMANT;
    }

    return CONFORMANT;
}



@end
