
#import <UIKit/UIKit.h>

/*
 ZoomScrollView makes UIScrollView easier to use:
 
 - ZoomScrollView is a drop-in replacement subclass of UIScrollView
 
 - ZoomScrollView adds programmatic zooming
   (see `setZoomScale:centeredAt:animated:`)
 
 - ZoomScrollView allows you to get the current zoom scale
   (see `zoomScale` property)
 
 - ZoomScrollView handles double-tap zooming for you
   (see `zoomInOnDoubleTap`, `zoomOutOnDoubleTap`)
 
 - ZoomScrollView forwards touch events to its delegate, allowing to handle
   custom gestures easily (triple-tap? two-finger scrolling?)
 
 Drop-in replacement:

 You can replace `[UIScrollView alloc]` with `[ZoomScrollView alloc]` or change
 class in Interface Builder, and everything should continue to work. The only
 catch is that you should not *read* the 'delegate' property; to get your delegate,
 please use zoomScrollViewDelegate property instead. (You can set the delegate
 via either of these properties, but reading 'delegate' does not work.)
 
 Zoom scale:
 
 Reading zoomScale property returns the scale of the last scaling operation.
 If your viewForZoomingInScrollView can return different views over time,
 please keep in mind that any view you return is instantly scaled to zoomScale.
 
 Delegate:
 
 The delegate accepted by ZoomScrollView is a regular UIScrollViewDelegate,
 however additional methods from `NSObject(ZoomScrollViewDelegateMethods)` category
 will be called on your delegate if defined.
 
 Method `scrollViewDidEndZooming:withView:atScale:` is called after any 'bounce'
 animations really finish. UIScrollView often calls it earlier, violating
 the documented contract of UIScrollViewDelegate.
 
 Instead of reading 'delegate' property (which currently returns the scroll
 view itself), you should read 'zoomScrollViewDelegate' property which
 correctly returns your delegate. Setting works with either of them (so you
 can still set your delegate in the Interface Builder).
 
 */

@interface ZoomScrollView : UIScrollView {
@private
	BOOL _zoomInOnDoubleTap;
	BOOL _zoomOutOnDoubleTap;
	BOOL _zoomingDidEnd;
	BOOL _ignoreSubsequentTouches;                                // after one of delegate touch methods returns YES, subsequent touch events are not forwarded to UIScrollView
	float _zoomScale;
	float _realMinimumZoomScale, _realMaximumZoomScale;           // as set by the user (UIScrollView's min/maxZoomScale == our min/maxZoomScale divided by _zoomScale)
	id _realDelegate;                       // as set by the user (UIScrollView's delegate is set to self)
	UIView *_realZoomView;                      // the view for zooming returned by the delegate
	UIView *_zoomWrapperView;               // the disposable wrapper view actually used for zooming
}

// if both are enabled, zoom-in takes precedence unless the view is at maximum zoom scale
@property(nonatomic, assign) BOOL zoomInOnDoubleTap;
@property(nonatomic, assign) BOOL zoomOutOnDoubleTap;

@property(nonatomic, assign) id<UIScrollViewDelegate> zoomScrollViewDelegate;

@end

@interface ZoomScrollView (Zooming)

@property(nonatomic, assign) float zoomScale;                     // from minimumZoomScale to maximumZoomScale

- (void)setZoomScale:(float)zoomScale animated:(BOOL)animated;    // centerPoint == center of the scroll view
- (void)setZoomScale:(float)zoomScale centeredAt:(CGPoint)centerPoint animated:(BOOL)animated;

@end

@interface NSObject (ZoomScrollViewDelegateMethods)

// return YES to stop processing, NO to pass the event to UIScrollView (mnemonic: default is to pass, and default return value in Obj-C is NO)
- (BOOL)zoomScrollView:(ZoomScrollView *)zoomScrollView touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (BOOL)zoomScrollView:(ZoomScrollView *)zoomScrollView touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (BOOL)zoomScrollView:(ZoomScrollView *)zoomScrollView touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (BOOL)zoomScrollView:(ZoomScrollView *)zoomScrollView touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end
