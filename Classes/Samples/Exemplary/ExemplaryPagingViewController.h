
#import <UIKit/UIKit.h>

@interface ExemplaryPagingViewController : UIViewController {
	NSMutableArray *_pageViews;
	UIScrollView *_scrollView;
	NSUInteger _currentPageIndex;
	BOOL _rotationInProgress;
}

@end
