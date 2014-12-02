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
@class ViewerController;

@interface DialogController : NSWindowController <NSWindowDelegate, NSComboBoxDataSource, NSComboBoxDelegate>
{
    Logger* logger;
    ImageMathFilter* parentFilter;
    NSArray* viewers;
    ViewerController* resultViewer;
    
    IBOutlet Parameters *params;
    IBOutlet NSComboBox *series1DescriptionCombobox;
    IBOutlet NSComboBox *operationCombobox;
    IBOutlet NSComboBox *series2DescriptionCombobox;
    IBOutlet NSTextField *resultSeriesDescriptionRextField;
}

@property (readonly) Parameters* params;

- (id)initWithFilter:(ImageMathFilter*)filter;
- (IBAction)calculateButtonPressed:(id)sender;
- (IBAction)closeButtonPressed:(id)sender;

@end
