#! /usr/bin/env racket
#lang racket

;;;; To Run:
;;;; chmod a+x tinywm.rkt
;;;; ./tinywm.rkt

(require x11/x11)

(define display (XOpenDisplay #f))
(define root (XDefaultRootWindow display))

(define mouse-pointer-init-position '*) ; holds the start position
                                        ; of a mouse grab
(define subwindow-attributes '*)        ; stores the window attributes
                                        ; of a start of a mouse-grab

(define (register-events)
  (XGrabKey display
            (XKeysymToKeycode display (XStringToKeysym "F1"))
            '(Mod1Mask)
            root
            #t
            'GrabModeAsync
            'GrabModeAsync)

  (XGrabButton display
               1
               '(Mod1Mask)
               root
               #t
               '(ButtonPressMask)
               'GrabModeAsync
               'GrabModeAsync
               None
               None)

  (XGrabButton display
               3
               '(Mod1Mask)
               root
               #t
               '(ButtonPressMask)
               'GrabModeAsync
               'GrabModeAsync
               None
               None))

(define (handle-key-press event)
  (let ((subwindow (XKeyEvent-subwindow event)))
   (when (not (= None (XKeyEvent-subwindow event)))
     (XRaiseWindow display subwindow))))

(define (handle-button-press event)
  (let ((subwindow (XButtonEvent-subwindow event))
        (button (XButtonEvent-button event)))
   (when (not (= None subwindow))
     (XGrabPointer display
                   subwindow
                   #t
                   '(PointerMotionMask ButtonReleaseMask)
                   'GrabModeAsync
                   'GrabModeAsync
                   None
                   None
                   CurrentTime)
     (set! subwindow-attributes
           (XGetWindowAttributes display
                                 subwindow))
     (set! mouse-pointer-init-position event))))

(define (handle-motion-notify event)
  (let ((window-pos-x  (XWindowAttributes-x subwindow-attributes))
        (window-pos-y  (XWindowAttributes-y subwindow-attributes))
        (window-width  (XWindowAttributes-width subwindow-attributes))
        (window-height (XWindowAttributes-height subwindow-attributes))
        (start-button  (XButtonEvent-button mouse-pointer-init-position))
        (xdiff         (- (XMotionEvent-x-root event)
                          (XButtonEvent-x-root mouse-pointer-init-position)))
        (ydiff         (- (XMotionEvent-y-root event)
                          (XButtonEvent-y-root mouse-pointer-init-position))))
    (cond [(= 3 start-button) (XMoveResizeWindow display
                                                 (XMotionEvent-window event)
                                                 window-pos-x
                                                 window-pos-y
                                                 (max 1
                                                      (+ xdiff window-width))
                                                 (max 1
                                                      (+ ydiff window-height)))]
          [(= 1 start-button) (XMoveResizeWindow display
                                                 (XMotionEvent-window event)
                                                 (+ window-pos-x xdiff)
                                                 (+ window-pos-y ydiff)
                                                 window-width
                                                 window-height)])))

(define (handle-button-release event)
  (XUngrabPointer display
                  CurrentTime))

(define (main-loop)

  (define event (XNextEvent* display))

  (case (XEvent-type event)
    [(KeyPress)      (handle-key-press event)]
    [(ButtonPress)   (handle-button-press event)]
    [(MotionNotify)  (handle-motion-notify event)]
    [(ButtonRelease) (handle-button-release event)])
  
  (main-loop))

(register-events)
(main-loop)
