(in-package :ccl);; ****************************************************************;;;; Author: Alan Ruttenberg, MIT Media Lab;; email:  alanr@media.mit.edu;;;; Sunday August 27,1995 made repositioning code aware of frame, for fewer flashes;; Friday August 25,1995 alanr added optional frame-color, thumb-texture, thumb-texture-inset,;;   thumb-texture-fraction. frame-color, if non nil, specifies what color a 1 picel border;;   around the thumb should be. Line color is now optional. If nil, no line is drawn (hence;;   make the name line-scrollbar incorrect). Thumb texture is a ppat obtained by (#_getpixpat,;;   or a resource number for same. Thumb texture inset is distance from thumb texture to;;   thumb edge. thumb-texture-fraction is portion of thumb which is drawn with texture.;; Friday July 28,1995 thumb proportion gets clipped to maximum 1.0;; Wednesday July 26,1995: have scrollbar initargs get passed through to thumb initargs;; Sunday July 16,1995: Added ability to pop up a menu if you click on the thumb for;;  long enough. Parameters: popup? : allow this functionality;;  popup-delay time in ticks until menu is popped up.;;  popup-limit number of pixels inside which you must stay for popup;;  popup-function two arg function (arg1 = view, arg = click point, as proportion ;;   of horizontal scroll view) to call to pop up menu.;;;; Created: Thursday January 19,1995 : from cyberonline project;; ;; ****************************************************************;; needs to be mixed in with something that defines ;; line-color, background-color, and thumb-color.;; thumb-class should be a subclass of line-scrollbar-thumb that;;   defines thumb-color, thumb-width;; Interface ;; (set-scroll-position v new-position);;    new-position is a fraction 0 to 1;; (scroll-position-changed-action v) ;;    is called with the new position when the thumb moves.;; Discussion with golan;; Hot resize edges are always active if the thumb is big enough;; Wants arrows at edges Same blue outline thumb-color fill;; The size of the thumb is not strictly the proportion viewable, but something ;; like logarithmic so that differences in the size of small thumbs mean more.;; Option to draw or not draw the top or bottom thumb bounding line (to avoid;;   collision of window edge and thumb edge.;; option drag drags at a ten to one factor.;; Have an indication of where the scrub bar is when outside the current screen by;;   having a red line in the scroll bar (outside the thumb) so that you can easily aim ;;   and move the thumb to include the scrub bar.;; Maybe: have history of scroll and zoom settings. User gets to it either from an extra;;  undo entry (golan's idea), or by option clicking on the arrows (my idea).(defclass scrollbar-design ()  ((line-color :initarg :line-color :initform *blue-color* :accessor line-color :allocation :class)   (background-color :initarg :background-color :initform *white-color* :accessor background-color :allocation :class)   (thumb-width :initarg :thumb-width :initform 16 :accessor thumb-width :allocation :class)   (thumb-color :initarg :thumb-color :initform *white-color* :accessor thumb-color :allocation :class)   (thumb-inset :initarg :thumb-inset :initform 0 :accessor thumb-inset)   (smallest-thumb-size :initarg :smallest-thumb-size :initform 10 :accessor smallest-thumb-size)   (resize-hot-range :initarg :resize-hot-range :initform 4 :accessor resize-hot-range)   (frame-color :initarg :frame-color :initform nil :accessor frame-color)   (thumb-texture :initarg :thumb-texture :initform nil :accessor thumb-texture)   (thumb-texture-inset :initarg :thumb-texture-inset :initform nil :accessor thumb-texture-inset)   (thumb-texture-fraction :initarg :thumb-texture-fraction :initform nil :accessor thumb-texture-fraction))  (:default-initargs :allow-other-keys t))(defclass line-scrollbar (scrollbar-design view)  ((thumb-view :initarg :thumb-view :initform nil :accessor thumb-view)   (scroll-area-proportion :initarg :scroll-area-proportion :initform .25 :accessor scroll-area-proportion)   (scroll-position :initarg :scroll-position :initform .5 :accessor scroll-position)   (thumb-class :initarg :thumb-class :accessor thumb-class)   (scroll-position-changed-action :initarg :scroll-position-changed-action                                   :initform #'(lambda(pos) (print-db pos))                                   :accessor scroll-position-changed-action))  )(defmethod set-thumb-proportion ((v line-scrollbar) proportion);  (assert (<= 0 proportion 1) () "Proportion needs to be between 0 and 1")  (setq proportion (min 1 proportion))  (setf (scroll-area-proportion v) proportion)  (set-view-size (thumb-view v) (compute-thumb-size v))  ;; catch the case where you zoom enough so that everything is visible. Ensure it it  ;; by setting the scroll bar position to 0. Subtle.  (when (= proportion 1)    (set-scroll-position v 1)    (thumb-position-changed v))  (invalidate-view v nil))(defmethod initialize-instance ((v line-scrollbar) &rest args)  (declare (dynamic-extent args))  (call-next-method)  (set-view-size v (compute-view-size v))  (let ((thumb (apply #'make-instance (thumb-class v)                       :view-size (compute-thumb-size v) args)))    (setf (thumb-view v) thumb)    (add-subviews v thumb)    (set-scroll-position v (scroll-position v))))(defmethod set-scroll-bar-length ((v line-scrollbar) length)  (if (horizontal? v)    (set-view-size v (@! length (@v (view-size v))))    (set-view-size v (@! (@h (view-size v)) length))))(defmethod scroll-bar-width ((v line-scrollbar))  (if (horizontal? v)    (@v (view-size v))    (@h (view-size v))))(defmethod thumb-fraction ((v line-scrollbar))  (/ (if (horizontal? v)        (@h (view-size (thumb-view v)))       (@v (view-size (thumb-view v))))     (if (horizontal? v)        (@h (view-size v))       (@v (view-size v)))));; ****************************************************************(defclass vertical-line-scrollbar (line-scrollbar) ()  (:default-initargs :thumb-class 'vertical-line-scrollbar-thumb))(defmethod vertical? ((v vertical-line-scrollbar)) t)(defmethod horizontal? ((v vertical-line-scrollbar)) nil)(defmethod compute-thumb-size ((v vertical-line-scrollbar))  (@! (thumb-width v) (max (smallest-thumb-size v) (round (* (scroll-area-proportion v) (@v (view-size v)))))))(defmethod compute-view-size ((v vertical-line-scrollbar))  (@! (thumb-width v) (@v (view-size v))))(defmethod set-scroll-position ((v vertical-line-scrollbar)  new-position)  (setf (scroll-position v) new-position)  (with-accessor-values (thumb-view view-size) v    (let ((new-position            (max 0 (round (* new-position (- (@v view-size) (@v (view-size (thumb-view v)))))))))      (set-view-position thumb-view 0 new-position))))(defmethod view-draw-contents ((v vertical-line-scrollbar))  (let* ((thumb-start (@v (view-position (thumb-view v))))         (thumb-end (+ thumb-start (@v (view-size (thumb-view v)))))         (width (@h (view-size v)))         (height (@v (view-size v))))    (with-fore-color (background-color v)      (#_paintrect (rect 0 0 thumb-start width))      (#_paintrect (rect thumb-end 0 height width)))    (let ((h (floor (thumb-width v) 2)))      (when (line-color v)        (with-fore-color (line-color v)          (#_moveto h 0)          (#_lineto h thumb-start)          (#_moveto h thumb-end)          (#_lineto h height))))    (call-next-method)    (when (frame-color v)      (with-fore-color (frame-color v)        (#_framerect (rect (view-size v)))))));; 1/5/96 Added by BW scrolls by half a page if user clicks in bar not;; on thumb(defmethod view-click-event-handler ((view vertical-line-scrollbar) where)  (if (eq (find-clicked-subview view where) view)    (let* ((clicked-v (point-v where))           (thumb (thumb-view view))           (thumb-top (point-v (view-position thumb)))           (thumb-size (point-v (view-size thumb)))           (thumb-bottom (+ thumb-top                            thumb-size))           (new-thumb-position (if (> clicked-v thumb-bottom)                                 (+ thumb-top (floor thumb-size 2))                                 (- thumb-top (floor thumb-size 2)))))      (reposition-thumb thumb (max 0 (min (- (point-v (view-size view))                                             thumb-size)                                          new-thumb-position))))    (call-next-method)));; ****************************************************************(defclass horizontal-line-scrollbar (line-scrollbar)  ()  (:default-initargs :thumb-class 'horizontal-line-scrollbar-thumb))(defmethod vertical? ((v horizontal-line-scrollbar)) nil)(defmethod horizontal? ((v horizontal-line-scrollbar)) t)(defmethod set-scroll-position ((v horizontal-line-scrollbar)  new-position)  (setf (scroll-position v) new-position)  (with-accessor-values (thumb-view view-size) v    (let ((new-position            (max 0 (round (* new-position (- (@h view-size) (@h (view-size (thumb-view v)))))))))      (set-view-position thumb-view new-position 0))))(defmethod compute-view-size ((v horizontal-line-scrollbar))  (@! (@h (view-size v)) (thumb-width v)))(defmethod compute-thumb-size ((v horizontal-line-scrollbar))  (@! (max (smallest-thumb-size v) (round (* (scroll-area-proportion v) (@h (view-size v))))) (thumb-width v)))(defmethod view-draw-contents ((v horizontal-line-scrollbar))  (let* ((thumb-start (@h (view-position (thumb-view v))))         (thumb-end (+ thumb-start (@h (view-size (thumb-view v)))))         (width (@h (view-size v)))         (height (@v (view-size v))))    (with-fore-color (background-color v)      (#_paintrect (rect 0 0 height thumb-start))      (#_paintrect (rect 0 thumb-end height width))      )    (let ((vv (floor (thumb-width v) 2)))      (when (line-color v)        (with-fore-color (line-color v)          (#_moveto 0 vv)          (#_lineto thumb-start vv)          (#_moveto thumb-end vv)          (#_lineto width vv)))))    (call-next-method)    (when (frame-color v)      (with-fore-color (frame-color v)      (#_framerect (rect (view-size v))))));; 1/5/96 Added by BW scrolls by half a page if user clicks in bar not;; on thumb(defmethod view-click-event-handler ((view horizontal-line-scrollbar) where)  (if (eq (find-clicked-subview view where) view)    (let* ((clicked-h (point-h where))           (thumb (thumb-view view))           (thumb-left (point-h (view-position thumb)))           (thumb-size (point-h (view-size thumb)))           (thumb-right (+ thumb-left                            thumb-size))           (new-thumb-position (if (> clicked-h thumb-right)                                 (+ thumb-left (floor thumb-size 2))                                 (- thumb-left (floor thumb-size 2)))))      (reposition-thumb thumb (max 0 (min (- (point-h (view-size view))                                             thumb-size)                                          new-thumb-position))))    (call-next-method)));;****************************************************************(defclass line-scrollbar-thumb (view scrollbar-design)    ((popup? :initarg :popup? :initform t :accessor popup?)   (popup-limit :initarg :popup-limit :initform 10 :accessor popup-limit)   (popup-delay :initarg :popup-delay :initform 40 :accessor popup-delay)   (popup-function :initarg :popup-function :initform nil :accessor popup-function)   ))(defmethod initialize-instance ((v line-scrollbar-thumb) &rest args &key thumb-texture)  (if thumb-texture    (unless (macptrp thumb-texture)       (apply #'call-next-method v :thumb-texture (#_getpixpat thumb-texture) args))    (call-next-method)))(defmethod vertical? ((v line-scrollbar-thumb)) (vertical? (view-container v)))(defmethod horizontal? ((v line-scrollbar-thumb)) (horizontal? (view-container v)))(defmethod view-draw-contents ((v line-scrollbar-thumb))  (let ((rect (rect (view-size v))))    (#_insetrect rect      (+ (if (frame-color v) 1 0) (if (horizontal? v) 0 (thumb-inset v)))     (+ (if (frame-color v) 1 0) (if (horizontal? v) (thumb-inset v) 0)))    (with-fore-color (thumb-color v)      (#_paintrect rect))    (when (line-color v)      (with-fore-color (line-color v)        (#_framerect rect))))  (call-next-method)  (when (thumb-texture v)    (let* ((no-texture-inset (floor (* (- 1 (thumb-texture-fraction v)) 	                                       (if (horizontal? v)                                         (@h (view-size v))                                         (@v (view-size v)))) 2))           (texture-rect             (if (horizontal? v)              (rect (thumb-texture-inset v)                    no-texture-inset                    (- (@v (view-size v)) (thumb-texture-inset v))                    (- (@h (view-size v)) no-texture-inset))              (rect no-texture-inset                    (thumb-texture-inset v)                    (- (@v (view-size v)) no-texture-inset)                    (- (@h (view-size v)) (thumb-texture-inset v))))))      (with-pen-saved         (#_penpixpat (thumb-texture v))        (#_paintrect texture-rect))))  (when (frame-color v)    (with-fore-color (frame-color v)      (#_framerect (rect (view-size v))))))(defmethod thumb-position-changed ((v line-scrollbar))  (funcall (scroll-position-changed-action v) (fractional-position v)))(defmethod view-click-event-handler :around ((v line-scrollbar-thumb) where)  (if (and (popup? v) (popup-function v))    (unless (popup-delay-view-click-event-handler v where)      (call-next-method))    (call-next-method)));; return t if the click was handled, nil if you want the regular view-click-event-handler.(defmethod popup-delay-view-click-event-handler ((v line-scrollbar-thumb) where)  (flet ((do-popup? (delta-h delta-t)            (and (mouse-down-p)                (< delta-t (popup-delay v))                (< delta-h (popup-limit v)))))    (loop with start-t = (#_tickcount)          for delta-t = (- (#_tickcount) start-t)          for current-h = (if (horizontal? v) (@h (view-mouse-position v)) (@v (view-mouse-position v)))          for delta-h = (abs (- (if (horizontal? v) (@h where)  (@v where)) current-h))          while (do-popup? delta-h delta-t)          do (sleep .01)          finally          do          ;; subtle point here. The last check shouldn't check the time, since if we are not           ;; going to popup we have passed the time anyways.          (if (and (mouse-down-p) (< delta-h (popup-limit v)) (popup-function v))            (progn (funcall (popup-function v) v                             (if (horizontal? v)                              (/ (@h where) (@h (view-size v)))                              (/ (@v where) (@v (view-size v))))) t)            nil))))(defmethod view-click-event-handler ((v line-scrollbar-thumb) where)  (let* ((component (if (horizontal? v) #'point-h #'point-v))         (vc (view-container v))         (startmouse (funcall component (view-mouse-position vc)))         (startpos (funcall component (view-position v)))         (resize-range (resize-hot-range v)))    (if (or (< (funcall component where) resize-range)            (> (funcall component where) (- (funcall component (view-size v)) resize-range)))      (click-to-resize-event-handler v where)      (loop for last = startpos then new            with option-magnifier = 10            with min = 0            with max = (- (funcall component (view-size vc))                          (funcall component (view-size v)))            for current = (funcall component (view-mouse-position vc))            for diff = (if (option-key-p) (floor (- current startmouse) option-magnifier) (- current startmouse))            for new = (max (min (+ startpos diff) max) min)            until (not (mouse-down-p))            do            (when (not (= new last))              (when (<= min new max)                (reposition-thumb v new)                ))            (let ((view-window (view-window v)))              (and view-window (window-update-event-handler view-window)))))))(defmethod click-to-resize-event-handler ((v line-scrollbar-thumb) where)  (declare (ignore where))  (let* ((component (if (horizontal? v) #'point-h #'point-v))         (vc (view-container v))         (startmouse (funcall component (view-mouse-position vc)))         (startpos (funcall component (view-position v))))    (loop for last = startpos then new          with option-magnifier = 10          with min = 0          with max = (- (funcall component (view-size vc))                        (funcall component (view-size v)))          for current = (funcall component (view-mouse-position vc))          for diff = (if (option-key-p) (floor (- current startmouse) option-magnifier) (- current startmouse))          for new = (max (min (+ startpos diff) max) min)          until (not (mouse-down-p))          do          (when (not (= new last))            (when (<= min new max)              (reposition-thumb v new)              ))          (let ((view-window (view-window v)))            (and view-window (window-update-event-handler view-window))))))(defmethod view-cursor ((v line-scrollbar-thumb) where)  (let* ((component (if (horizontal? v) #'point-h #'point-v))         (left (resize-hot-range v))         (right (- (funcall component (view-size v)) (resize-hot-range v))))    (if (or (< (funcall component where) left)            (> (funcall component where) right))      (get-resource :curs "move side to side")      (call-next-method))));; ****************************************************************(defclass vertical-line-scrollbar-thumb (line-scrollbar-thumb) ())(defmethod reposition-thumb ((v vertical-line-scrollbar-thumb) new)   (let ((vsize (@v (view-size v)))        (current-start (@v (view-position v))))    (when (/= new current-start)      (without-interrupts        (set-view-position v (make-point 0 new))       (validate-view v)       (let ((frame-inset (if (frame-color v) 1 0)))         (with-focused-view (view-container v)           (invalidate-corners             (view-container v)            (@! frame-inset (min current-start new))            (@! (- (@h (view-size v)) frame-inset) (+ (max current-start new) vsize)))           nil)))      (let ((view-window (view-window v)))        (and view-window (window-update-event-handler view-window)))      (thumb-position-changed (view-container v)))))(defmethod fractional-position ((v vertical-line-scrollbar))  (/ (@v (view-position (thumb-view v)))     (@v (view-size v))));****************************************************************(defclass horizontal-line-scrollbar-thumb (line-scrollbar-thumb) ())(defmethod reposition-thumb ((v horizontal-line-scrollbar-thumb) new)   (let ((hsize (@h (view-size v)))        (current-start (@h (view-position v))))    (when (/= new current-start)      (without-interrupts       (let ((frame-inset (if (frame-color v) 1 0)))         (set-view-position v (make-point new 0))         (validate-view v)         (with-focused-view (view-container v)           (invalidate-corners             (view-container v)            (@! (min current-start new) frame-inset)            (@! (+ (max current-start new) hsize) (- (@v (view-size v)) frame-inset))            nil))))      (let ((view-window (view-window v)))        (and view-window (window-update-event-handler view-window)))      (thumb-position-changed (view-container v)))))(defmethod fractional-position ((v horizontal-line-scrollbar))  (/ (@h (view-position (thumb-view v)))     (@h (view-size v))))