//
//  Parameters.h
//  ImageMath
//
//  Created by Tim Allman on 2014-11-18.
//
//

#import <Foundation/Foundation.h>

@class Logger;

@interface Parameters : NSObject
{
    Logger* logger_;

    // Plugin configuration parameters
    int loggerLevel;
}

@property (assign) int loggerLevel;

@end
