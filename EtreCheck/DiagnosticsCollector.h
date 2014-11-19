/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect diagnostics information.
@interface DiagnosticsCollector : Collector
  {
  BOOL insufficientPermissions;
  NSMutableDictionary * events;
  }

@end
