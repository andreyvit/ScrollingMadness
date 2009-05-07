iPhone: advanced UIScrollView tricks everyone should know (and ZoomScrollView that encapsulates them)
=====================================================================================================

Note: the sample code in this project implements both tricks. Furthermore, the second trick is encapsulated in a nice ZoomScrollView class. So you don't really have to read all this to use the code, just download and try it.

The example code in the HEAD uses ZoomScrollView, but one of the earlier commits applies Trick 1 to a plain UIScrollView, so if that's what you are looking for, go grab it in commit history.


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
