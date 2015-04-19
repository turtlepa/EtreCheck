/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect information about adware.
@interface AdwareCollector : Collector
  {
  NSMutableDictionary * myAdwareSignatures;
  NSMutableDictionary * myAdwareFound;
  }

@property (retain) NSMutableDictionary * adwareSignatures;
@property (retain) NSMutableDictionary * adwareFound;

@end
