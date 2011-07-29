(in-package :beh)#| ######################################################################Behave window Copyright � 1996-7 Michael TraversPart of the Behave! systemSend questions, comments, and fixes to mt@media.mit.edu.###################################################################### |#(defclass* proto-block (ccl::a-view) ());(defclass* colored-sheet (ccl::sheet-view colored-background-mixin) ();  (:default-initargs :background-color (make-gray 100)))(defclass* behave-aview (ccl::a-view colored-background-mixin expand-container-mixin) ()  (:default-initargs    :background-color (make-gray 100)    :border 0));;; not working, crashes brutally.(defclass* expander-sheet-view (ccl::sheet-view expand-container-mixin) ()  (:default-initargs    :border 0))                        ; this better be 0 or you get an ever-expanding window!(defclass* behave-window (ccl::sheet-window)  ((world :initarg :world :accessor world)   (background-view))  (:default-initargs     :window-do-first-click t;    :sheet-class 'expander-sheet-view    ));;; don't draw resize box during drags(defmethod window-draw-grow-icon ((w behave-window))  (unless (mouse-down-p)    (call-next-method)    ));;; and draw it OVER the background instead of under!(defmethod view-draw-contents :after ((w behave-window))    (window-draw-grow-icon w))(defvar *win* nil)(defmethod* initialize-instance :after ((w behave-window) &rest ignore)  (setf *win* (elt (view-subviews w) 0))   ; *win* is sheet  ;; comment out to flush background view  (setf *win*        (setf background-view (make-instance 'behave-aview                                :view-size view-size                                :view-position #@(0 0)                                :view-container *win*))))(defmethod* set-view-size :after ((w behave-window) h &optional v)  (declare (ignore h v))  (unless (= view-size (view-size background-view))    (set-view-size background-view view-size)))(defun make-win ()  (make-instance 'behave-window    :window-title "Behave!" :color-p t))(defun kill-win ()  (when *win*    (window-close (view-window *win*))))    