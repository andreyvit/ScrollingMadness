
#import <UIKit/UIKit.h>

@class TrivialCircleView;

@interface ExemplaryCircleZoomingViewController : UIViewController {
	TrivialCircleView *_vectorView;
	UIScrollView *_scrollView;
	UIView *_tileContainerView;
	NSInteger _resolution;
}

@end
