(in-package :ccl);;you need to mix this class into your window (defclass transparent-text-window (quickdraw-bottleneck-mixin window) ()  (:default-initargs :color-p t))(defmethod install-bottleneck? ((w transparent-text-window) method)  (eq (car method) 'rectproc))(defmethod view-sheet ((w transparent-text-window)) w)(defclass transparent-text-view (view)  ((thetext :initarg :thetext :initform nil :accessor thetext)))(defvar *drawing-my-text?* nil)(defmethod view-sheet ((v transparent-text-view)) (view-window v))(defmethod view-draw-contents ((v transparent-text-view))  (let ((handle (%str-to-handle (thetext v))))    (with-pointer (p handle)      (let ((*drawing-my-text?* t))        (without-interrupts         (#_textmode #$transparent)         (rlet ((rect :rect :topleft 0 :bottomright (view-size v)))           (#_textbox p (#_gethandlesize handle) rect              #$tejustleft)))))))(defmethod rectproc ((w transparent-text-window) verb rect)  (declare (ignore verb rect))  (if *drawing-my-text?* nil (call-next-method)));; test. remove the leading quote to execute.'(progn    (defclass test-red-window (transparent-text-window) ())    (defmethod view-draw-contents ((v test-red-window))    (with-fore-color *red-color*      (rlet ((rect :rect :topleft 0 :bottomright (view-size v)))        (#_paintrect rect))      (call-next-method)))    (make-instance     'test-red-window :view-size #@(300 300)    :view-subviews     (list (make-instance 'transparent-text-view :thetext "How much wood could a wood chuck chuck if a wood chuck could chuck wood?"                         :view-size #@(100 100)                         :view-position #@(100 100))))  )