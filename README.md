Catalog of UIScrollView samples (iPhone)
========================================

Hey, new and old friends of ScrollingMadness,

This project used to demonstrate some hacks needed to implement Photos.app-style paging+scrolling+zooming on iPhone. However I'm pleased to say that on iPhone OS 3.x no hacks are necessary any more!

First, nested UIScrollView's are supported natively on 3.x. To implement paging+scrolling you just use an outer UIScrollView in paging mode, and separate UIScrollViews for each page. They work together automagically.

Second, UIScrollView now supports programmatic zooming natively. See setZoomScale: and the like.

Third, many of you came here to implement double-tap-to-zoom functionality. Apple now has an example called ScrollViewSuite which shows this, and contains some other tricks like tiling. You should really check it out.

My ZoomScrollView component is officially retired. ScrollingMadness project is now a catalog of UIScrollView samples, in particular, it shows a way to support UI rotation in paging mode, something that still requires a bit of a hack. The old README is available too — it's not of much direct interest, but shows who you'd go about hacking UIScrollView if you ever need too.

BTW I'm always looking for iPhone work — if you happen to have one, please consider sending it my way.

Andrey.


Old Content
-----------

The title used to be: “advanced UIScrollView tricks everyone should know (and ZoomScrollView that encapsulates them)”

Note: the sample code in this project implements both tricks. Furthermore, the second trick is encapsulated in a nice ZoomScrollView class. So you don't really have to read all this to use the code, just download and try it.

The example code in the HEAD uses ZoomScrollView, but one of the earlier commits applies Trick 1 to a plain UIScrollView, so if that's what you are looking for, go grab it in commit history.


Cover story: How does UIScrollView work?
----------------------------------------

To do anything non-trivial with UIScrollView, you must know how it works internally.

UIScrollView overrides `hitTest` method and always returns itself, so that all touch events (`touchesBegan`, `touchesMoved`, `touchesEnded`, `touchesCancelled`) go into it. Then inside `touchesBegan`, `touchesMoved` etc it checks if it's interested in the event, and either handles or passes it on to the inner views.

To decide if the touch is to be handled or to be forwarded, UIScrollView starts a timer when you first touch it:

* If you haven't moved your finger significantly within 150ms, it passes the event on to the inner view.

* If you have moved your finger significantly within 150ms, it starts scrolling (and never passes the event to the inner view).

   Note how when you touch a table (which is a subclass of scroll view) and start scrolling immediately, the row that you touched is never highlighted.

* If you have *not* moved your finger significantly within 150ms and UIScrollView started passing the events to the inner view, but *then* you have moved the finger far enough for the scrolling to begin, UIScrollView calls `touchesCancelled` on the inner view and starts scrolling.

   Note how when you touch a table, hold your finger a bit and then start scrolling, the row that you touched is highlighted first, but de-highlighted afterwards.

These sequence of events can be altered by configuration of UIScrollView:

* If `delaysContentTouches` is NO, then no timer is used — the events immediately go to the inner control (but then are canceled if you move your finger far enough)
* If `canCancelContentTouches` is NO, then once the events reach the inner view, scrolling will never happen.

Note that it is UIScrollView that receives *all* `touchesBegin`, `touchesMoved`, `touchesEnded` and `touchesCanceled` events from CocoaTouch (because its `hitTest` tells it to do so). It then forwards them to the inner view if it wants to, as long as it wants to.


Trick 1: Emulating Photos app swiping/zooming/scrolling with a single UIScrollView
----------------------------------------------------------------------------------

Many iPhone developers want to emulate the behaviour of the iPhone photo browser: you can swipe between photos, you can zoom a photo and then scroll it, and after you zoom out completely you can swipe again.

The first impression might be that you need nested UIScrollViews for this. However nested UIScrollViews are known to behave weirdly, and indeed many people failed to get this setup to work — for example, see [this StackOverflow discussion][1].

  [1]: http://stackoverflow.com/questions/241152/handling-touch-events-within-a-child-uiscrollview/

