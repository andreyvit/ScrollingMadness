
#import <UIKit/UIKit.h>

typedef enum {
	ScrollViewModeNotInitialized,           // view has just been loaded
	ScrollViewModePaging,                   // fully zoomed out, swiping enabled
	ScrollViewModeZooming,                  // zoomed in, panning enabled
} ScrollViewMode;

@interface PagingAndZoomingViewController : UIViewController {
	UIScrollView *scrollView;
	NSArray *pageViews;
	NSUInteger currentPage;
	ScrollViewMode scrollViewMode;
	CGFloat pendingOffsetDelta;
}

@end
