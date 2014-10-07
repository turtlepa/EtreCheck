/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect Safari extensions.
@interface SafariExtensionsCollector : Collector
  {
  NSMutableDictionary * myExtensions;
  NSMutableDictionary * myUpdates;
  }

// Key is extension name.
@property (retain) NSMutableDictionary * extensions;

// Available updates.
@property (retain) NSMutableDictionary * updates;

@end
