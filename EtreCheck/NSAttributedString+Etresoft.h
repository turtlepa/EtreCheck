/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface NSAttributedString (Etresoft)

- (NSAttributedString *) attributedStringByTrimmingCharactersInSet:
  (NSCharacterSet *)set;

- (NSAttributedString *) attributedStringByTrimmingWhitespace;

@end