What you actually need is a single UIScrollView. Before the user starts zooming (in viewForZoomingInScrollView:), switch the scroll view into zooming mode (remove all pages but the current one, reset contentSize to a single page and contentOffset to zero). When the user zooms out completely (in scrollViewDidEndZooming:withView:atScale:), switch back into paging mode (add all pages back, set contentSize to the width of all pages and contentOffset to the current page).

There's some trickery involved in doing the switching, so this runnable example should show you how to implement it correctly. Of course, you should remove the NSLog's from your production code, they are of no use to you once you've mastered this technique.

If you have any questions, or would like to comment, feel free to email me at andreyvit@gmail.com.


Why UIScrollView's zooming API is so, well, strange (unexistent)?
-----------------------------------------------------------------

Imagine a futuristic user interface like the one they show in hacker movies: a huge touch screen with lots of windows floating around. You can scroll the whole screen with your fingers, or you can touch any single window and zoom it in or out by pinching. This is the concept of UIScrollView: many individually zoomable windows.

Most people have a different concept in mind, however. They have a single content view they want to scroll and zoom. Therefore they ask questions like “how do I programmatically zoom an UIScrollView?” This is completely natural, but unfortunately not what designers of UIScrollView wanted to support. (Hey, maybe a huge-screen futuristic PC is coming out of Apple labs soon?)

UIScrollView does not have a notion of a “current zoom level”, because each subview it contains may have its own current zoom level. Note that there is no field in UIScrollView to keep the current zoom level. However we know that someone stores that zoom level, because if you pinch-zoom a subview, then reset its transform to CGAffineTransformIdentity, and then pinch again, you will notice that the previous zoom level of the subview has been restored.

