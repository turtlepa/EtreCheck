/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

#define kStatusUpdate @"statusupdate"
#define kProgressUpdate @"progressupdate"
#define kMinorProgressUpdate @"minorprogressupdate"
#define kFoundApplication @"foundapplication"
#define kShowMachineIcon @"showmachineicon"
#define kCollectionStatus @"collectionstatus"
#define kShowDemonAgent @"showdemonagent"

// Assorted utilities.
@interface Utilities : NSObject
  {
  NSFont * myBoldFont;
  NSFont * myBoldItalicFont;
  
  NSColor * myGreen;
  NSColor * myBlue;
  NSColor * myRed;
  NSColor * myGray;
  
  NSImage * myUnknownMachineIcon;
  NSImage * myMachineNotFoundIcon;
  NSImage * myGenericApplicationIcon;
  NSImage * myEtreCheckIcon;
  NSImage * myFinderIcon;
  }

// Make some handy shared values available to all collectors.
@property (readonly) NSFont * boldFont;
@property (readonly) NSFont * boldItalicFont;

@property (readonly) NSColor * green;
@property (readonly) NSColor * blue;
@property (readonly) NSColor * red;
@property (readonly) NSColor * gray;

@property (readonly) NSImage * unknownMachineIcon;
@property (readonly) NSImage * machineNotFoundIcon;
@property (readonly) NSImage * genericApplicationIcon;
@property (readonly) NSImage * EtreCheckIcon;
@property (readonly) NSImage * FinderIcon;

// Return the singeton of shared utilities.
+ (Utilities *) shared;

// Execute an external program and return the results.
+ (NSData *) execute: (NSString *) program arguments: (NSArray *) args;

// Format text into an array of trimmed lines separated by newlines.
+ (NSArray *) formatLines: (NSData *) data;

// Read a property list to an array.
+ (id) readPropertyList: (NSString *) path;
+ (id) readPropertyListData: (NSData *) data;

// Redact any user names in a path.
+ (NSString *) cleanPath: (NSString *) path;

// Format an exectuable array for printing, redacting any user names in
// the path.
+ (NSString *) formatExecutable: (NSArray *) parts;

@end
