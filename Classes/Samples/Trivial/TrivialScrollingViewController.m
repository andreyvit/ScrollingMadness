
#import "TrivialScrollingViewController.h"


@implementation TrivialScrollingViewController

- (void)loadView {
	UIScrollView *scrollView = [[[UIScrollView alloc] init] autorelease];
	UIImage *image = [UIImage imageNamed:@"red.png"];
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
	imageView.image = image;
	[scrollView addSubview:imageView];
	scrollView.contentSize = imageView.frame.size;
	self.view = scrollView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
