//
//  Parameters.h
//  ImageMath
//
//  Created by Tim Allman on 2014-11-18.
//
//

#import <Foundation/Foundation.h>

#include "ProjectDefs.h"

/**
 * The possible image - image operations. This must be kept in sync with the combobox values
 * in MainDialog.xib.
 */
enum ImageOperation
{
    ADD,           ///< Add series 1 to series 2.
    SUBTRACT,      ///< Subtract series 2 from series 1.
    MULTIPLY,      ///< Multiply series 1 by series 2.
    DIVIDE,        ///< Divide series 1 by series 2.
    LN_DIFFERENCE  ///< Calculate ln(series1 - series 2).
};

/**
 */
enum ComboboxTags
{
    SERIES1_DESC = 0,
    OPERATION = 1,
    SERIES2_DESC = 2
};

@class Logger;

@interface Parameters : NSObject
{
    Logger* logger_;

    // Plugin configuration parameters
    int loggerLevel;
    int operation;

    unsigned series1Index;
    unsigned series2Index;

    NSString* seriesDescription1;
    NSString* seriesDescription2;
    NSString* seriesDescriptionResult;
}

- (id)init;

@property (assign) int loggerLevel;
@property (assign) int operation;
@property (assign) unsigned series1Index;
@property (assign) unsigned series2Index;
@property (copy) NSString* seriesDescription1;
@property (copy) NSString* seriesDescription2;
@property (copy) NSString* seriesDescriptionResult;

@end
