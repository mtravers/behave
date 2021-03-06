(in-package :beh)

#| ######################################################################

Define the look (and part of the feel) of blocks

Copyright � 1996-7 Michael Travers 

Part of the Behave! system

Send questions, comments, and fixes to mt@media.mit.edu.

###################################################################### |#


;;; system definition is wrong (from ccl:interfaces;colorpicker.lisp)
(defrecord HSVColor 
   (hue :unsigned-word)                        ; Fraction of circle, red at 0
   (saturation :unsigned-word)                 ; 0-1, 0 for gray, 1 for pure color
   (value :unsigned-word)                      ; 0-1, 0 for black, 1 for max intensity
   )


#| older flat bevel
;;; from LiveWorld
(defun beveled-frame-1 (top left bottom right border-width topleft-color bottomright-color)
  (with-rgb (tlc (if (plusp border-width) topleft-color bottomright-color))
    (with-rgb (brc (if (plusp border-width) bottomright-color topleft-color))
      (when (minusp border-width)
        (setf bottom (- bottom border-width)
              right (- right border-width)
              top (+ top border-width)
              left (+ left border-width)))
      (rlet ((oldc :rgbcolor))
        (#_GetForeColor oldc)
        (dotimes (n (abs border-width))
          (decf& bottom)
          (decf& right)
          (#_rgbForeColor tlc)
          (#_PenSize 1 1)
          (#_MoveTo left bottom)
          (#_LineTo left top)
          (#_LineTo right top)
          (#_rgbForeColor brc)
          (#_LineTo right bottom)
          (#_LineTo left bottom)
          (incf& top)
          (incf& left))
        (#_rgbForeColor oldc)))))


(defun beveled-frame (top left bottom right border-width color delta-v)
  (unless (zerop border-width)
    (beveled-frame-1 top left bottom right border-width (color+lightness color delta-v) (color+lightness color (-  delta-v)))))

|#

;;; new -- smooth-shaded bevel
;;; this is about 6% of drawing time so it's trying (not very successfully) to b fast.
(defun beveled-frame (top left bottom right border-width color delta-v)
  (unless (zerop border-width)
    (let ((ddelta-v (* (/ delta-v border-width) 
                       (sign border-width)))
          color-delta)
      (when (minusp& border-width)
        (setf bottom (-& bottom border-width)
              right (-& right border-width)
              top (+& top border-width)
              left (+& left border-width)))
      (rlet ((tlc :rgbcolor)
             (brc :rgbcolor))
        (dotimes (n (abs border-width))
          (setf color-delta (* (if (plusp& border-width)
                                 (-& border-width n)
                                 (+& border-width n))
                               ddelta-v))
            (let ((tlcolor (color+lightness color color-delta)) 
                  (brcolor (color+lightness color (- color-delta))))
              (setf (rref tlc :rgbcolor.red) (color-red tlcolor))
              (setf (rref tlc :rgbcolor.green) (color-green tlcolor))
              (setf (rref tlc :rgbcolor.blue) (color-blue tlcolor))

              (setf (rref brc :rgbcolor.red) (color-red brcolor))
              (setf (rref brc :rgbcolor.green) (color-green brcolor))
              (setf (rref brc :rgbcolor.blue) (color-blue brcolor))

              (decf& bottom)
              (decf& right)
              (#_rgbForeColor tlc)
              (#_PenSize 1 1)
              (#_MoveTo left bottom)
              (#_LineTo left top)
              (#_LineTo right top)
              (#_rgbForeColor brc)
              (#_LineTo right bottom)
              (#_LineTo left bottom)
              (incf& top)
              (incf& left))
            )))))






(defun beveled-rect (top left bottom right border-width color delta-v)
  (flat-rect top left bottom right color)
  (beveled-frame top left bottom right border-width color delta-v))

(defun flat-rect (top left bottom right color)
  (with-rect (r left top right bottom)
    (with-rgb (c color)
      (#_rgbForeColor c)
      (#_PaintRect r ))))

(def-cached-function color+lightness (color change)
  (multiple-value-bind (h s v)
                       (color-to-hsv color)
    (hsv-to-color h s (max 0.0 (min 1.0 (+ v change))))))
  

;;; these are from Alan

(defun hsv-to-color (hue saturation value)
  (setq hue (round (* hue 65535))
        saturation (round (* saturation 65535))
        value (round (* value 65535)))
  (rlet ((hsv-var :hsvcolor :hue hue :saturation saturation :value value )
         (rgb-var :rgbcolor ))
    (#_hsv2rgb hsv-var rgb-var)
    (rgb-to-color rgb-var)))

(defun color-to-hsv (color)
  (rlet ((hsv-var :hsvcolor)
         (rgb-var :rgbcolor :red (color-red color) :blue (color-blue color)
                  :green (color-green color)))
    (#_rgb2hsv rgb-var hsv-var)
    (values (/ (rref hsv-var :hsvcolor.hue) 65535.0)
            (/ (rref hsv-var :hsvcolor.saturation) 65535.0)
            (/ (rref hsv-var :hsvcolor.value) 65535.0))))

#|
(defun hsl-to-color (hue saturation value)
  (setq hue (round (* hue 65535))
        saturation (round (* saturation 65535))
        value (round (* value 65535)))
  (rlet ((hsl-var :rgbcolor :red hue :green saturation :blue value )
         (rgb-var :rgbcolor ))
    (#_hsl2rgb hsl-var rgb-var)
    (rgb-to-color rgb-var)))

(defun color-to-hsl (color)
  (rlet ((hsl-var :rgbcolor)
         (rgb-var :rgbcolor :red (color-red color) :blue (color-blue color)
                  :green (color-green color)))
    (#_rgb2hsl rgb-var hsl-var)
    (values (/ (rref hsl-var rgbcolor.red) 65535.0)
            (/ (rref hsl-var rgbcolor.blue) 65535.0)
            (/ (rref hsl-var rgbcolor.green) 65535.0))))
|#


;;; Some classes that make use of the above

(defparameter *standard-border* 3)      ; these should be slots, I suppose
(defparameter *standard-delta-v* .2)
(defparameter *spacing* (round (* *standard-border* 2.5)))      ; used by layout

;;; new, based on view instead of simple-view
(defclass* beveled-rect-view-mixin (view)
  ((color :initarg :color :initform *gray-color* :accessor color)
   (bevel-border :initform *standard-border* :initarg :bevel-border)))

(defmethod* view-draw-contents :before ((v beveled-rect-view-mixin))
  (let* ((topleft (view-scroll-position v))
         (botright (add-points topleft (view-size v))))
    (beveled-rect (point-v topleft) (point-h topleft)
                  (point-v botright) (point-h botright)
                  bevel-border
                  color
                  *standard-delta-v*)))

;;; draw a hole as well
;;; this class might only be useful for making example layouts
(defclass* beveled-indent-rect-view-mixin (beveled-rect-view-mixin)
  ((bevel-border :initform (* 2 *standard-border*) :initarg :bevel-border)))

(defmethod view-draw-contents :after ((v beveled-indent-rect-view-mixin))
  (when (typep (view-container v) 'beveled-rect-view-mixin)
    (let* ((container-color (color (view-container v)))
           (topleft #@(0 0))
           (botright (add-points topleft (view-size v))))
      (beveled-frame  (point-v topleft) (point-h topleft)
                      (point-v botright) (point-h botright)
                      (- *standard-border*)
                      container-color
                      *standard-delta-v*))))

;(defclass* proto-block (view) ())        ; redefined for sheets

;;; beveled blocks with holes done right.

(defclass* depressions-for-subviews-mixin (beveled-rect-view-mixin)
  ())

(defmethod* view-draw-contents :after ((v depressions-for-subviews-mixin))
  (dosequence (sv (view-subviews v))
    (when (typep sv 'basic-block)       ; prob wrong test
      (let* ((topleft (view-position sv))
             (botright (add-points topleft (view-size sv))))
        (beveled-frame (point-v topleft) (point-h topleft)
                       (point-v botright) (point-h botright)
                       (- bevel-border)
                       (color v)
                       *standard-delta-v*)))))

;;; this is a function for the contained views. Invalidate container on move or grow
(defmethod set-view-position :after ((v depressions-for-subviews-mixin) hx &optional vx)
  (declare (ignore hx vx))
  (awhen (view-container v)
    (invalidate-view it)))

(defmethod set-view-size :after ((v depressions-for-subviews-mixin) hx &optional vx)
  (declare (ignore hx vx))
  (awhen (view-container v)
    (invalidate-view it)))

(defclass* layout-block (proto-block)
  ((tag :initarg :tag :accessor tag)
   (needs-layout? :initform t)))

(defclass* basic-block (layout-block depressions-for-subviews-mixin beveled-rect-view-mixin drag-mixin drag-and-drop-mixin expand-container-mixin gesture-handling-mixin)
  ()
  (:default-initargs
    :border (* 3 *standard-border*)
    :view-container *win*))

;;; Note: reducing this does not save much vertical space (which is mostly borders)
;;; but can reduce the horizontal space somewhat.
(defparameter *default-block-font* `("Tekton" 24 :bold))

(defclass* block-text-subview (layout-block expand-container-mixin gesture-handling-mixin text-view) ()
  (:default-initargs 
    :view-font *default-block-font*
    :border 1))

(defclass* block-pict-subview (layout-block pict-view drag-mixin drag-and-drop-mixin gesture-handling-mixin proto-block)
  ())

(defmethod can-drop? ((v block-pict-subview) (c t))
  t)


#|  for debugging
(defmethod view-draw-contents :before ((v block-text-subview))
  (with-rect (r 0 (view-size v))
    (with-rgb (c *black-color*)
      (#_rgbForeColor c)
      (#_Framerect r))))
|#

;;; exists to be overriden by hole
(defmethod default-text-color ((block basic-block))
  *black-color*)

(defmethod drag :before ((v basic-block) &optional where)
  (declare (ignore where))
  (set-view-level v 0))

;;; blocks indicate functions or constants
;;; was just BLOCK but turns out that is a system type in MCL 4.1!
(defclass* a-block (translucent-mixin basic-block) 
  ()
  (:default-initargs 
    :view-container *win*
    :view-font *default-block-font*))

(defmethod view-default-size ((block basic-block))
  #@(10 10))                            ; get expanded by subviews

;;; holes indicate parameters
;;; same as block, but with different border and font
(defclass* hole (highlight-target-mixin basic-block) ()          ; +++ might want to cut down classes for this (ie drag-and-drop)
  (:default-initargs 
    :view-font *default-block-font*
    :bevel-border 0
    ))

(defmethod default-text-color ((hole hole))
  *white-color*)

(defun medium-blocks ()
  (setf *default-block-font* `("Tekton" 18 :bold))
  (setf *standard-border* 2)
  (setf *spacing* (round (* *standard-border* 2.5))))

(defun small-blocks ()
  (setf *default-block-font* `("Tekton" 14))
  (setf *standard-border* 2)
  (setf *spacing* (round (* *standard-border* 2.5))))

(defun large-blocks ()
  (setf *default-block-font* `("Tekton" 24 :bold))
  (setf *standard-border* 3)
  (setf *spacing* (round (* *standard-border* 2.5))))

(medium-blocks)
