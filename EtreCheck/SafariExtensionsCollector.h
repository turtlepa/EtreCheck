/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect Safari extensions.
@interface SafariExtensionsCollector : Collector
  {
  NSDictionary * mySettings;
  NSMutableDictionary * myUpdates;
  }

// Results from defaults read ~/Library/Safari/Extensions/extensions.
@property (retain) NSDictionary * settings;

// Available updates.
@property (retain) NSMutableDictionary * updates;

@end
