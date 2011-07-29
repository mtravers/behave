(in-package :beh)#| ######################################################################this file collects misc. functions that connect Behave!and StarLogo.Part of the Behave! systemCopyright � 1996-7 Michael Travers Send questions, comments, and fixes to mt@media.mit.edu.###################################################################### |#(defform (slider number :block-class slider-block) (number)  `(u::.obs ,number))(defmethod value-changed :after ((v my-slider-view))   ; warning, there is a primary method for this gf/class  (u::set-global-value (slider-number v) (slider-value v)))(defmethod* initialize-instance :after ((species sl-species) &rest ignore)  (make-*logo-symbol name-of))(defmethod* initialize-instance :after ((agent sl-agent) &rest ignore)  (make-*logo-symbol name-of))(defmethod* start-agent-block ((block agent-block))  (unless (downloaded? agent)    (download block))  (run-*logo (format nil "~A-~A-agent" species agent-name)))(defmethod* stop-agent-block ((block agent-block))  (run-*logo (format nil "stop~A-~A-agent" species agent-name)))(defun setup ()  (reset-species)  (u::initialize-interface))(u::on-startup (setup)  (setup));;; 2/25/97 13:25 New glue (post-vft version); +++ this needs to be hidden in palette, I think(setf *number-form*  (defform (20 number :hidden t) (raw)    raw));;; obso;;; would be nice if this could be in a random position, but that's hard(defun create-a (breed)  (run-*logo (format nil "create-~A 1" breed))  (run-*logo (format nil "ask-~A [setc ~A]" breed (species-color (species-named breed)))))(defun create-creatures (breed n)  (run-*logo (format nil "create-random ~A ~A ~A"                      breed n (species-color (species-named breed)))))(defun reset-world ()  (setf *background-color* nil)  (unless u::*starlogo-inited?*    (u::init)    (window-close u::*toolbar-window*)          ; get rid of toolbar    (setf u::*observer-queue* nil)      ; don't create initial turtles    ))(defun initialize-world  (&optional name)  (when name    (set-window-title u::graphics-window (string name)))  (at-listener-level                    ; because size update is done at listener level    (position-graphics-window))  (u::beh-eval-flip t)                   (start-all-agents))(defun position-graphics-window ()  (let* ((gwin u::graphics-window)         (bwin (view-window *win*))         (screen-width (point-h (second (multiple-value-list (ccl::find-best-color-screen)))))         (beh-right-edge (point-h (add-points (view-position bwin)                                              (view-size bwin)))))    (set-view-position gwin                       (make-point (min (+ 6 beh-right-edge)                                        (- screen-width (point-h (view-size gwin))))                                  44))));;; put some picts in the species blocks(defun *color-value (color-spec)  (etypecase color-spec    (number color-spec)    (symbol (car (u::define-fcn (u::get-definition                                 (intern (symbol-name color-spec) (find-package :u)))))))); +++ this should pick a view to draw in; +++ pict memory never gets released; sometimes null ptr is returned, don't know why.(defun make-turtle-pict (color)  (let ((*color (*color-value color)))    (with-rect (r #@(0 0) #@(16 16))      (let ((pict (#_OpenPicture r)))        (with-rgb (c 0)          (#_getentrycolor            u::palette           *color           c)          (#_rgbForeColor c)          (#_OffSetRgn u::*turtle--region* (- u::*cbar--turtlex*) (- u::*cbar--turtley*))          (#_PaintRgn u::*turtle--region*)          (#_OffSetRgn u::*turtle--region* u::*cbar--turtlex* u::*cbar--turtley*))        (#_ClosePicture)        (and (not (ccl::%null-ptr-p pict))             pict)))))(defmethod initialize-instance :after ((s sl-species) &rest ignore)  (update s));;; also called when user edits species thru dialog(defmethod* update ((s sl-species) &optional download?)  (setf pict (make-turtle-pict color))  (make-*logo-symbol name-of)  (when download?    (run-*logo (format nil "ask-~A [setc ~A]" (name-of s) (species-color s)))))(defmethod set-name-of :around ((s sl-species) new-name)  (let ((old-name (name-of s)))    (call-next-method)    (unless (equal new-name old-name)      (u::beh-eval-flip t))))    