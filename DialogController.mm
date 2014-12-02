//
//  DialogController.m
//  ImageMath
//
//  Created by Tim Allman on 2014-11-18.
//
//

#include "ProjectDefs.h"
#include "LoggerUtils.h"

#import "DialogController.h"
#import "ViewerController+ExportTimeSeries.h"
#import "Parameters.h"
#import "UserDefaults.h"
#import "ImageMathFilter.h"

#import <OsiriXAPI/Notifications.h>
#import <OsiriXAPI/DCMPix.h>
#import <OsiriXAPI/DicomSeries.h>

#import <Osirix/DCMObject.h>
#import <OsiriX/DCMAttribute.h>
#import <OsiriX/DCMAttributeTag.h>

#import <Log4m/Log4m.h>

/**
 * Strings to fill combobox. Must be coordinated with enum Operation in ProjectDefs.h.
 */
static NSString* operationNames[] =
{
    @"Add", @"Subtract", @"Multiply", @"Divide", @"ln(Difference)"
};
static int NUM_OPERATIONS = 5;

@interface DialogController ()

@end

@implementation DialogController

@synthesize params;

- (id)initWithFilter:(ImageMathFilter *)filter
{
    self = [super initWithWindowNibName:@"MainDialog"];
    if (self)
    {
        parentFilter = filter;
        viewers = [[NSArray arrayWithArray:parentFilter.viewerControllersList] retain];
    }
    return self;
}

- (void)dealloc
{
    [viewers release];

    [super dealloc];
}

- (void)awakeFromNib
{
    NSLog(@"awakeFromNib");

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
    [self setupControls];
}

