
#import "ZoomScrollView.h"

@interface ZoomScrollView (DelegateMethods) <UIScrollViewDelegate>
@end

@interface ZoomScrollView (ZoomingPrivate)
- (void)_setZoomScaleAndUpdateVirtualScales:(float)zoomScale;           // set UIScrollView's minimumZoomScale/maximumZoomScale
- (BOOL)_handleDoubleTapWith:(UITouch *)touch;
- (UIView *)_createWrapperViewForZoomingInsteadOfView:(UIView *)view;   // create a disposable wrapper view for zooming
- (void)_zoomDidEndBouncing;
- (void)_programmaticZoomAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(UIView *)context;
- (void)_setTransformOn:(UIView *)view;
@end


@implementation ZoomScrollView

@synthesize zoomInOnDoubleTap=_zoomInOnDoubleTap, zoomOutOnDoubleTap=_zoomOutOnDoubleTap;
@synthesize zoomScrollViewDelegate=_realDelegate;

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		_zoomScale = 1.0f;
		_realMinimumZoomScale = super.minimumZoomScale;
		_realMaximumZoomScale = super.maximumZoomScale;
		super.delegate = self;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		_zoomScale = 1.0f;
		_realMinimumZoomScale = super.minimumZoomScale;
		_realMaximumZoomScale = super.maximumZoomScale;
		super.delegate = self;
	}
	return self;
}

- (id<UIScrollViewDelegate>)realDelegate {
	return _realDelegate;
}
- (void)setDelegate:(id<UIScrollViewDelegate>)delegate {
	_realDelegate = delegate;
}

- (float)minimumZoomScale {
	return _realMinimumZoomScale;
}
- (void)setMinimumZoomScale:(float)value {
	_realMinimumZoomScale = value;
	[self _setZoomScaleAndUpdateVirtualScales:_zoomScale];
}

- (float)maximumZoomScale {
	return _realMaximumZoomScale;
}
- (void)setMaximumZoomScale:(float)value {
	_realMaximumZoomScale = value;
	[self _setZoomScaleAndUpdateVirtualScales:_zoomScale];
}

@end


@implementation ZoomScrollView (Zooming)

- (void)_setZoomScaleAndUpdateVirtualScales:(float)zoomScale {
	_zoomScale = zoomScale;
	// prevent accumulation of error, and prevent a common bug in the user's code (comparing floats with '==')
	if (ABS(_zoomScale - _realMinimumZoomScale) < 1e-5)
		_zoomScale = _realMinimumZoomScale;
	else if (ABS(_zoomScale - _realMaximumZoomScale) < 1e-5)
		_zoomScale = _realMaximumZoomScale;
	super.minimumZoomScale = _realMinimumZoomScale / _zoomScale;
	super.maximumZoomScale = _realMaximumZoomScale / _zoomScale;
}

- (void)_setTransformOn:(UIView *)view {
	if (ABS(_zoomScale - 1.0f) < 1e-5)
		view.transform = CGAffineTransformIdentity;
	else
		view.transform = CGAffineTransformMakeScale(_zoomScale, _zoomScale);
}

- (float)zoomScale {
	return _zoomScale;
}

- (void)setZoomScale:(float)zoomScale {
	[self setZoomScale:zoomScale animated:NO];
}

- (void)setZoomScale:(float)zoomScale animated:(BOOL)animated {
	[self setZoomScale:zoomScale centeredAt:CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2) animated:animated];
}

- (void)setZoomScale:(float)zoomScale centeredAt:(CGPoint)centerPoint animated:(BOOL)animated {
	if (![_realDelegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
		NSLog(@"setZoomScale called on ZoomScrollView, however delegate does not implement viewForZoomingInScrollView");
		return;
	}
	
	// viewForZoomingInScrollView may change contentOffset, and centerPoint is relative to the current one
	CGPoint origin = self.contentOffset;
	centerPoint = CGPointMake(centerPoint.x - origin.x, centerPoint.y - origin.y);
	
	UIView *viewForZooming = [_realDelegate viewForZoomingInScrollView:self];
	if (viewForZooming == nil)
		return;
	
	if (animated) {
		[UIView beginAnimations:nil context:viewForZooming];
		[UIView setAnimationDuration: 0.2];
		[UIView setAnimationDelegate: self];
		[UIView setAnimationDidStopSelector: @selector(_programmaticZoomAnimationDidStop:finished:context:)];
	}
	
	[self _setZoomScaleAndUpdateVirtualScales:zoomScale];
	[self _setTransformOn:viewForZooming];
	
	CGSize zoomViewSize   = viewForZooming.frame.size;
	CGSize scrollViewSize = self.frame.size;
	if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
		scrollViewSize = CGSizeMake(scrollViewSize.height, scrollViewSize.width);
	viewForZooming.frame = CGRectMake(0, 0, zoomViewSize.width, zoomViewSize.height);
	self.contentSize = zoomViewSize;
	self.contentOffset = CGPointMake(MAX(MIN(zoomViewSize.width*centerPoint.x/scrollViewSize.width - scrollViewSize.width/2, zoomViewSize.width - scrollViewSize.width), 0),
									 MAX(MIN(zoomViewSize.height*centerPoint.y/scrollViewSize.height - scrollViewSize.height/2, zoomViewSize.height - scrollViewSize.height), 0));
	
	if (animated) {
		[UIView commitAnimations];
	} else {
		[self _programmaticZoomAnimationDidStop:nil finished:nil context:viewForZooming];
	}
}

- (void)_programmaticZoomAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(UIView *)context {
	if ([_realDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)])
		[_realDelegate scrollViewDidEndZooming:self withView:context atScale:_zoomScale];
}

