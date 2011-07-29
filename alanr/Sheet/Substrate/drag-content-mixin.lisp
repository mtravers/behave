;-*- Mode: Lisp; Package: CCL -*-(in-package :ccl)(defclass drag-content-mixin () ())(defconstant $dragpattern #xa34)(deftrap _dragthergn ((thergn (:handle :region)) (startpt :point) (boundsrect :rect) (sloprect :rect) (axis :signed-integer) (actionproc :pointer))   (:stack :signed-long)   (:stack-trap #xA926))(defvar *drag-content-dragging-view* nil)(defpascal call-drag-content-action-function ()  (and *drag-content-dragging-view*        (view-get *drag-content-dragging-view* :dragging-function)       (funcall (view-get *drag-content-dragging-view* :dragging-function)                *drag-content-dragging-view*)))(defmethod drag-content ((v drag-content-mixin) &optional action-function bounds constraint (gray? t) )  (view-put v :dragging-function action-function)  (with-temp-gworld ((point-h (view-size v)) (point-v (view-size v)) 1 gw)    ;; alanr Friday December 15,1995 use offscreen.lisp    (with-sheets-focused-gworld (gw)      (view-draw-content-to-drag v))    (let ((region (make-region nil)))      (with-pixmap (bitmap gw)        (#_bitmaptoregion region bitmap))      (let ((start (add-points (view-position (view-window v))                               (convert-coordinates (view-mouse-position v) v                                                    (view-window v)))))        (#_offsetrgn :ptr region :long (add-points (view-position (view-window v))                                              (convert-coordinates #@(0 0) v                                                                   (view-window v))))        ;; make it drag in black        (unless gray?          (copy-record *white-pattern* (:pattern :storage :pointer) (%int-to-ptr $dragpattern)))        (setq constraint (case constraint (:vertical 2) (:horizontal 1) (otherwise 0)))        (flet ((drag ()                 (let ((grayregion (#_getgrayrgn)))                   (let ((rect (region-rect grayregion)))                     (#_cliprect rect)                     (let ((*drag-content-dragging-view* v))                       (if gray?                         (#_draggrayrgn region start rect rect constraint call-drag-content-action-function)                         (#_dragthergn region start rect rect constraint call-drag-content-action-function)                         ))))))          (if (typep bounds 'view)            (with-focused-view bounds (drag))            (with-focused-view *desktop*              (drag)))          (#_disposergn region))))))  (defmethod view-draw-content-to-drag ((v drag-content-mixin))  (view-draw-contents v))            