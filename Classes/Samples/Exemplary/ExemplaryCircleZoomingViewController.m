
#import "ExemplaryCircleZoomingViewController.h"
#import "TrivialCircleView.h"


#define kInitialSize 500


@interface ExemplaryCircleZoomingViewController () <UIScrollViewDelegate>

@property (nonatomic, retain) TrivialCircleView *vectorView;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIView *tileContainerView;

- (void)updateResolution;

@end


@implementation ExemplaryCircleZoomingViewController

@synthesize vectorView=_vectorView, scrollView=_scrollView, tileContainerView=_tileContainerView;

- (void)loadView {
	self.scrollView = [[[UIScrollView alloc] init] autorelease];
	self.scrollView.delegate = self;
	self.tileContainerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, kInitialSize, kInitialSize)] autorelease];
	self.vectorView = [[[TrivialCircleView alloc] initWithFrame:CGRectMake(0, 0, kInitialSize, kInitialSize)] autorelease];
	[self.tileContainerView addSubview:self.vectorView];
	[self.scrollView addSubview:self.tileContainerView];
	self.scrollView.contentSize = self.tileContainerView.frame.size;
	self.scrollView.minimumZoomScale = 0.1;
	self.scrollView.maximumZoomScale = 8;
	self.view = self.scrollView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	self.vectorView = nil;
	self.scrollView = nil;
}

- (void)dealloc {
	self.vectorView = nil;
	self.scrollView = nil;
    [super dealloc];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.tileContainerView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	[self updateResolution];
}

/*****************************************************************************************/
/* The following method handles changing the resolution of our tiles when our zoomScale  */
/* gets below 50% or above 100%. When we fall below 50%, we lower the resolution 1 step, */
/* and when we get above 100% we raise it 1 step. The resolution is stored as a power of */
/* 2, so -1 represents 50%, and 0 represents 100%, and so on.                            */
/*****************************************************************************************/
- (void)updateResolution {
	// can't go above max resolution of 3 because of UIView size restrictions;
	// need to break the content view into multiple smaller views (e.g. tiles or
	// individual objects) to support higher resolutions.
	NSInteger minimumResolution = -4, maximumResolution = 3;
    
    // delta will store the number of steps we should change our resolution by. If we've fallen below
    // a 25% zoom scale, for example, we should lower our resolution by 2 steps so delta will equal -2.
    // (Provided that lowering our resolution 2 steps stays within the limit imposed by minimumResolution.)
    int delta = 0;
    
    // check if we should decrease our resolution
    for (int thisResolution = minimumResolution; thisResolution < _resolution; thisResolution++) {
        int thisDelta = thisResolution - _resolution;
        // we decrease resolution by 1 step if the zoom scale is <= 0.5 (= 2^-1); by 2 steps if <= 0.25 (= 2^-2), and so on
        float scaleCutoff = pow(2, thisDelta); 
        if (self.scrollView.zoomScale <= scaleCutoff) {
            delta = thisDelta;
            break;
        } 
    }
    
    // if we didn't decide to decrease the resolution, see if we should increase it
    if (delta == 0) {
        for (int thisResolution = maximumResolution; thisResolution > _resolution; thisResolution--) {
            int thisDelta = thisResolution - _resolution;
            // we increase by 1 step if the zoom scale is > 1 (= 2^0); by 2 steps if > 2 (= 2^1), and so on
            float scaleCutoff = pow(2, thisDelta - 1); 
            if ([self.scrollView zoomScale] > scaleCutoff) {
                delta = thisDelta;
                break;
            } 
        }
    }
    
    if (delta != 0) {
        _resolution += delta;
		NSLog(@"Resolution is now %d", _resolution);
        
        // if we're increasing resolution by 1 step we'll multiply our zoomScale by 0.5; up 2 steps multiply by 0.25, etc
        // if we're decreasing resolution by 1 step we'll multiply our zoomScale by 2.0; down 2 steps by 4.0, etc
        float zoomFactor = pow(2, delta * -1); 
        
        // save content offset, content size, and tileContainer size so we can restore them when we're done
        // (contentSize is not equal to containerSize when the container is smaller than the frame of the scrollView.)
        CGPoint contentOffset = [self.scrollView contentOffset];   
        CGSize  contentSize   = [self.scrollView contentSize];
        CGSize  containerSize = [self.tileContainerView frame].size;
        
        // adjust all zoom values (they double as we cut resolution in half)
        [self.scrollView setMaximumZoomScale:[self.scrollView maximumZoomScale] * zoomFactor];
        [self.scrollView setMinimumZoomScale:[self.scrollView minimumZoomScale] * zoomFactor];
        [self.scrollView setZoomScale:[self.scrollView zoomScale] * zoomFactor];
        
        // restore content offset, content size, and container size
        [self.scrollView setContentOffset:contentOffset];
        [self.scrollView setContentSize:contentSize];
        [self.tileContainerView setFrame:CGRectMake(0, 0, containerSize.width, containerSize.height)];    

		// recreate the content view at the new resolution
        [self.vectorView removeFromSuperview];
		CGFloat p = pow(2, _resolution);
		self.vectorView = [[[TrivialCircleView alloc] initWithFrame:CGRectMake(0, 0, kInitialSize * p, kInitialSize * p)] autorelease];
		[self.tileContainerView addSubview:self.vectorView];
    }        
}

@end
