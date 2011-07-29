;; ****************************************************************;;;; Author: Alan Ruttenberg, MIT Media Lab;; email:  alanr-d@media.mit.edu;;;; Created: Sunday October 9,1994;; MT: revised to use pict objects, which can draw into gworlds;; todo: use momentary push icons in toggles.;;;; modified again to use PICTs, icons suck rocks.;; modified to use my gesture system.;; ;; ****************************************************************(in-package :ccl);;; Additions to pict class;****************************************************************;;; button independent of display(defclass button (view)  ((state :initarg :state :initform :released :accessor state)))(defclass pict-button (button)  ((pict :initarg :pict :initform nil :accessor pict)   (pict-pressed :initarg :pict-pressed :initform nil :accessor pict-pressed)))                         ;;; init size of view based on PICTs(defmethod view-default-size ((v pict-button))  (when (pict v)    (subtract-points (rref (pict v) picture.picframe.bottomright)                     (rref (pict v) picture.picframe.topleft))))(defmethod view-draw-contents ((button pict-button))  (draw-pict button             (ecase (state button)               (:pressed (pict-pressed button))                (:released (pict button)))))(defmethod draw-pict ((v pict-button) the-pict)  (let* ((topleft #@(0 0))         (bottomright (view-size v)))    (rlet ((dest-rect rect            :topleft topleft :bottomright bottomright))      (#_DrawPicture the-pict dest-rect))))(defmethod update-now ((v pict-button))  (invalidate-view v nil)  (window-update-event-handler (view-window v)));; press and release correspond to user actions. These two just change ;; the state.(defmethod make-active ((v pict-button))  (setf (state v) :pressed)  (update-now v))(defmethod make-unactive ((v pict-button))  (setf (state v) :released)  (update-now v))(defmethod set-state ((v pict-button) state)  (setf (state v) state)  (update-now v));****************************************************************(defclass toggle-pict-button (pict-button) ())(defmethod press ((button toggle-pict-button))  (setf (state button) :pressed)  (invalidate-view button t)  (window-update-event-handler (view-window button))  )(defmethod release ((button toggle-pict-button))  (setf (state button) :released)  (invalidate-view button t)  (window-update-event-handler (view-window button))  )#|(defmethod view-click-event-handler ((v toggle-pict-button) ignore)  (declare (ignore ignore))  (if (eq (state v) :pressed)    (release v)    (press v)))|#;;; use gesture-handling-mixin system(defmethod beh::click ((v toggle-pict-button) ignore)  (declare (ignore ignore))  (if (eq (state v) :pressed)    (release v)    (press v))  t)  ;****************************************************************(defclass momentary-pict-button (toggle-pict-button) ())#|(defmethod view-click-event-handler ((v momentary-pict-button) ignore)  (declare (ignore ignore))  (press v)  (loop until (not (mouse-down-p))          finally (release v)))|#  (defmethod beh::click ((v momentary-pict-button) ignore)  (declare (ignore ignore))  (press v)  (loop until (not (mouse-down-p))          finally (release v))  t)