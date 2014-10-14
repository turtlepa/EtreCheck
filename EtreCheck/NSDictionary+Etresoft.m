/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "NSDictionary+Etresoft.h"
#import "Utilities.h"

@implementation NSDictionary (Etresoft)

// Read from a property list file or data and make sure it is a dictionary.
+ (NSDictionary *) readPropertyList: (NSString *) path
  {
  NSDictionary * dictionary = [Utilities readPropertyList: path];
  
  if([dictionary respondsToSelector: @selector(objectForKey:)])
    return dictionary;
    
  return nil;
  }

+ (NSDictionary *) readPropertyListData: (NSData *) data
  {
  NSDictionary * dictionary = [Utilities readPropertyListData: data];
  
  if([dictionary respondsToSelector: @selector(objectForKey:)])
    return dictionary;
    
  return nil;
  }

@end
