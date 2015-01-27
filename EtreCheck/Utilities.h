/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

#define kStatusUpdate @"statusupdate"
#define kProgressUpdate @"progressupdate"
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
  
  NSBundle * myEnglishBundle;
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

@property (readonly) NSBundle * EnglishBundle;

// Return the singeton of shared utilities.
+ (Utilities *) shared;

// Execute an external program and return the results.
+ (NSData *) execute: (NSString *) program arguments: (NSArray *) args;

// Execute an external program, return the results, and collect any errors.
+ (NSData *) execute: (NSString *) program
  arguments: (NSArray *) args error: (NSString **) error;

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

// Make a file name more presentable.
+ (NSString *) sanitizeFilename: (NSString *) file;

// Uncompress some data.
+ (NSData *) ungzip: (NSData *) gzipData;

// Build a URL.
+ (NSAttributedString *) buildURL: (NSString *) url
  title: (NSString *) title;

// Look for attributes from a file that might depend on the PATH.
+ (NSDictionary *) lookForFileAttributes: (NSString *) path;

// Compare versions.
+ (NSComparisonResult) compareVersion: (NSString *) version1
  withVersion: (NSString *) version2;

@end
