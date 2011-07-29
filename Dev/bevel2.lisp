(in-package :beh);;; beveled blocks with holes done right.(defclass depressions-for-subviews-mixin (beveled-rect-view-mixin)  ())(defmethod* view-draw-contents :after ((v depressions-for-subviews-mixin))  (dosequence (sv (view-subviews v))    (when (typep sv 'basic-block)       ; prob wrong test      (let* ((topleft (view-position sv))             (botright (add-points topleft (view-size sv))))        (beveled-frame (point-v topleft) (point-h topleft)                       (point-v botright) (point-h botright)                       (- bevel-border)                       (color v)                       *standard-delta-v*)))));;; this is a function for the contained views. Invalidate container on move or grow(defmethod set-view-position :after ((v depressions-for-subviews-mixin) hx &optional vx)  (declare (ignore hx vx))  (awhen (view-container v)    (invalidate-view it)))(defmethod set-view-size :after ((v depressions-for-subviews-mixin) hx &optional vx)  (declare (ignore hx vx))  (awhen (view-container v)    (invalidate-view it)))(defclass basic-block (proto-block highlight-target-mixin depressions-for-subviews-mixin beveled-rect-view-mixin drag-mixin drag-and-drop-mixin expand-container-mixin gesture-handling-mixin)  ((text :initarg :text))  (:default-initargs :border  *standard-border*))(defmethod* set-view-container :before ((v block) container)  )