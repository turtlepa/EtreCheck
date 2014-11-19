/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface DiagnosticEvent : NSObject
  {
  NSUInteger myCrashCount;
  NSUInteger myCPUCount;
  NSUInteger myPassingCount;
  NSUInteger myFailureCount;
  NSString * myTestResult;
  NSString * myDate;
  NSString * myName;
  }

@property (assign) NSUInteger crashCount;
@property (assign) NSUInteger cpuCount;
@property (assign) NSUInteger passingCount;
@property (assign) NSUInteger failureCount;
@property (strong) NSString * testResult;
@property (strong) NSString * date;
@property (strong) NSString * name;

@end
