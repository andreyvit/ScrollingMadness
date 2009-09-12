
#import "TrivialZoomingViewController.h"


@interface TrivialZoomingViewController () <UIScrollViewDelegate>

@property (nonatomic, retain) UIImageView *imageView;

@end


@implementation TrivialZoomingViewController

@synthesize imageView=_imageView;

- (void)loadView {
	UIScrollView *scrollView = [[[UIScrollView alloc] init] autorelease];
	scrollView.delegate = self;
	UIImage *image = [UIImage imageNamed:@"red.png"];
	self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
	self.imageView.image = image;
	[scrollView addSubview:self.imageView];
	scrollView.contentSize = self.imageView.frame.size;
	scrollView.minimumZoomScale = 0.1;
	scrollView.maximumZoomScale = 10;
	self.view = scrollView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	self.imageView = nil;
}

- (void)dealloc {
	self.imageView = nil;
    [super dealloc];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.imageView;
}

@end
