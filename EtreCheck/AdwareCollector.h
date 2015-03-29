/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect information about adware.
@interface AdwareCollector : Collector
  {
  NSDictionary * myAdwareSignatures;
  }

@property (retain) NSDictionary * adwareSignatures;
@property (readonly) NSMutableDictionary * adwareFiles;

@end
