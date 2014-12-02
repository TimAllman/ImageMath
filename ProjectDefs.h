//
//  ProjectDefs.h
//  ImageMath
//
//  Created by Tim Allman on 2013-04-26.
//
//

#ifndef ProjectDefs_h
#define ProjectDefs_h

/*
 * This file contains only C compatible definitions, #defines etc that are
 * used throughout the program. This ensures that they are usable by any
 * module be it C, C++, Obj-C or Obj-C++.
 */

/**
 * Values to use to return the results of functions which may fail.
 */
enum ResultCode
{
    SUCCESS = 0,   ///< All went well.
    FAILURE = 1,   ///< Registration was suboptimal but we can continue.
    DISASTER = 2   ///< Complete failure like an exception's being thrown by ITK or some similar event
};

/**
 * Describe the status of the loaded series with respect to element by element arithmetic.
 */
enum SeriesStatus
{
    CONFORMANT,    ///< Suitable for calculation.
    TOO_FEW,       ///< Not enough image series for calculation.
    NONCONFORMANT  ///< Not suitable for some other reason.
};

///**
// * Used to select image operations. Must be coordinated with static NSArray* operations
// * in DialogController.mm
// */
//enum Operation
//{
//    ADD,
//    SUBTRACT,
//    MULTIPLY,
//    DIVIDE,
//    LN_DIFF
//};

// The name of the logger used through this plugin.
#define LOGGER_NAME "ca.brasscats.osirix.ImageMath"

// The name of the rolling file log that we place in ~/Library/Logs
#define LOG_FILE_NAME LOGGER_NAME;

#endif
