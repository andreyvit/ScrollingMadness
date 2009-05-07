
#import "ScrollingMadnessViewController.h"

@implementation ScrollingMadnessViewController

- (CGSize)pageSize {
	CGSize pageSize = scrollView.frame.size;
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		return CGSizeMake(pageSize.height, pageSize.width);
	else
		return pageSize;
}

- (void)setPagingMode {
	// reposition pages side by side, add them back to the view
	CGSize pageSize = [self pageSize];
	NSUInteger page = 0;
	for (UIView *view in pageViews) {
		if (!view.superview)
			[scrollView addSubview:view];
		view.frame = CGRectMake(pageSize.width * page++, 0, pageSize.width, pageSize.height);
	}
	
	scrollView.pagingEnabled = YES;
	scrollView.showsVerticalScrollIndicator = scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.contentSize = CGSizeMake(pageSize.width * [pageViews count], pageSize.height);
	scrollView.contentOffset = CGPointMake(pageSize.width * currentPage, 0);
	
	scrollViewMode = ScrollViewModePaging;
}

- (void)setZoomingMode {
	NSLog(@"setZoomingMode");
	scrollViewMode = ScrollViewModeZooming; // has to be set early, or else currentPage will be mistakenly reset by scrollViewDidScroll
	
	CGSize pageSize = [self pageSize];
	
	// hide all pages besides the current one
	NSUInteger page = 0;
	for (UIView *view in pageViews)
		if (currentPage != page++)
			[view removeFromSuperview];

	// move the current page to (0, 0), as if no other pages ever existed
	[[pageViews objectAtIndex:currentPage] setFrame:CGRectMake(0, 0, pageSize.width, pageSize.height)];
	
	scrollView.pagingEnabled = NO;
	scrollView.showsVerticalScrollIndicator = scrollView.showsHorizontalScrollIndicator = YES;
	scrollView.contentSize = pageSize;
	scrollView.contentOffset = CGPointZero;
	scrollView.bouncesZoom = YES;
}

- (void)loadView {
	CGRect frame = [UIScreen mainScreen].applicationFrame;
	scrollView = [[ZoomScrollView alloc] initWithFrame:frame];
	scrollView.delegate = self;
	scrollView.maximumZoomScale = 2.0f;
	scrollView.minimumZoomScale = 1.0f;
	scrollView.zoomInOnDoubleTap = scrollView.zoomOutOnDoubleTap = YES;
	
	UIImageView *imageView1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"red.png"]];
	UIImageView *imageView2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"green.png"]];
	UIImageView *imageView3 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"yellow-blue.png"]];
	
	// in a real app, you most likely want to have an array of view controllers, not views;
	// also should be instantiating those views and view controllers lazily
	pageViews = [[NSArray alloc] initWithObjects:imageView1, imageView2, imageView3, nil];
	
	self.view = scrollView;
}

- (void)setCurrentPage:(NSUInteger)page {
	if (page == currentPage)
		return;
	currentPage = page;
	// in a real app, this would be a good place to instantiate more view controllers -- see SDK examples
}

- (void)viewDidLoad {
	scrollViewMode = ScrollViewModeNotInitialized;
	[self setPagingMode];
}

- (void)viewDidUnload {
	[pageViews release]; // need to release all page views here; our array is created in loadView, so just releasing it
	pageViews = nil;
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
	if (scrollViewMode == ScrollViewModePaging)
		[self setCurrentPage:roundf(scrollView.contentOffset.x / [self pageSize].width)];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)aScrollView {
	if (scrollViewMode != ScrollViewModeZooming)
		[self setZoomingMode];
	return [pageViews objectAtIndex:currentPage];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)aScrollView withView:(UIView *)view atScale:(float)scale {
	if (scrollView.zoomScale == scrollView.minimumZoomScale)
		[self setPagingMode];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	if (scrollViewMode == ScrollViewModePaging) {
		scrollViewMode = ScrollViewModeNotInitialized;
		[self setPagingMode];
	} else {
		[self setZoomingMode];
	}
}

@end
