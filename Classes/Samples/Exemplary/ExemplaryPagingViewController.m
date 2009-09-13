
#import "ExemplaryPagingViewController.h"


@interface ExemplaryPagingViewController () <UIScrollViewDelegate>

@property (nonatomic, retain) NSMutableArray *pageViews;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, readonly) NSUInteger currentPageIndex;

@end


@implementation ExemplaryPagingViewController

@synthesize pageViews=_pageViews, scrollView=_scrollView, currentPageIndex=_currentPageIndex;

- (UIView *)loadViewForPage:(NSUInteger)pageIndex {
	UIImage *image = nil;
	switch(pageIndex % 3) {
		case 0: image = [UIImage imageNamed:@"red.png"]; break;
		case 1: image = [UIImage imageNamed:@"green.png"]; break;
		case 2: image = [UIImage imageNamed:@"yellow-blue.png"]; break;
	}
	UIImageView *pageView = [[[UIImageView alloc] initWithImage:image] autorelease];
	pageView.contentMode = UIViewContentModeScaleToFill;
	return pageView;
}

- (CGRect)alignView:(UIView *)view forPage:(NSUInteger)pageIndex inRect:(CGRect)rect {
	UIImageView *imageView = (UIImageView *)view;
	CGSize imageSize = imageView.image.size;
	CGFloat ratioX = rect.size.width / imageSize.width, ratioY = rect.size.height / imageSize.height;
	CGSize size = (ratioX < ratioY ?
				   CGSizeMake(rect.size.width, ratioX * imageSize.height) :
				   CGSizeMake(ratioY * imageSize.width, rect.size.height));
	return CGRectMake(rect.origin.x + (rect.size.width - size.width) / 2,
					  rect.origin.y + (rect.size.height - size.height) / 2,
					  size.width, size.height);
}

- (NSUInteger)numberOfPages {
	return [self.pageViews count];
}

- (UIView *)viewForPage:(NSUInteger)pageIndex {
	NSParameterAssert(pageIndex >= 0);
	NSParameterAssert(pageIndex < [self numberOfPages]);
	
	UIView *pageView;
	if ([self.pageViews objectAtIndex:pageIndex] == [NSNull null]) {
		pageView = [self loadViewForPage:pageIndex];
		[self.pageViews replaceObjectAtIndex:pageIndex withObject:pageView];
		[self.scrollView addSubview:pageView];
		NSLog(@"View loaded for page %d", pageIndex);
	} else {
		pageView = [self.pageViews objectAtIndex:pageIndex];
	}
	return pageView;
}

- (CGSize)pageSize {
	return self.scrollView.frame.size;
}

- (BOOL)isPageLoaded:(NSUInteger)pageIndex {
	return [self.pageViews objectAtIndex:pageIndex] != [NSNull null];
}

- (void)layoutPage:(NSUInteger)pageIndex {
	UIView *pageView = [self viewForPage:pageIndex];
	CGSize pageSize = [self pageSize];
	pageView.frame = [self alignView:pageView forPage:pageIndex inRect:CGRectMake(pageIndex * pageSize.width, 0, pageSize.width, pageSize.height)];
}

- (void)loadView {
	self.scrollView = [[[UIScrollView alloc] init] autorelease];
	self.scrollView.delegate = self;
	self.scrollView.pagingEnabled = YES;
	self.scrollView.showsHorizontalScrollIndicator = NO;
	self.scrollView.showsVerticalScrollIndicator = NO;
	self.view = self.scrollView;
}

- (void)viewDidLoad {
	self.pageViews = [NSMutableArray array];
	// to save time and memory, we won't load the page views immediately
	for (NSUInteger i = 0; i < 8; ++i)
		[self.pageViews addObject:[NSNull null]];
}

- (void)currentPageIndexDidChange {
	[self layoutPage:_currentPageIndex];
	if (_currentPageIndex+1 < [self numberOfPages])
		[self layoutPage:_currentPageIndex+1];
	if (_currentPageIndex > 0)
		[self layoutPage:_currentPageIndex-1];
	self.navigationItem.title = [NSString stringWithFormat:@"%d of %d", 1+_currentPageIndex, [self numberOfPages]];
}

- (void)layoutPages {
	CGSize pageSize = [self pageSize];
	self.scrollView.contentSize = CGSizeMake([self numberOfPages] * pageSize.width, pageSize.height);
	// move all visible pages to their places, because otherwise they may overlap
	for (NSUInteger pageIndex = 0; pageIndex < [self numberOfPages]; ++pageIndex)
		if ([self isPageLoaded:pageIndex])
			[self layoutPage:pageIndex];
}

- (void)viewWillAppear:(BOOL)animated {
	[self layoutPages];
	[self currentPageIndexDidChange];
	self.scrollView.contentOffset = CGPointMake(_currentPageIndex * [self pageSize].width, 0);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (_rotationInProgress)
		return; // UIScrollView layoutSubviews code adjusts contentOffset, breaking our logic
	
	NSLog(@"didScroll, scroll content offset = %@", NSStringFromCGPoint(self.scrollView.contentOffset));
	
	CGSize pageSize = [self pageSize];
	NSUInteger newPageIndex = (self.scrollView.contentOffset.x + pageSize.width / 2) / pageSize.width;
	if (newPageIndex == _currentPageIndex) return;
	_currentPageIndex = newPageIndex;
	
	[self currentPageIndexDidChange];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	_rotationInProgress = YES;
	
	// hide other page views because they may overlap the current page during animation
	for (NSUInteger pageIndex = 0; pageIndex < [self numberOfPages]; ++pageIndex)
		if ([self isPageLoaded:pageIndex])
			[self viewForPage:pageIndex].hidden = (pageIndex != _currentPageIndex);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	// resize and reposition the page view, but use the current contentOffset as page origin
	// (note that the scrollview has already been resized by the time this method is called)
	CGSize pageSize = [self pageSize];
	UIView *pageView = [self viewForPage:_currentPageIndex];
	[self viewForPage:_currentPageIndex].frame = [self alignView:pageView forPage:_currentPageIndex inRect:CGRectMake(self.scrollView.contentOffset.x, 0, pageSize.width, pageSize.height)];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	// adjust frames according to the new page size - this does not cause any visible changes
	[self layoutPages];
	self.scrollView.contentOffset = CGPointMake(_currentPageIndex * [self pageSize].width, 0);
	
	// unhide
	for (NSUInteger pageIndex = 0; pageIndex < [self numberOfPages]; ++pageIndex)
		if ([self isPageLoaded:pageIndex])
			[self viewForPage:pageIndex].hidden = NO;
	
	_rotationInProgress = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	if (self.pageViews) {
		// unload non-visible pages in case the memory is scarse
		for (NSUInteger pageIndex = 0; pageIndex < [self numberOfPages]; ++pageIndex)
			if (pageIndex < _currentPageIndex-1 || pageIndex > _currentPageIndex+1)
				if ([self isPageLoaded:pageIndex]) {
					UIView *pageView = [self.pageViews objectAtIndex:pageIndex];
					[self.pageViews replaceObjectAtIndex:pageIndex withObject:[NSNull null]];
					[pageView removeFromSuperview];
				}
	}
}

- (void)viewDidUnload {
	self.pageViews = nil;
	self.scrollView = nil;
}

- (void)dealloc {
	[self viewDidUnload];
    [super dealloc];
}

@end
