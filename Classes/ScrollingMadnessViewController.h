
#import <UIKit/UIKit.h>

typedef enum {
        ScrollViewModeNotInitialized,           // view has just been loaded
        ScrollViewModePaging,                   // fully zoomed out, swiping enabled
        ScrollViewModeZooming,                  // zoomed in, panning enabled
        ScrollViewModeAnimatingFullZoomOut,     // fully zoomed out, animations not yet finished
        ScrollViewModeInTransition,             // during the call to setPagingMode to ignore scrollViewDidScroll events
} ScrollViewMode;

@interface ScrollingMadnessViewController : UIViewController <UIScrollViewDelegate> {
	UIScrollView *scrollView;
	NSArray *pageViews;
	NSUInteger currentPage;
	ScrollViewMode scrollViewMode;
}

@end