- (BOOL)_handleDoubleTapWith:(UITouch *)touch {
	if (!_zoomInOnDoubleTap && !_zoomOutOnDoubleTap)
		return NO;
	if (_zoomOutOnDoubleTap && ABS(_zoomScale - _realMinimumZoomScale) > 1e-5)
		[self setZoomScale:_realMinimumZoomScale animated:YES];
	else if (_zoomInOnDoubleTap && ABS(_zoomScale - _realMaximumZoomScale) > 1e-5)
		[self setZoomScale:_realMaximumZoomScale centeredAt:[touch locationInView:self] animated:YES];
	return YES;
}

// the heart of the zooming technique: zooming starts here
- (UIView *)_createWrapperViewForZoomingInsteadOfView:(UIView *)view {
	if (_zoomWrapperView != nil) // not sure this is really possible
		[self _zoomDidEndBouncing]; // ...but just in case cleanup the previous zoom op
	
	_realZoomView = [view retain];
	[view removeFromSuperview];
	[self _setTransformOn:_realZoomView]; // should be already set, except if this is a different view
	_realZoomView.frame = CGRectMake(0, 0, _realZoomView.frame.size.width, _realZoomView.frame.size.height);
	_zoomWrapperView = [[UIView alloc] initWithFrame:view.frame];
	[_zoomWrapperView addSubview:view];
	[self addSubview:_zoomWrapperView];
	
	return _zoomWrapperView;
}

// the heart of the zooming technique: zooming ends here
- (void)_zoomDidEndBouncing {
	_zoomingDidEnd = NO;
	[_realZoomView removeFromSuperview];
	[self _setTransformOn:_realZoomView];
	_realZoomView.frame = _zoomWrapperView.frame;
	[self addSubview:_realZoomView];
	
	[_zoomWrapperView release];
	_zoomWrapperView = nil;
	
	if ([_realDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)])
		[_realDelegate scrollViewDidEndZooming:self withView:_realZoomView atScale:_zoomScale];
	[_realZoomView release];
	_realZoomView = nil;
}

@end


@implementation ZoomScrollView (DelegateMethods)

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if ([_realDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)])
		[_realDelegate scrollViewWillBeginDragging:self];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if ([_realDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
		[_realDelegate scrollViewDidEndDragging:self willDecelerate:decelerate];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
	if ([_realDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)])
		[_realDelegate scrollViewWillBeginDecelerating:self];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if ([_realDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)])
		[_realDelegate scrollViewDidEndDecelerating:self];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	if ([_realDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)])
		[_realDelegate scrollViewDidEndScrollingAnimation:self];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	UIView *viewForZooming = nil;
	if ([_realDelegate respondsToSelector:@selector(viewForZoomingInScrollView:)])
		viewForZooming = [_realDelegate viewForZoomingInScrollView:self];
	if (viewForZooming != nil)
		viewForZooming = [self _createWrapperViewForZoomingInsteadOfView:viewForZooming];
	return viewForZooming;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	[self _setZoomScaleAndUpdateVirtualScales:_zoomScale * scale];
	
	// often UIScrollView continues bouncing even after the call to this method, so we have to use delays
	_zoomingDidEnd = YES; // signal scrollViewDidScroll to schedule _zoomDidEndBouncing call
	[self performSelector:@selector(_zoomDidEndBouncing) withObject:nil afterDelay:0.1];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (_zoomWrapperView != nil && _zoomingDidEnd) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_zoomDidEndBouncing) object:nil];
		[self performSelector:@selector(_zoomDidEndBouncing) withObject:nil afterDelay:0.1];
	}
		
	if ([_realDelegate respondsToSelector:@selector(scrollViewDidScroll:)])
		[_realDelegate scrollViewDidScroll:self];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	if ([_realDelegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)])
		return [_realDelegate scrollViewShouldScrollToTop:self];
	else
		return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
	if ([_realDelegate respondsToSelector:@selector(scrollViewDidScrollToTop:)])
		[_realDelegate scrollViewDidScrollToTop:self];	
}

@end


@implementation ZoomScrollView (EventForwarding)

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	id delegate = self.delegate;
	if ([delegate respondsToSelector:@selector(zoomScrollView:touchesBegan:withEvent:)])
		_ignoreSubsequentTouches = [delegate zoomScrollView:self touchesBegan:touches withEvent:event];
	if (_ignoreSubsequentTouches)
		return;
	if ([touches count] == 1 && [[touches anyObject] tapCount] == 2)
		if ([self _handleDoubleTapWith:[touches anyObject]])
			return;
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	id delegate = self.delegate;
	if ([delegate respondsToSelector:@selector(zoomScrollView:touchesMoved:withEvent:)])
		if ([delegate zoomScrollView:self touchesMoved:touches withEvent:event]) {
			_ignoreSubsequentTouches = YES;
			[super touchesCancelled:touches withEvent:event];
		}
	if (_ignoreSubsequentTouches)
		return;
	[super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	id delegate = self.delegate;
	if ([delegate respondsToSelector:@selector(zoomScrollView:touchesEnded:withEvent:)])
		if ([delegate zoomScrollView:self touchesEnded:touches withEvent:event]) {
			_ignoreSubsequentTouches = YES;
			[super touchesCancelled:touches withEvent:event];
		}
	if (_ignoreSubsequentTouches)
		return;
	[super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	id delegate = self.delegate;
	if ([delegate respondsToSelector:@selector(zoomScrollView:touchesCancelled:withEvent:)])
		if ([delegate zoomScrollView:self touchesCancelled:touches withEvent:event])
			_ignoreSubsequentTouches = YES;
	[super touchesCancelled:touches withEvent:event];
}

@end

