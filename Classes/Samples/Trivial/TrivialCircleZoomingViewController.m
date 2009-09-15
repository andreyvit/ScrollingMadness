
#import "TrivialCircleZoomingViewController.h"
#import "TrivialCircleView.h"


@interface TrivialCircleZoomingViewController () <UIScrollViewDelegate>

@property (nonatomic, retain) TrivialCircleView *vectorView;

@end


@implementation TrivialCircleZoomingViewController

@synthesize vectorView=_vectorView;

- (void)loadView {
	UIScrollView *scrollView = [[[UIScrollView alloc] init] autorelease];
	scrollView.delegate = self;
	self.vectorView = [[[TrivialCircleView alloc] initWithFrame:CGRectMake(0, 0, 1000, 1000)] autorelease];
	[scrollView addSubview:self.vectorView];
	scrollView.contentSize = self.vectorView.frame.size;
	scrollView.minimumZoomScale = 0.1;
	scrollView.maximumZoomScale = 20;
	self.view = scrollView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	self.vectorView = nil;
}

- (void)dealloc {
	self.vectorView = nil;
    [super dealloc];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.vectorView;
}

@end