Indeed, if you look at the disassembly, it is UIView that stores its own zoom level (inside UIGestureInfo object pointed to by the _gestureInfo field). It also has a set of nice undocumented methods like `zoomScale` and `setZoomScale:animated:`. (Mind you, it also has a bunch of rotation-related methods, maybe we're getting rotation gesture support some day soon.)

Summary: UIScrollView does not have programmatic zoom API by design. UIView, on the other hand, does have zooming API, it just happens to not be exposed to the public. (This design is highly questionable, of course. Maybe its questioning is exactly the reason why there's no public API at the moment.)


Trick 2: How to programmatically zoom an UIScrollView (in a clean way)
----------------------------------------------------------------------

Of course, we cannot use undocumented methods in App Store applications. (If we could, Apple would not be free to change their implementation details, and we would end up with Windows-style compatibility problems and a sucking platform. I prefer the way it is now, thanks.) So we have no control over the internal zoom scale stored by UIView.

However, if we create a new UIView just for zooming and add our real zoomable view as its child, we will always start with zoom level 1.0, which is much better than starting with arbitrary zoom level. After zooming ends, we manually set the needed scaling transform to the real zoomable view and dispose the wrapper view.

Once you get this right, programmatic zooming involves simply applying a proper scaling transform to your content view. With hidden zoom scale out of your way, and with the dirty UIScrollView's hands off your content view (we give it a dummy throw-away wrapper view instead), noone can stop you from applying any zoom level to your views.

Slighly more detailed description: normally your content view is a child view of UIScrollView. You also maintain a current zoom level, and your content view always has a transform equal to `CGAffineTransformMakeScale(currentZoomLevel, currentZoomLevel)`. When `viewForZoomingInScrollView:` gets called, you create a new UIView (we'll call it a “wrapper”), initialize it with the *frame* of your content view, remove your content view from UIScrollView and add it to the wrapper. (You also set the top-left corner of your content view's *frame* to be 0,0.)

When `scrollViewDidEndZooming:` is called, you copy the wrapper's *frame* back to your content view's *frame*, then move the content view back into UIScrollView and dispose the wrapper. You also multiply your currentZoomLevel by the zoom level reported in the notification, and adjust UIScrollView's minimumZoomScale/maximumZoomScale accordingly (e.g. `minimumZoomScale = realMinimumZoomScale / currentZoomLevel`);

(Note the word `frame` highlighted in the previous two paragraphs. You need to manipulate frames, not bounds, even though your view has a non-identity transform, because you want to synchronize the positions and sizes in UIScrollView's coordinates, not in your content view's coordinates.)

Another way to circumvent the hidden zoom scale involves overriding setTransform on your content views and de-scaling the transform that is being set, according to the last known zoom level. This feels dirty to me because I do not want to subclass my content views; I want all the logic to be contained within the scroll view's view controller. Also this solution relies on the fact that zooming code uses setTransform to apply the transformation. Given that the code is inside UIView, it might easily start using some internal method for that.


Meet ZoomScrollView!
--------------------

(A quote from comments in the header file.)

ZoomScrollView makes UIScrollView easier to use:

- ZoomScrollView is a drop-in replacement subclass of UIScrollView

- ZoomScrollView adds programmatic zooming
  (see `setZoomScale:centeredAt:animated:`)

- ZoomScrollView allows you to get the current zoom scale
  (see `zoomScale` property)

- ZoomScrollView handles double-tap zooming for you
  (see `zoomInOnDoubleTap`, `zoomOutOnDoubleTap`)

- ZoomScrollView forwards touch events to its delegate, allowing to handle
  custom gestures easily (triple-tap? two-finger scrolling?)

Drop-in replacement:

You can replace `[UIScrollView alloc]` with `[ZoomScrollView alloc]` or change
class in Interface Builder, and everything should continue to work. The only
catch is that you should not *read* the 'delegate' property; to get your delegate,
please use zoomScrollViewDelegate property instead. (You can set the delegate
via either of these properties, but reading 'delegate' does not work.)

Zoom scale:

Reading zoomScale property returns the scale of the last scaling operation.
If your viewForZoomingInScrollView can return different views over time,
please keep in mind that any view you return is instantly scaled to zoomScale.

Delegate:

The delegate accepted by ZoomScrollView is a regular UIScrollViewDelegate,
however additional methods from `NSObject(ZoomScrollViewDelegateMethods)` category
will be called on your delegate if defined.

Method `scrollViewDidEndZooming:withView:atScale:` is called after any 'bounce'
animations really finish. UIScrollView often calls it earlier, violating
the documented contract of UIScrollViewDelegate.

Instead of reading 'delegate' property (which currently returns the scroll
view itself), you should read 'zoomScrollViewDelegate' property which
correctly returns your delegate. Setting works with either of them (so you
can still set your delegate in the Interface Builder).


Possible trick 3: How to get nested UIScrollViews to work
---------------------------------------------------------

I haven't tried this one, but outlined a possible solution in an answer to this Stack Overflow question: http://stackoverflow.com/questions/728014/prevent-diagonal-scrolling-in-uiscrollview/; now I'm merely reprinting my idea here.

Suppose you want your outer scroll view to page-scroll horizontally, and your inner scroll views (one scroll view per page) to scroll vertically. You want to give preference to vertical scrolling, so that once the user touches the view and starts moving his finger (even slightly), the view starts scrolling in vertical direction; but when the user moves his finger in horizontal direction far enough, you want to cancel vertical scrolling and start horizontal scrolling.

The strategy is to let the outer scroll view only handle horizontal scrolling. You want to subclass your outer UIScrollView (and, say, name your subclass RemorsefulScrollView), so that instead of the default behaviour it immediately forwards all events to the inner view, and only when significant horizontal movement is detected it scrolls.

How to make RemorsefulScrollView behave that way?

* It looks like disabling vertical scrolling and setting `delaysContentTouches` to NO should make nested UIScrollViews to work. Unfortunately, it does not; UIScrollView appears to do some additional filtering for fast motions (which cannot be disabled), so that even if UIScrollView can only be scrolled horizontally, it will always eat up (and ignore) fast enough vertical motions.

  The effect is so severe that vertical scrolling inside a nested scroll view is unusable. (It appears that you have got exactly this setup, so try it: hold a finger for 150ms, and then move it in vertical direction — nested UIScrollView works as expected then!)

* This means you cannot use UIScrollView's code for event handling; you have to override all four touch handling methods in RemorsefulScrollView and do your own processing first, only forwarding the event to `super` (UIScrollView) if you have decided to go with horizontal scrolling.

* However you have to pass `touchesBegan` to UIScrollView, because you want it to remember a base coordinate for future horizontal scrolling (if you later decide it *is* a horizontal scrolling). You won't be able to send `touchesBegan` to UIScrollView later, because you cannot store the `touches` argument: it contains objects that will be mutated before the next `touchesMoved` event, and you cannot reproduce the old state.

  So you have to pass `touchesBegan` to UIScrollView immediately, but you will hide any further `touchesMoved` events from it until you decide to scroll horizontally. No `touchesMoved` means no scrolling, so this initial `touchesBegan` will do no harm. But do set `delaysContentTouches` to NO, so that no additional surprise timers interfere.

  (Offtopic — unlike you, UIScrollView *can* store touches properly and can reproduce and forward the original `touchesBegan` event later. It has an unfair advantage of using unpublished APIs, so can clone touch objects before they are mutated.)
  
* Given that you always forward `touchesBegan`, you also have to forward `touchesCancelled` and `touchesEnded`. You have to turn `touchesEnded` into `touchesCancelled`, however, because UIScrollView would interpret `touchesBegan`, `touchesEnded` sequence as a touch-click, and would forward it to the inner view. You are already forwarding the proper events yourself, so you never want UIScrollView to forward anything.

Basically here's pseudocode for what you need to do. For simplicity, I never allow horizontal scrolling after multitouch event has occurred.

    // RemorsefulScrollView.h
    
    @interface RemorsefulScrollView : UIScrollView {
      CGPoint _originalPoint;
      BOOL _isHorizontalScroll, _isMultitouch;
      UIView *_currentChild;
    }
    @end
    
    // RemorsefulScrollView.m
    
    // the numbers from an example in Apple docs, may need to tune them
    #define kThresholdX 12.0f
    #define kThresholdY 4.0f
    
    @implementation RemorsefulScrollView
    
    - (id)initWithFrame:(CGRect)frame {
      if (self = [super initWithFrame:frame]) {
        self.delaysContentTouches = NO;
      }
      return self;
    }
    
    - (id)initWithCoder:(NSCoder *)coder {
      if (self = [super initWithCoder:coder]) {
        self.delaysContentTouches = NO;
      }
      return self;
    }
    
    - (UIView *)honestHitTest:(CGPoint)point withEvent:(UIEvent *)event {
      UIView *result = nil;
      for (UIView *child in self.subviews)
        if ([child pointInside:point withEvent:event])
          if ((result = [child hitTest:point withEvent:event]) != nil)
            break;
      return result;
    }
    
    - (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    	[super touchesBegan:touches withEvent:event]; // always forward touchesBegan -- there's no way to forward it later
    	if (_isHorizontalScroll)
    	  return; // UIScrollView is in charge now
    	if ([touches count] == [[event touchesForView:self] count]) { // initial touch
    	  _originalPoint = [[touches anyObject] locationInView:self];
        _currentChild = [self honestHitTest:_originalPoint withEvent:event];
        _isMultitouch = NO;
    	}
      _isMultitouch ||= ([[event touchesForView:self] count] > 1);
      [_currentChild touchesBegan:touches withEvent:event];
    }
    
    - (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
      if (!_isHorizontalScroll && !_isMultitouch) {
        CGPoint point = [[touches anyObject] locationInView:self];
        if (fabsf(_originalPoint.x - point.x) > kThresholdX && fabsf(_originalPoint.y - point.y) < kThresholdY) {
          _isHorizontalScroll = YES;
          [_currentChild touchesCancelled:[event touchesForView:self] withEvent:event]
        }
      }
      if (_isHorizontalScroll)
      	[super touchesMoved:touches withEvent:event]; // UIScrollView only kicks in on horizontal scroll
      else
        [_currentChild touchesMoved:touches withEvent:event];
    }
    
    - (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
      if (_isHorizontalScroll)
      	[super touchesEnded:touches withEvent:event];
    	else {
      	[super touchesCancelled:touches withEvent:event];
      	[_currentChild touchesEnded:touches withEvent:event];
    	}
    }

    - (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  	  [super touchesCancelled:touches withEvent:event];
  	  if (!_isHorizontalScroll)
      	[_currentChild touchesCancelled:touches withEvent:event];
    }

    @end

I have not tried to run or even to compile this (and typed the whole class in a plain text editor), but you can start with the above and hopefully get it working.

The only hidden catch I see is that if you add any non-UIScrollView child views to RemorsefulScrollView, the touch events you forward to a child may arrive back to you via responder chain, if the child does not always handle touches like UIScrollView does. A bullet-proof RemorsefulScrollView implementation would protect against `touchesXxx` reentry.

Hopefully some day I will implement this (or receive a working implementation from some nice guy/girl) and include it into ZoomScrollView and/or publish it as a separate class inside ScrollingMadness project.


FAQ: Why is zooming-to-paging transition in the example so complicated?
-----------------------------------------------------------------------

(This only applies to one of the previous commits. The example code in the HEAD uses ZoomScrollView, 
which hides the problems described here.)

Because iPhone (OS version 2.2.1) behaves weirdly. A log from the simulator:

    scrollViewDidScroll: (2.000000, 3.000000)
    scrollViewDidScroll: (2.000000, 1.000000)
    scrollViewDidScroll: (-0.000000, -0.000000)
    scrollViewDidScroll: (1.000000, 0.000000)
    scrollViewDidEndZooming: scale = 1.000000, but zoomBouncing is still true!
    scrollViewDidScroll: (0.000000, 0.000000)
    setZoomingMode

So normally `scrollViewDidEndZooming:` cannot switch to the paging mode right away, because UIScrollView will reset its `contentOffset` quite soon. Instead it switches into ScrollViewModeAnimatingFullZoomOut mode, and then the next `scrollViewDidScroll:` knows to call `setPagingMode` when the offset reaches zero. (Sometimes `scrollViewDidScroll:` occurs several times even with zero coordinates, so we have to delay the call to `setPagingMode` even more, or else `contentOffset` would be reset to zero just as well.)

On the real device, even more `scrollViewDidScroll:` notifications tend to arrive while bouncing:

    scrollViewDidScroll: (11.000000, -4.000000)
    scrollViewDidEndZooming: scale = 1.000000, but zoomBouncing is still true!
    scrollViewDidScroll: (10.000000, -4.000000)
    scrollViewDidScroll: (9.000000, -4.000000)
    scrollViewDidScroll: (8.000000, -4.000000)
    scrollViewDidScroll: (6.000000, -3.000000)
    scrollViewDidScroll: (5.000000, -2.000000)
    scrollViewDidScroll: (3.000000, -2.000000)
    scrollViewDidScroll: (2.000000, -1.000000)
    scrollViewDidScroll: (1.000000, -1.000000)
    scrollViewDidScroll: (0.000000, -1.000000)
    scrollViewDidScroll: (0.000000, 0.000000)
    setPagingMode

However, if you simply touch the image view with two fingers and do not zoom, no bouncing will take place, so no more `scrollViewDidScroll:` notifications arrive, and thus we have to initiate a delayed call to `setPagingMode` in `scrollViewDidEndZooming:` too. In this case, the log looks like this:

    setZoomingMode
    scrollViewDidScroll: (-0.000000, -0.000000)
    scrollViewDidEndZooming: scale = 1.000000
    setPagingMode
    
We cannot rely on `scrollView.zoomBouncing` (in `scrollViewDidEndZooming:`) to choose between one of these behaviours, because sometimes `zoomBouncing` is YES, but no subsequent `scrollViewDidScroll:` notifications arrive:

    scrollViewDidScroll: (0.000000, 0.000000)
    scrollViewDidScroll: (0.000000, 0.000000)
    scrollViewDidEndZooming: scale = 1.000000, but zoomBouncing is still true!
    setPagingMode
  
Note that the documentation for `scrollViewDidEndZooming:` says it is called after any bouncing animations are finished, so this may be a bug in CocoaTouch.
