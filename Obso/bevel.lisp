(in-package :beh);;; system definition is wrong (from ccl:interfaces;colorpicker.lisp)(defrecord HSVColor    (hue :unsigned-word)                        ; Fraction of circle, red at 0   (saturation :unsigned-word)                 ; 0-1, 0 for gray, 1 for pure color   (value :unsigned-word)                      ; 0-1, 0 for black, 1 for max intensity   );;; from LiveWorld(defun beveled-frame-1 (top left bottom right border-width topleft-color bottomright-color)  (with-rgb (tlc (if (plusp border-width) topleft-color bottomright-color))    (with-rgb (brc (if (plusp border-width) bottomright-color topleft-color))      (rlet ((oldc :rgbcolor))        (#_GetForeColor oldc)        (dotimes (n (abs border-width))          (decf& bottom)          (decf& right)          (#_rgbForeColor tlc)          (#_MoveTo left bottom)          (#_LineTo left top)          (#_LineTo right top)          (#_rgbForeColor brc)          (#_LineTo right bottom)          (#_LineTo left bottom)          (incf& top)          (incf& left))        (#_rgbForeColor oldc)))))(defun beveled-frame (top left bottom right border-width color delta-v)  (beveled-frame-1 top left bottom right border-width (color+lightness color delta-v) (color+lightness color (-  delta-v))))(defun beveled-rect (top left bottom right border-width color delta-v)  (flat-rect top left bottom right color)  (beveled-frame top left bottom right border-width color delta-v))(defun flat-rect (top left bottom right color)  (with-rect (r left top right bottom)    (with-rgb (c color)      (#_rgbForeColor c)      (#_PaintRect r ))))(defun color+lightness (color change)  (multiple-value-bind (h s v)                       (color-to-hsv color)    (hsv-to-color h s (max 0.0 (min 1.0 (+ v change))))))  ;;; these are from Alan(defun hsv-to-color (hue saturation value)  (setq hue (round (* hue 65535))        saturation (round (* saturation 65535))        value (round (* value 65535)))  (rlet ((hsv-var :hsvcolor :hue hue :saturation saturation :value value )         (rgb-var :rgbcolor ))    (#_hsv2rgb hsv-var rgb-var)    (rgb-to-color rgb-var)))(defun color-to-hsv (color)  (rlet ((hsv-var :hsvcolor)         (rgb-var :rgbcolor :red (color-red color) :blue (color-blue color)                  :green (color-green color)))    (#_rgb2hsv rgb-var hsv-var)    (values (/ (rref hsv-var :hsvcolor.hue) 65535.0)            (/ (rref hsv-var :hsvcolor.saturation) 65535.0)            (/ (rref hsv-var :hsvcolor.value) 65535.0))))#|(defun hsl-to-color (hue saturation value)  (setq hue (round (* hue 65535))        saturation (round (* saturation 65535))        value (round (* value 65535)))  (rlet ((hsl-var :rgbcolor :red hue :green saturation :blue value )         (rgb-var :rgbcolor ))    (#_hsl2rgb hsl-var rgb-var)    (rgb-to-color rgb-var)))(defun color-to-hsl (color)  (rlet ((hsl-var :rgbcolor)         (rgb-var :rgbcolor :red (color-red color) :blue (color-blue color)                  :green (color-green color)))    (#_rgb2hsl rgb-var hsl-var)    (values (/ (rref hsl-var rgbcolor.red) 65535.0)            (/ (rref hsl-var rgbcolor.blue) 65535.0)            (/ (rref hsl-var rgbcolor.green) 65535.0))))|#;;; Some classes that make use of the above(defparameter *standard-border* 4)      ; these should be slots, I suppose(defparameter *standard-delta-v* .2)(defclass beveled-rect-view-mixin (simple-view)  ((color :initarg :color :initform *gray-color* :accessor color)   (bevel-border :initform *standard-border*)))(defmethod* view-draw-contents :before ((v beveled-rect-view-mixin))  (let* ((topleft (view-position v))         (botright (add-points topleft (view-size v))))    (beveled-rect (point-v topleft) (point-h topleft)                  (point-v botright) (point-h botright)                  bevel-border                  color                  *standard-delta-v*)));;; new, based on view instead of simple-view(defclass beveled-rect-view-mixin (view)  ((color :initarg :color :initform *gray-color* :accessor color)   (bevel-border :initform *standard-border*)))(defmethod* view-draw-contents :before ((v beveled-rect-view-mixin))  (let* ((topleft #@(0 0))         (botright (add-points topleft (view-size v))))    (beveled-rect (point-v topleft) (point-h topleft)                  (point-v botright) (point-h botright)                  bevel-border                  color                  *standard-delta-v*)));;; draw a hole as well(defclass beveled-indent-rect-view-mixin (beveled-rect-view-mixin)  ((bevel-border :initform (* 2 *standard-border*) :initarg :bevel-border)))(defmethod view-draw-contents :after ((v beveled-indent-rect-view-mixin))  (when (typep (view-container v) 'beveled-rect-view-mixin)    (let* ((container-color (color (view-container v)))           (topleft #@(0 0))           (botright (add-points topleft (view-size v))))      (beveled-frame  (point-v topleft) (point-h topleft)                      (point-v botright) (point-h botright)                      (- *standard-border*)                      container-color                      *standard-delta-v*))))#|(defclass text-mixin (simple-view)   ((text :initarg :text :initform nil)   (text-color :initarg :text-color :initform 0)))(defmethod* raw-set-font ((v simple-view) font)  (multiple-value-bind (ff ms) (font-codes font)    (when ff      (set-wptr-font-codes wptr ff ms))))(defmethod* view-draw-contents :after ((v text-mixin))  (when text    (with-rgb (c text-color)      (#_rgbForeColor c))    (raw-set-font v (view-font v))          (#_MoveTo 6 (+ 6 (font-info (view-font v))))      ; +++ inefficient to call view-font a lot, offset should be param somewhere    (with-pstrs ((ps text))      (#_DrawString ps))))|#(defclass proto-block (view) ())        ; redefined for sheets; +++ text-view is not quite right, we need a subview to get an offset...argh.(defclass basic-block (proto-block beveled-indent-rect-view-mixin drag-mixin text-view expand-container-mixin gesture-handling-mixin)  ()  (:default-initargs :border (* 3 *standard-border*)))(defmethod drag :before ((v basic-block) &optional where)  (declare (ignore where))  (set-view-level v 0));;; blocks indicate functions or constants(defclass block  (basic-block) ()  (:default-initargs     :view-font '("Tekton" 24 :bold)))(defmethod* set-view-container :before ((v block) container)  (if (typep container 'beveled-rect-view-mixin)    (setf bevel-border (* 2 *standard-border*))    (setf bevel-border *standard-border*)));;; holes indicate parameters;;; same as block, but with different border and font(defclass hole (basic-block) ()  (:default-initargs     :view-font `("Tekton" 24 :bold)    :bevel-border 0    :text-color *white-color*));;; Commands for layout experiments(defmethod* command-click ((v basic-block) ignore)  (setf text (get-string-from-user "New string"))  (invalidate-view v))(defmethod* command-shift-click ((v basic-block) ignore)  (setf color (user-pick-color :color color))  (invalidate-view v))(defmethod* command-option-click ((v basic-block) ignore)  (inspect v)); +++ use these instead of text-mixin(defclass text-block (proto-block drag-mixin gesture-handling-mixin text-view)          ; ordered to allow clicks to work  ()  (:default-initargs     :view-font '("Tekton" 24 :bold)))#|  for debugging(defmethod view-draw-contents :before ((v text-block))  (with-rect (r 0 (view-size v))    (#_Framerect r)))|#  #|(setf w (make-instance 'window :window-title "Bevel Test" :color-p t))(make-instance 'block :view-container w :view-position #@(300 100) :view-size #@(100 50))(defun make-block (container name hue &optional (type 'block))  (make-instance type    :view-container container    :view-position #@(20 20)    :color (hsv-to-color hue .5 .7)    :text name))(defun make-structure (struct container)  (let ((block (make-block container (car struct) (cadr struct))))    (awhen (caddr struct)      (make-structure it block))))(make-structure '("go" .2 ("towards" .3 ("a random" .9 ("fish"  .7)))) w)(make-block (make-block w "a random" .9)            "species" .7 'hole)(make-block w "fish" .7)(make-instance 'text-block :view-container w :text "butterfly")|##|;;; sample tiles(dotimes (n 20)  (with-focused-view w    (beveled-rect 20 (* n 30) 50 (* (+ 1 n) 30) 4 (hsv-to-color (* n .05) .6 .8) .2)))(defun sample-tiles (&optional (ntiles 20) (saturation .6) (base-value .8) (delta-value .2))  (dotimes (n ntiles)    (with-focused-view w      (beveled-rect 20 (* n 30) 50 (* (+ 1 n) 30) 4 (hsv-to-color (/ n ntiles) saturation base-value) delta-value))))(sample-tiles); green with purple hole, purple borders (ech)(with-focused-view w  (beveled-rect 60 20 200 200 4 (hsv-to-color .3 .6 .8) .2)  (beveled-rect 80 50 120 150 -4 (hsv-to-color .7 .6 .8) .2));;; green with purple hole(with-focused-view w  (beveled-rect 60 20 200 200 4 (hsv-to-color .3 .6 .8) .2)  (beveled-rect 80 50 120 150 -4 (hsv-to-color .3 .6 .8) .2)  (flat-rect 84 54 116 146 (hsv-to-color .7 .6 .8))  );;; filled in(with-focused-view w  (beveled-rect 60 20 200 200 4 (hsv-to-color .3 .6 .8) .2)  (beveled-rect 80 50 120 150 -4 (hsv-to-color .3 .6 .8) .2)  (beveled-rect 84 54 116 146 4 (hsv-to-color .7 .6 .8) .2))|#