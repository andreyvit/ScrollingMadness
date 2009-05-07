
#import <UIKit/UIKit.h>
#import "ZoomScrollView.h"

typedef enum {
        ScrollViewModeNotInitialized,           // view has just been loaded
        ScrollViewModePaging,                   // fully zoomed out, swiping enabled
        ScrollViewModeZooming,                  // zoomed in, panning enabled
} ScrollViewMode;

@interface ScrollingMadnessViewController : UIViewController <UIScrollViewDelegate> {
	ZoomScrollView *scrollView;
	NSArray *pageViews;
	NSUInteger currentPage;
	ScrollViewMode scrollViewMode;
}

@end
