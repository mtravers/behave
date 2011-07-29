(def-beh-type 'species (hsv-to-color 0 0 .8))(defform (fish species :block-class species-block) (agent)  )(defclass species-block (form-block)  ((species :initarg :species))  (:default-initargs     :view-font (append *default-block-font* '(:outline))    :color (make-gray 175)    ))         ;;;; reorganized drop;;; +++ cutouts(defmethod drop ((block agent-block))  (call-next-method));;; this rather than an :after method because we have to rearrange the view hierarchy before layout is called(defmethod drop ((block form-block));  (call-next-method)  (let ((hole (drop-target block)))    (when hole      (fill-argument-block* (view-container hole) hole block))    ))(defmethod fill-argument-block* ((container form-block) (arg arg-block) (filler form-block))  (setf (actual arg) filler)  (sound-play-async *drop-in-sound*)  (set-view-position filler (view-position arg))  (set-view-container filler container)  ;; get rid of arg block, but save it   (set-view-container arg nil)  (setf (tag filler) (tag arg))  (push (cons filler arg) (slot-value container 'saved-holes))  (invalidate-view container t)     ; shouldn't be necessary  (block-changed filler)  )(defmethod drop :after ((block agent-block))  )                                     ; +++ set species slot in some way; +++ cutout some existing methods (temp)(defmethod* initialize-instance :after ((block species-block) &rest ignore)  )(defmethod can-drop? ((block agent-block) (target species-block))  (call-next-method)); +++ see if we can avoid making this a primary method(defmethod* drop ((block agent-block))  (call-next-method))#|(generate-block  (defform (fish species :block-class species-block) (agent)   ))|#;;; Extend layout to have picts and multi-args(defmethod layout-block ((block species-block) &optional ignore)  (flet ((find-block (type)           (dosequence (sv (view-subviews block))             (when (typep sv type)               (return sv))))         (list-nonnull (&rest args)           (filter #'identity args)))    (let* ((name-block (find-block 'block-text-subview))           (pict-block (find-block 'block-pict-subview))           (arg-block (find-block 'arg-block))           (agent-blocks (nset-difference (coerce (view-subviews block) 'list)                                          (list-nonnull name-block pict-block arg-block)))           (y *spacing*))      (setf y (+ *spacing* (position-row block (list-nonnull name-block pict-block) y)))      (dolist (agent-block agent-blocks)        (setf y (+ *spacing* (position-row block (list agent-block) y))))      (position-row block (list arg-block) y))    (shrink-wrap block *spacing*)))      ;;;; sort of a crock...retrieve the hole and use it again(defmethod fill-argument-block* :after ((container species-block) (arg arg-block) (filler form-block))  (set-view-container arg container)  (relayout container));;; +++ cutout(defmethod relayout ((block species-block))       (call-next-method))(defun make-species-block (name &optional pict)  (let ((sb (generate-block             (defform-1 name 'species '(agent) 'nil 'species-block 'nil)               )))    (when pict      (make-instance 'block-pict-subview        :view-container sb        :pict pict))    (layout-block sb)    (find-position sb)    sb))