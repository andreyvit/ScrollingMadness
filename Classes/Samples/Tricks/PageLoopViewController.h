
#import <UIKit/UIKit.h>

@interface PageLoopViewController : UIViewController {
	NSMutableArray *_pageViews;
	UIScrollView *_scrollView;
	NSUInteger _currentPageIndex;
}

@end
