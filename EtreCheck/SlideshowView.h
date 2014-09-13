/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

@class CIImage;
@class CATransition;

@interface SlideshowView : NSView
  {
  // An NSImageView that displays the current image, as a subview of the
  // SlideshowView
  NSImageView * currentImageView;
  NSView * myMaskView;
  }

// A view to use as a mask.
@property (retain) NSView * maskView;

// Show a new image.
- (void) transitionToImage: (NSImage *) newImage;

// Set the transition style.
- (void) updateSubviewsWithTransition: (NSString *) transition;

@end