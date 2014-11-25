/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

typedef enum EventType
  {
  kUnknown,
  kCrash,
  kCPU,
  kHang,
  kSelfTestPass,
  kSelfTestFail,
  kPanic,
  kLog
  }
EventType;

@interface DiagnosticEvent : NSObject
  {
  EventType myType;
  NSString * myName;
  NSDate * myDate;
  NSString * myFile;
  NSString * myDetails;
  }

@property (assign) EventType type;
@property (strong) NSString * name;
@property (strong) NSDate * date;
@property (strong) NSString * file;
@property (strong) NSString * details;

@end
