/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012. All rights reserved.
 **********************************************************************/

#import "ByteCountFormatter.h"

@implementation ByteCountFormatter

- (NSString *) stringFromByteCount: (long long) byteCount
  {
  NSArray * unitValues =
    [NSLocalizedString(@"B KB MB GB TB", NULL)
      componentsSeparatedByString: @" "];
  int precisionValues[] = { 0, 0, 0, 2, 0};
  NSUInteger unitsIndex = 0;
  
  NSString * displayMem = @"?";
  
  double value = byteCount;
  
  while(YES)
    {
    if(value < 1024)
      {
      int precision = 0;
      NSString * units = @"";
      
      if(unitsIndex < 5)
        {
        precision = precisionValues[unitsIndex];
        units = [unitValues objectAtIndex: unitsIndex];
        }
        
      displayMem =
        [NSString stringWithFormat: @"%.*lf %@", precision, value, units];
        
      break;
      }
      
    ++unitsIndex;
    
    value /= 1024.0;
    }
    
  return displayMem;
  }

@end
