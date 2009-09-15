
#import "TrivialCircleView.h"

@implementation TrivialCircleView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
	CGSize mySize = self.bounds.size;
	CGFloat color[4] = {1.0, 0.0, 0.0, 1.0};
	CGContextSetStrokeColor(context, color);
	CGContextStrokeEllipseInRect(context, CGRectMake(0, 0, mySize.width, mySize.height));
}

- (void)dealloc {
    [super dealloc];
}

@end
