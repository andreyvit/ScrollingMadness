
#import <UIKit/UIKit.h>

@class ScrollingMadnessViewController;

@interface ScrollingMadnessAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UIViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *viewController;

@end

