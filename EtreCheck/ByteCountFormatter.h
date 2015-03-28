/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// NSByteCountFormatter only exists on 10.8 and later.
@interface ByteCountFormatter : NSObject

@property (assign) double k1000;

- (NSString *) stringFromByteCount: (unsigned long long) byteCount;

@end
