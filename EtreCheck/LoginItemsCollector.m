/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "LoginItemsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"

// Collect login items.
@implementation LoginItemsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"loginitems";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking login items", NULL)];

  [self.result appendAttributedString: [self buildTitle]];
    
  NSArray * args =
    @[
      @"-e",
      @"tell application \"System Events\" to get the properties of every login item"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/bin/osascript" arguments: args];
  
  NSArray * loginItems = [self formatLoginItems: result];
  
  NSUInteger count = 0;
  
  for(NSDictionary * loginItem in loginItems)
    {
    [self printLoginItem: loginItem];
    
    ++count;
    }
    
  if(!count)
    [self.result appendString: NSLocalizedString(@"    None\n", NULL)];
  
  [self
    setTabs: @[@28, @112, @196]
    forRange: NSMakeRange(0, [self.result length])];

  [self.result appendCR];
    
  dispatch_semaphore_signal(self.complete);
  }

// Format the comma-delimited list of login items.
- (NSArray *) formatLoginItems: (NSData *) data
  {
  if(!data)
    return nil;
  
  NSString * string =
    [[NSString alloc]
      initWithBytes: [data bytes]
      length: [data length]
      encoding: NSUTF8StringEncoding];
  
  if(!string)
    return nil;
    
  NSMutableArray * loginItems = [NSMutableArray array];
  
  NSArray * parts = [string componentsSeparatedByString: @","];
  
  [string release];
  
  for(NSString * part in parts)
    {
    NSArray * keyValue = [self parseKeyValue: part];
    
    if(!keyValue)
      continue;
      
    NSString * key = [keyValue objectAtIndex: 0];
    NSString * value = [keyValue objectAtIndex: 1];
    
    if([key isEqualToString: @"name"])
      [loginItems addObject: [NSMutableDictionary dictionary]];
    else if([key isEqualToString: @"path"])
      value = [Utilities cleanPath: value];
    
    NSMutableDictionary * loginItem = [loginItems lastObject];
    
    [loginItem setObject: value forKey: key];
    }
    
  return loginItems;
  }

// Print a login item.
- (void) printLoginItem: (NSDictionary *) loginItem
  {
  NSString * name = [loginItem objectForKey: @"name"];
  NSString * path = [loginItem objectForKey: @"path"];
  NSString * kind = [loginItem objectForKey: @"kind"];
  NSString * hidden = [loginItem objectForKey: @"hidden"];
  
  if(![name length])
    name = @"-";
    
  if(![path length])
    path = NSLocalizedString(@"Unknown", NULL);
    
  if(![kind length])
    kind = NSLocalizedString(@"Unknown", NULL);

  bool isHidden = [hidden isEqualToString: @"true"];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"    %@    %@ %@ (%@)\n",
          name,
          kind,
          isHidden ? NSLocalizedString(@"Hidden", NULL) : @"",
          path]];
  }

// Parse a key/value from a login item result.
- (NSArray *) parseKeyValue: (NSString *) part
  {
  NSArray * keyValue = [part componentsSeparatedByString: @":"];
  
  if([keyValue count] < 2)
    return nil;
    
  NSString * key =
    [[keyValue objectAtIndex: 0]
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];

  NSString * value = 
    [[keyValue objectAtIndex: 1]
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
  return @[key, value];
  }

@end