- (void)windowDidLoad
{
    NSLog(@"windowDidLoad");
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

- (void)setupControls
{
    [series1DescriptionCombobox selectItemAtIndex:0];
    [series1DescriptionCombobox setObjectValue:[self comboBox:series1DescriptionCombobox
                                    objectValueForItemAtIndex:0]];
    [series1DescriptionCombobox reloadData];

    [operationCombobox selectItemAtIndex:0];
    [operationCombobox setObjectValue:[self comboBox:operationCombobox
                                    objectValueForItemAtIndex:0]];
    [operationCombobox reloadData];
    
    [series2DescriptionCombobox selectItemAtIndex:0];
    [series2DescriptionCombobox setObjectValue:[self comboBox:series2DescriptionCombobox
                                    objectValueForItemAtIndex:0]];
    [series2DescriptionCombobox reloadData];
}

- (DicomSeries*)dicomSeriesForViewer:(ViewerController*)viewer
{
    DCMPix *firstPix = [[viewer pixList] objectAtIndex:0];

    return (DicomSeries*)[firstPix seriesObj];
}

- (DCMObject*)dicomObjectForViewer:(ViewerController*)viewer atIndex:(unsigned)idx
{
    DCMPix *pix = [[viewer pixList] objectAtIndex:idx];

    // file containing the slice
    NSString* filePath = [pix sourceFile];

    return [DCMObject objectWithContentsOfFile:filePath decodingPixelData:NO];
}

- (NSString*)seriesDescriptionForViewer:(ViewerController*)viewer
{
    // Get the current series desc. so that we can append to it.
    // Note. This is stored as the property seriesName in OsiriX's DicomSeries.
    NSString* dicomTag = @"SeriesDescription";

    DCMAttributeTag* tag = [DCMAttributeTag tagWithName:dicomTag];
    if (!tag)
        tag = [DCMAttributeTag tagWithTagString:dicomTag];

    NSString* retVal = nil;
    DCMObject* dcmObject = [self dicomObjectForViewer:viewer atIndex:0];
    if (tag && tag.group && tag.element)
    {
        DCMAttribute* attr = [dcmObject attributeForTag:tag];
        retVal = [[attr value] description];
    }

    if ((retVal == nil) || (retVal.length == 0))
        retVal = @"No series description";

    LOG4M_INFO(logger, @"seriesDescription = %@", retVal);

    return [retVal copy];
}

#pragma mark -
#pragma mark Notification handlers

// Our viewer is about to close.
- (void)viewerWillClose:(NSNotification*)notification
{
    LOG4M_DEBUG(logger, @"viewerWillClose: %@", [notification name]);

    [viewers release];
    viewers = [[NSArray arrayWithArray:parentFilter.viewerControllersList] retain];
    [series1DescriptionCombobox reloadData];
    [series2DescriptionCombobox reloadData];
}

// Our viewer is about to change
- (void)viewerWillChange:(NSNotification*)notification
{
    LOG4M_DEBUG(logger, @"viewerWillChange: %@", [notification name]);

    [viewers release];
    viewers = [[NSArray arrayWithArray:parentFilter.viewerControllersList] retain];
    [series1DescriptionCombobox reloadData];
    [series2DescriptionCombobox reloadData];
}

// There is a new viewer to attach to.
- (void)viewerDidChange:(NSNotification*)notification
{
    LOG4M_DEBUG(logger, @"viewerDidChange: %@", [notification name]);

    [viewers release];
    viewers = [[NSArray arrayWithArray:parentFilter.viewerControllersList] retain];
    [series1DescriptionCombobox reloadData];
    [series2DescriptionCombobox reloadData];
}

#pragma mark -
#pragma mark Processing

- (void)showNonconformanceAlert:(NSString*)informMsg
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
    // Osirix will not allow plugins to run unless there is at least one
    // viewer open. We need check only that there are at least two open.
    if (viewers.count == 1)
    {
        NSString* informText = @"Only one image is open. There must be at "
                               @"least two images open to proceed.";

        [self showNonconformanceAlert:informText];
        LOG4M_DEBUG(logger, informText);
        return TOO_FEW;
    }

    // We go through the two series and check for conformance
    ViewerController* v0 = [viewers objectAtIndex:0];
    ViewerController* v1 = [viewers objectAtIndex:1];

    unsigned numTimeImages = (unsigned)[v0 maxMovieIndex];
    if (numTimeImages != [v1 maxMovieIndex])
    {
        NSString* informText = [NSString stringWithFormat:
                                @"Number of dynamics do not match: %d, %d",
                                (int)[v0 maxMovieIndex], (int)[v1 maxMovieIndex]];
        [self showNonconformanceAlert:informText];
        LOG4M_DEBUG(logger, informText);
        return NONCONFORMANT;
    }

    unsigned slicesPerImage = [[v0 pixList] count];
    if (slicesPerImage != [[v1 pixList] count])
    {
        NSString* informText = [NSString stringWithFormat:
                                @"Number of slices per image do not match: %d, %d",
                                (int)[[v0 pixList] count], (int)[[v1 pixList] count]];
        [self showNonconformanceAlert:informText];
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
        [self showNonconformanceAlert:informText];
        LOG4M_DEBUG(logger, informText);
        return NONCONFORMANT;
    }

    return CONFORMANT;
}

/**
 * Perform element by element addition such that result = block1 + block2.
 * @param size The number of elements in each array. They are all of the same size.
 * @param block1 Pointer to block 1.
 * @param block2 Pointer to block 2.
 * @param result Pointer to the preallocated result block.
 */
- (void)addArrays:(unsigned)size array1:(float*)block1 array2:(float*)block2
           result:(float*)result
{
    for (NSUInteger idx = 0; idx < size; ++idx)
        result[idx] = block1[idx] + block2[idx];
}

/**
 * Perform element by element subtraction such that result = block1 - block2.
 * @param size The number of elements in each array. They are all of the same size.
 * @param block1 Pointer to block 1.
 * @param block2 Pointer to block 2.
 * @param result Pointer to the preallocated result block.
 */
- (void)subtractArrays:(unsigned)size array1:(float*)block1 array2:(float*)block2
                result:(float*)result
{
    for (NSUInteger idx = 0; idx < size; ++idx)
        result[idx] = block1[idx] - block2[idx];
}

/**
 * Perform element by element multiplication such that result = block1 * block2.
 * @param size The number of elements in each array. They are all of the same size.
 * @param block1 Pointer to block 1.
 * @param block2 Pointer to block 2.
 * @param result Pointer to the preallocated result block.
 */
