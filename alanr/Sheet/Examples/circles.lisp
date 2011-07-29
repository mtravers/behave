(in-package :ccl)(defclass click-move-drag ()  ())(defmethod view-click-event-handler ((v click-move-drag) where)  (declare (ignore where))  (loop with initialpos = (view-position v)        with initialmouse = (view-mouse-position (view-container v))        for mouse = (view-mouse-position (view-container v))        for pos = (add-points initialpos (subtract-points mouse initialmouse))        do         (set-view-position v pos)        (let ((w (view-window v)))          (and w (window-update-event-handler w)))        until (not (mouse-down-p))));; transparent example. Subtractive color. Drag the three;; circles around and look at their intersections. You will;; see the color that is arrived at by subtracting their colors from;; white.(defclass colored-circle (click-move-drag sheet-view)  ((color :initarg :color :initform nil :accessor color))  (:default-initargs :depth 8 :view-size #@(100 100)))(defmethod initialize-instance ((v colored-circle) &key)  (call-next-method)  (with-focused-view v    (#_paintrect (rect (view-size v)))    (with-fore-color (color v)      (#_paintoval (rect (view-size v))))))(defmethod copybits-mode ((v colored-circle))  #$subpin)(defun test-circles ()  (make-instance 'a-window     :view-size #@(200 200)    :view-subviews     (list    (make-instance 'sheet-view :depth 8 :view-size #@(200 200)                   :view-subviews                   (list                    (make-instance 'colored-circle :color (make-color 65535 0 0)                                    :view-position #@(7 24))                    (make-instance 'colored-circle :color (make-color 0 65535 0)                                    :view-position #@(75 24))                    (make-instance 'colored-circle :color (make-color 0 0 65535)                                    :view-position #@(40 75)))))))  