//
//  UserDefaults.m
//  Registration
//
//  Created by Tim Allman on 2012-09-26.
//
//

#import <Log4m/Log4m.h>

#import "UserDefaults.h"
#import "Parameters.h"

#include "ProjectDefs.h"

// General program defaults
NSString* const LoggerLevelKey = @"LoggerLevel";

static NSMutableDictionary *defaultsDict;
static NSString* bundleId;
static NSUserDefaults* defaults;
static UserDefaults* sharedInstance;

@implementation UserDefaults

+ (void)initialize
{
    // We'll use this as a singleton so we set up the shared instance here.
    static BOOL initialised = NO;
    if (!initialised)
    {
        initialised = YES;
        sharedInstance = [[UserDefaults alloc] init];
    }
    
    // Initialise the user defaults pointer.
    defaults = [[NSUserDefaults alloc] init];
    
    // We use the Bundle Identifier to store our defaults.
    bundleId = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
    
    // These are the initial "factory" settings. They will appear as the
    // defaults settings on the first running of the program
    NSDictionary* factoryDict = [self createFactoryDefaults];

    // We now get whatever may have been stored before.
    NSMutableDictionary* curDefaultsDict = [[defaults persistentDomainForName:bundleId] mutableCopy];

    // Remove any invalid keys/objects and reset the defaults
    [self removeObsoleteKeysFrom:curDefaultsDict using:factoryDict];
    [defaults setPersistentDomain:curDefaultsDict forName:bundleId];
   
    defaultsDict = [factoryDict mutableCopy];
    [defaultsDict addEntriesFromDictionary:curDefaultsDict];

    // Give back the memory
    [curDefaultsDict release];
    
    //LOG4M_TRACE(logger_, @".initialize: Set defaults %@ for domain %@", defaultsDict, bundleId);
}

+ (NSDictionary*)createFactoryDefaults
{
    NSDictionary* d =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithInt:LOG4M_LEVEL_DEBUG], LoggerLevelKey,
     nil];
    
    return d;
}

+ (UserDefaults*)sharedInstance
{
    return sharedInstance;
}

+ (void)removeObsoleteKeysFrom:(NSMutableDictionary*)currentDict using:(NSDictionary*)validDict
{
    // Create an array of all of the valid keys.
    NSArray* validKeys = [validDict allKeys];

    // Create array of current keys, some of which may be invalid
    NSArray* dictKeys = [currentDict allKeys];
    for (NSString* key in dictKeys)
    {
        if (![validKeys containsObject:key])
            [currentDict removeObjectForKey:key];
        [currentDict class];
    }
}

- (void) setupLogger
{
    NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                            stringByAppendingString:@".UserDefaults"];
    logger_ = [[Logger newInstance:loggerName] retain];
}


+ (NSMutableDictionary*)defaultsDictionary
{
    return defaultsDict;
}

- (void)saveParams:(Parameters*)data
{
    LOG4M_TRACE(logger_, @"Enter");

    // Set the values and keys that currently exist in the data.
    // This needs to be kept synchronized with the +initialize method
    [defaultsDict setObject:[NSNumber numberWithInt:data.loggerLevel]
                     forKey:LoggerLevelKey];

    // Set the current values for for next time
    [defaults setPersistentDomain: defaultsDict forName: bundleId];
}

- (void)saveDefaults:(NSMutableDictionary *)data
{
    LOG4M_TRACE(logger_, @"Enter");

    // Set the values and keys that currently exist in the data.
    // This needs to be kept synchronized with the +initialize method
    [defaultsDict addEntriesFromDictionary:data];

    // Set the current values for for next time
    [defaults setPersistentDomain: defaultsDict forName: bundleId];
}

- (void)dealloc
{
    LOG4M_TRACE(logger_, @"Enter");

    [logger_ release];
    [defaultsDict release];

    [super dealloc];
}

- (BOOL)keyExists:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);

	return ([defaultsDict valueForKey:key] != NULL);
}

-(BOOL)booleanForKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);
    
	NSNumber* value = [defaultsDict valueForKey:key];
    return [value boolValue];
}

-(void)setBoolean:(BOOL)value forKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"value = %d, key = %@", value, key);

	[defaultsDict setValue:[NSNumber numberWithBool:value] forKey:key];
}

-(NSInteger)integerForKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);

	NSNumber* value = [defaultsDict valueForKey:key];
    return [value intValue];
}

-(void)setInteger:(int)value forKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"value = %d, key = %@", value, key);

	[defaultsDict setValue:[NSNumber numberWithInt: value] forKey:key];
}

-(unsigned)unsignedIntegerForKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);

	NSNumber* value = [defaultsDict valueForKey:key];
    return [value unsignedIntValue];
}

-(void)setUnsignedInteger:(unsigned)value forKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"value = %d, key = %@", value, key);

	[defaultsDict setValue:[NSNumber numberWithUnsignedInteger: value] forKey:key];
}

-(float)floatForKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);

    NSNumber* value = [defaultsDict valueForKey:key];
    return [value floatValue];
}

-(void)setFloat:(float)value forKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"value = %f, key = %@", value, key);

	[defaultsDict setValue:[NSNumber numberWithFloat:value] forKey:key];
}

-(float)doubleForKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);

    NSNumber* value = [defaultsDict valueForKey:key];
    return [value floatValue];
}

-(void)setDouble:(float)value forKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"value = %f, key = %@", value, key);

	[defaultsDict setValue:[NSNumber numberWithDouble:value] forKey:key];
}

-(NSString*)stringForKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);
    
    return [defaultsDict valueForKey:key];
}

-(void)setString:(NSString*)string forKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"value = %@, key = %@", string, key);
    
	[defaultsDict setValue:[NSString stringWithString:string] forKey:key];
}

-(NSRect)rectForKey:(NSString *)key
{
    NSString* rectStr = [self stringForKey:key];
    return NSRectFromString(rectStr);
}

-(void)setRect:(NSRect)rect forKey:(NSString *)key
{
    NSString* rectStr = NSStringFromRect(rect);
    [self setString:rectStr forKey:key];
}

-(id)objectForKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);
    
    return [defaultsDict valueForKey:key];
}

-(void)setObject:(id)data forKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"value = %@, key = %@", data, key);
    
	[defaultsDict setValue:data forKey:key];
}

@end