- (void)multiplyArrays:(unsigned)size array1:(float*)block1 array2:(float*)block2
                result:(float*)result
{
    for (NSUInteger idx = 0; idx < size; ++idx)
        result[idx] = block1[idx] * block2[idx];
}

/**
 * Perform element by element division such that result = block1 / block2.

 * @param size The number of elements in each array. They are all of the same size.
 * @param block1 Pointer to block 1.
 * @param block2 Pointer to block 2.
 * @param result Pointer to the preallocated result block.
 */
- (void)divideArrays:(unsigned)size array1:(float*)block1 array2:(float*)block2
              result:(float*)result
{
    for (NSUInteger idx = 0; idx < size; ++idx)
    {
        result[idx] = block1[idx] / block2[idx];
        //        float res = block1[idx] / block2[idx];
        //        if (isnan(res))
        //            result[idx] = MAXFLOAT;
        //        else
        //            result[idx] = res;
    }
}

/**
 * Perform element by element calculation of ln(x) im place.
 * @param size The number of elements in the array.
 * @param block1 Pointer to array.
 */
- (void)lnArray:(unsigned)size array:(float*)block
{
    for (NSUInteger idx = 0; idx < size; ++idx)
    {
        block[idx] = logf(block[idx]);
        //        float res = logf(block[idx]);
        //        if (isinf(res))
        //            block[idx] = -MAXFLOAT;
        //        else
        //            block[idx] = res;
    }
}

- (void)processSeries:(int)op
{
    LOG4M_TRACE(logger, @"Enter");

    ViewerController* vc1 = [viewers objectAtIndex:params.series1Index];
    ViewerController* vc2 = [viewers objectAtIndex:params.series2Index];
    unsigned numTimeImages = (unsigned)[vc1 maxMovieIndex];
    unsigned slicesPerImage = [[vc1 pixList] count];
    NSArray* pixList = [vc1 pixList:0];
    DCMPix* pix = [pixList objectAtIndex:0];
    unsigned numPixels = [pix pheight] * [pix pwidth];

    for (unsigned timeIdx = 0; timeIdx < numTimeImages; ++timeIdx)
    {
        NSArray* pixList1 = [vc1 pixList:timeIdx];
        NSArray* pixList2 = [vc2 pixList:timeIdx];
        NSArray* pixList3 = [resultViewer pixList:timeIdx];

        for (unsigned sliceIdx = 0; sliceIdx < slicesPerImage; ++sliceIdx)
        {
            DCMPix* pix1 = [pixList1 objectAtIndex:sliceIdx];
            DCMPix* pix2 = [pixList2 objectAtIndex:sliceIdx];
            DCMPix* pix3 = [pixList3 objectAtIndex:sliceIdx];

            float* block1 = [pix1 fImage];
            float* block2 = [pix2 fImage];
            float* block3 = [pix3 fImage];

//            for (unsigned idx = 0; idx < numPixels; ++idx)
//                block3[idx] = sliceIdx + 0.2;

            switch (op)
            {
                case ADD:
                    [self addArrays:numPixels array1:block1 array2:block2 result:block3];
                    break;
                case SUBTRACT:
                    [self subtractArrays:numPixels array1:block1 array2:block2 result:block3];
                    break;
                case MULTIPLY:
                    [self multiplyArrays:numPixels array1:block1 array2:block2 result:block3];
                    break;
                case DIVIDE:
                    [self divideArrays:numPixels array1:block1 array2:block2 result:block3];
                    break;
                case LN_DIFFERENCE:
                    [self subtractArrays:numPixels array1:block1 array2:block2 result:block3];
                    [self lnArray:numPixels array:block3];
                    break;
                default:
                    break;
            }
        }
    }

}

#pragma mark -
#pragma mark Actions

