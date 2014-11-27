/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "Collector.h"

@interface LaunchdCollector : Collector
  {
  BOOL myShowExecutable;
  }

// These need to be shared by all launchd collector objects.
@property (retain) NSMutableDictionary * launchdStatus;
@property (retain) NSMutableSet * appleLaunchd;
@property (assign) BOOL showExecutable;

// Print a list of files.
- (void) printPropertyListFiles: (NSArray *) paths;

// Release memory.
+ (void) cleanup;

@end
