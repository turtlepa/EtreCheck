/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "Collector.h"

@interface LaunchdCollector : Collector
  {
  bool myShowExecutable;
  NSUInteger myPressureKilledCount;
  }

// These need to be shared by all launchd collector objects.
@property (retain) NSMutableDictionary * launchdStatus;
@property (retain) NSMutableSet * appleLaunchd;
@property (assign) bool showExecutable;
@property (assign) NSUInteger pressureKilledCount;

// Print a list of files.
- (void) printPropertyListFiles: (NSArray *) paths;

// Release memory.
+ (void) cleanup;

@end