- (IBAction)calculateButtonPressed:(id)sender
{
    if (params.seriesDescriptionResult == nil)
    {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];

        [alert addButtonWithTitle:@"Close"];
        [alert setMessageText:@"ImageMath plugin."];
        [alert setInformativeText:@"You have not entered a Series Description for the Result."];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:self
                         didEndSelector:nil
                            contextInfo:nil];

        return;
    }

    // Make sure that the series conform for the operation.
    enum SeriesStatus status = [self checkSeriesConformance];

    // checkSeriesConformance has already warned the user so we just check the return value.
    if (status == CONFORMANT)
    {
        // We need to make a new viewer
        resultViewer = [parentFilter copy4DViewer:[viewers objectAtIndex:params.series1Index]];

        [self processSeries:params.operation];

        [resultViewer exportAllImages4D:params.seriesDescriptionResult];
        [resultViewer setWindowTitle:self];
        [resultViewer needsDisplayUpdate];
    }
}

- (IBAction)closeButtonPressed:(id)sender
{
    [self.window performClose:self];
}

#pragma mark -
#pragma mark ComboBoxes
// NSComboboxDelegate methods
- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    LOG4M_TRACE(logger, @"Enter: %@", [notification name]);
    NSComboBox* cb = (NSComboBox*)[notification object];
    long tag = [cb tag];

    NSInteger idx = [cb indexOfSelectedItem];
    id value = [self comboBox:cb objectValueForItemAtIndex:idx];

    LOG4M_DEBUG(logger, @"comboBoxSelectionDidChange tag = %ld, idx = %ld, value = %@", tag, idx, value);

    // Use the tag of the combo box to select the parameter to set
    // These tags are hard wired in the XIB file.
    switch (tag)
    {
        case SERIES1_DESC:
            params.series1Index = idx;
            break;

        case OPERATION:
            params.operation = idx;
            break;
            
        case SERIES2_DESC:
            params.series1Index = idx;
            break;

        default:
            LOG4M_FATAL(logger, @"Invalid tag %ld.", (long)tag);
            [NSException raise:NSInternalInconsistencyException
                        format:@"Invalid tag %ld in comboBoxSelectionDidChange:notification", (long)tag];
    }
}

// NSComboboxDatasource methods
// This fills the combo box.
- (id)comboBox:(NSComboBox *)comboBox objectValueForItemAtIndex:(NSInteger)index
{
    LOG4M_TRACE(logger, @"%ld", (long)index);
    long tag = [comboBox tag];

    LOG4M_DEBUG(logger, @"comboBox:objectValueForItemAtIndex tag = %ld, index = %ld", tag, index);

    id retVal = nil;
    ViewerController* viewer = nil;

    switch (tag)
    {
        case SERIES1_DESC:
            viewer = [viewers objectAtIndex:index];
            retVal = [self seriesDescriptionForViewer:viewer];
            break;

        case OPERATION:
            retVal = operationNames[NUM_OPERATIONS];
            break;

        case SERIES2_DESC:
            viewer = [viewers objectAtIndex:index];
            retVal = [self seriesDescriptionForViewer:viewer];
            break;

        default:
            LOG4M_FATAL(logger, @"Invalid tag %ld.", (long)tag);
            [NSException raise:NSInternalInconsistencyException
                        format:@"Invalid tag %ld in comboBox:objectValueForItemAtIndex:", (long)tag];
            return nil;
    }

    LOG4M_DEBUG(logger, @"returning %@", retVal);

    return retVal;
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)comboBox
{
    //LOG4M_TRACE(logger_, @"Enter");
    long tag = [comboBox tag];

    LOG4M_DEBUG(logger, @"numberOfItemsInComboBox tag = %ld", tag);

    NSInteger retVal;

    switch (tag)
    {
        case SERIES1_DESC:  // fixed image number
            retVal = (NSInteger)viewers.count;
            break;

        case OPERATION:
            retVal = (NSInteger)NUM_OPERATIONS;
            break;

        case SERIES2_DESC:
            retVal = (NSInteger)viewers.count;
            break;

        default:
            LOG4M_FATAL(logger, @"Invalid tag %ld.", (long)tag);
            [NSException raise:NSInternalInconsistencyException
                        format:@"Invalid tag %ld in numberOfItemsInComboBox:", (long)tag];
            return (NSInteger)-1;
    }
    
    LOG4M_DEBUG(logger, @"returning %ld", retVal);
    
    return retVal;
}

@end
