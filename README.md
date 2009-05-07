iPhone: Emulating Photos app swiping/zooming/scrolling with a single UIScrollView (example)
===========================================================================================

Many iPhone developers want to emulate the behaviour of the iPhone photo browser: you can swipe between photos, you can zoom a photo and then scroll it, and after you zoom out completely you can swipe again.

The first impression might be that you need two UIScrollViews for this. However nested UIScrollViews are known to behave weirdly, and indeed many people failed to get this setup to work — for example, see [this StackOverflow discussion][1].

  [1]: http://stackoverflow.com/questions/241152/handling-touch-events-within-a-child-uiscrollview/

What you actually need is a single UIScrollView. Before the user starts zooming (in viewForZoomingInScrollView:), switch the scroll view to the zooming mode (remove all pages but the current one, reset content size to a single page and offset to zero). When the user zooms out to scale 1.00 (in scrollViewDidEndZooming:withView:atScale:), switch back to the paging mode (add all pages back, set content size to the width of all pages and offset to the current page).

There's some trickery involved in doing the switching, so this runnable example should show you how to implement it correctly. Of course, you should remove the NSLog's from your production code, they are of no use to you once you've mastered this technique.

If you have any questions, or would like to comment, feel free to email me at andreyvit@gmail.com.


Q: Why is zooming-to-paging transition so complicated?
------------------------------------------------------

Because iPhone (OS version 2.2.1) behaves weirdly. A log from the simulator:

    scrollViewDidScroll: (2.000000, 3.000000)
    scrollViewDidScroll: (2.000000, 1.000000)
    scrollViewDidScroll: (-0.000000, -0.000000)
    scrollViewDidScroll: (1.000000, 0.000000)
    scrollViewDidEndZooming: scale = 1.000000
    scrollViewDidEndZooming, but zoomBouncing is still true!
    scrollViewDidScroll: (0.000000, 0.000000)
    setZoomingMode

So normally `scrollViewDidEndZooming:` cannot switch to the paging mode right away, because UIScrollView will reset its `contentOffset` quite soon. Instead it switches into ScrollViewModeAnimatingFullZoomOut mode, and then the next `scrollViewDidScroll:` knows to call `setPagingMode` when the offset reaches zero. (Sometimes `scrollViewDidScroll:` occurs several times even with zero coordinates, so we have to delay the call to `setPagingMode` even more, or else `contentOffset` would be reset to zero just as well.)

On the real device, even more `scrollViewDidScroll:` notifications tend to arrive while bouncing:

    scrollViewDidScroll: (11.000000, -4.000000)
    scrollViewDidEndZooming: scale = 1.000000
    scrollViewDidEndZooming, but zoomBouncing is still true!
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
    scrollViewDidEndZooming: scale = 1.000000
    scrollViewDidEndZooming, but zoomBouncing is still true!
    setPagingMode
  
Note that the documentation for `scrollViewDidEndZooming:` says it is called after any bouncing animations are finished, so this may be a bug in CocoaTouch.
