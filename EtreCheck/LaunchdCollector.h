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

// Format a list of files.
- (void) formatPropertyListFiles: (NSArray *) paths
  title: (NSString *) title;

// Release memory.
+ (void) cleanup;

@end
