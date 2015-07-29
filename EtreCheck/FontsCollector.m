/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "FontsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"

// Collect font information.
@implementation FontsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"fonts";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking fonts", NULL)];

  NSArray * badFonts = [self collectBadFonts];
  
  if([badFonts count])
    {
    [self.result appendAttributedString: [self buildTitle]];
    
    for(NSDictionary * font in badFonts)
      {
      NSString * name = [font objectForKey: @"_name"];
      NSString * path = [font objectForKey: @"path"];
      NSNumber * valid = [font objectForKey: @"valid"];

      if(![valid boolValue])
        {
        [self.result
          appendString:
            [NSString
              stringWithFormat:
                NSLocalizedString(
                  @"    %@: %@\n", NULL),
                name,
                [Utilities cleanPath: path]]];
        }
      }
      
    [self.result appendCR];
    }
    
  dispatch_semaphore_signal(self.complete);
  }

// Collect bad fonts.
- (NSArray *) collectBadFonts
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPFontsDataType"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/system_profiler" arguments: args];
  
  NSMutableArray * badFonts = [NSMutableArray array];
  
  if(result)
    {
    NSArray * plist = [NSArray readPropertyListData: result];
  
    if(plist && [plist count])
      {
      NSArray * fonts =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([fonts count])
        for(NSDictionary * font in fonts)
          {
          NSNumber * valid = [font objectForKey: @"valid"];
 
          if(![valid boolValue])
            [badFonts addObject: font];
          }
      }
    }

  return badFonts;
  }

@end
