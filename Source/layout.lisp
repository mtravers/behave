(in-package :beh)#| ######################################################################Block layoutCopyright � 1996-7 Michael Travers Part of the Behave! systemSend questions, comments, and fixes to mt@media.mit.edu.------outstanding problems:- switch in agent block is in wrong place- number constants- tabbing, etc.- see +++;;; Form layout specificationblock-spec:= keyword, nonkeyword, or list  keywords are noise text  nonkeywords are arguments  lists are(block-spec [options]*), ie (when :rtab 30))line-spec = list of block-specswhole-spec = list of line-specs###################################################################### |#;;; assumes subblocks are all sized correctly(defmethod layout-block ((block form-block) &optional (layout-spec (get-layout (form block))))  (if (prim-block? block)    (layout-prim-block block)           ; use different method for simple blocks    (let ((y *spacing*))      (dolist (row layout-spec)        (setf y (+ *spacing* (layout-row block row y))))      )));;; shrink wrap has to happen after all the layout, hence this is an :around(defmethod layout-block :around ((block form-block) &optional layout-spec)  (declare (ignore layout-spec))  (call-next-method)  (unless (prim-block? block)    (shrink-wrap block *spacing*)));;; T if no args(defmethod prim-block? ((block form-block))  (= 1 (length (view-subviews block)) ))       ;;; less spacing is needed for primitives(defmethod layout-prim-block ((block form-block))  (let ((text-view (aref (view-subviews block) 0))        (half-spacing (round *spacing* 2)))    (set-view-position text-view (make-point half-spacing half-spacing))    (shrink-wrap block half-spacing)));;; same for arg blocks(defmethod layout-block ((block arg-block) &optional ignore)  (let ((text-view (aref (view-subviews block) 0))        (half-spacing (round *spacing* 2)))    (set-view-position text-view (make-point half-spacing half-spacing))    (shrink-wrap block half-spacing)))(defmethod layout-block ((block layout-block) &optional layout-spec)  (declare (ignore layout-spec)));;; return single block or list for multiargs(defmethod find-blocks-from-spec ((container layout-block) spec)  (let* ((name (keyword (if (listp spec) (car spec) spec)))         (result nil))    (dosequence (sv (view-subviews container))      (when (and (typep sv 'layout-block)                 (eq (tag sv) name))        (push sv result)))    (case  (length result)      (0 (error "no block named ~A in ~A" name container))      (1 (car result))      (t (stable-sort (nreverse result) #'< :key #'(lambda (b) (if (typep b 'arg-block) 1 0)))))));;; tag management(defmethod* create-subviews ((block form-block))  (dolist (arg (args form))    (make-instance 'arg-block      :view-container block      :arg arg      :tag (keyword (car arg))      :view-font (view-font block)      :color (type-color (cadr arg))))  (dolist (row (get-layout form))    (dolist (item row)      (let ((name (if (listp item) (car item) item)))        (when (keywordp name)          (make-instance 'block-text-subview            :tag name            :text (sym-string name)            :text-color (default-text-color block)            :view-container block            :view-font (view-font block)))))))(defmethod layout-row ((container layout-block) row-spec top)  (flet ((find-block (spec)           (find-blocks-from-spec container spec)))    (let ((blocks (mapcar #'find-block row-spec)))      (prog1        (position-row container blocks top row-spec)        ;; non-general kludge for multi args        (when (and (second blocks) (listp (second blocks)))          (let* ((text-block (first blocks))                 (top-form-block (first (second blocks)))                 (inner-text-block  (find-view top-form-block #'(lambda (v) (typep v 'block-text-subview))))                 (text-pos (point-v (view-position-relative inner-text-block container))))            (set-view-position text-block (make-point (point-h (view-position text-block))                                                      text-pos)))))))); +++ to utils(defun sum (list &key (key #'identity))  (apply #'+ (mapcar key list)))(defmethod position-row ((block layout-block) row-views top &optional (row-spec (make-list (length row-views))))  (let ((row-height (maximize row-views                              :key #'(lambda (v)                                        (if (listp v)                                         (sum v :key #'(lambda (vv)                                                          (+ *spacing*                                                            (point-v (view-size vv)))))                                         (point-v (view-size v))))                              :return-max t) )        (x *spacing*))    (mapcar #'(lambda (block spec)                (if (listp block)                  (let ((y top)                        (max-width 0))                    (dolist (iblock block)                      (set-view-position iblock (make-point x y))                      (incf y (+ (point-v (view-size iblock)) *spacing*))                      (setf max-width (max max-width (point-h (view-size iblock)))))                    (setf x (+ *spacing* max-width)))                  (setf x (+ *spacing* (position-subblock block spec top x row-height)))))            row-views            row-spec)    (values (+ top row-height))))(defmethod position-subblock ((block layout-block) spec top left row-height)  (set-view-position block (make-point left (+ top                                               (round (- row-height (point-v (view-size block)))                                                      2))))  (values (+ left (point-h (view-size block)))))(defmethod shrink-wrap ((v layout-block) border)  (let ((svs (coerce (view-subviews v) 'list)))    (set-view-size      v     (if svs       (add-points (bounding-size (coerce (view-subviews v) 'list))                   (make-point border border))       (view-default-size v)))));;; Invocation(defmethod drop :after ((block layout-block))  (aif (view-container block)       (call-if #'relayout it)));;; called when something changes (ie a drop or raise)(defmethod* relayout ((block layout-block))  (setf needs-layout? t)  (if (layout-top? block)    (layout-block-recursive block)    (relayout (view-container block))))(defmethod* layout-block-recursive ((block layout-block))  (dosequence (sv (view-subviews block))    (call-if #'layout-block-recursive sv))  (when needs-layout?    (layout-block block)    (setf needs-layout? nil)))(defmethod layout-top? ((block form-block))  (not (typep (view-container block) 'form-block)));;; Form interface(defmethod* get-layout ((form form))  (or layout      (let ((new-name (if (numberp name)                        (princ-to-string name)                        name)))        (list (cons (keyword new-name) (mapcar #'car args))))))