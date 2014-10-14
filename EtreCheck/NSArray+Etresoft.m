/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "NSArray+Etresoft.h"
#import "Utilities.h"

@implementation NSArray (Etresoft)

// Read from a property list file or data and make sure it is an array.
+ (NSArray *) readPropertyList: (NSString *) path
  {
  NSArray * array = [Utilities readPropertyList: path];
  
  if([array respondsToSelector: @selector(objectAtIndex:)])
    return array;
    
  return nil;
  }

+ (NSArray *) readPropertyListData: (NSData *) data
  {
  NSArray * array = [Utilities readPropertyListData: data];
  
  if([array respondsToSelector: @selector(objectAtIndex:)])
    return array;
    
  return nil;
  }

@end
