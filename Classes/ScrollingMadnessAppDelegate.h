
#import <UIKit/UIKit.h>

@class ScrollingMadnessViewController;

@interface ScrollingMadnessAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    ScrollingMadnessViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ScrollingMadnessViewController *viewController;

@end

