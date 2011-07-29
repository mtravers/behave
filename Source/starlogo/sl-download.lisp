(in-package :beh)#| ######################################################################Download to StarLogo (see also download-beh.lisp)Part of the Behave! systemCopyright � 1996-7 Michael Travers Send questions, comments, and fixes to mt@media.mit.edu.###################################################################### |#(defvar *prims* nil)(defun init-beh-prims (&optional force)  (when (or (null *prims*) force)    (setf *prims*          (with-open-file (s "beh:source;starlogo;beh-prims.starlogo")            (u::parse-stream s t)))))(u::make-alternate-readtable)           ; must do this before parse-stream can work(init-beh-prims);;; define turtle vars our way.;;;  Will override any in prim file.  Watch out for future-statevalues.;;; the order of these can matter in some way that I no longer understand well(defparameter *built-in-variables* '(u::scratch u::it u::dead u::scratch1 u::scratch2 u::loopcount))(defun define-variables ()  (let* ((species (all-species))         (slots (remove-duplicates (append *built-in-variables*                                           (mapappend #'species-slots species)))))    (u::setup-turtlesown slots)))(defun turtle-var (name)  `(u::.thing ,(position name *built-in-variables*)))(defvar *background-color* nil)(defun define-breeds (reset-world)  (let ((species (all-species)))    (u::setup-breeds (nconc (mapcar #'name-of species)                            (list 'u::corpse)))         ; add in corpse breed    (when reset-world      (run-*logo "ca")      (when *background-color*        (run-*logo (format nil "setpc ~A" *background-color*)))      (mapc #'setup-species species))))(defmethod* setup-species ((sl sl-species))  (run-*logo (format nil "create-~A ~A" name-of number))  (run-*logo (format nil "ask-~A [setc ~A setxy random 100 random 100]" name-of color)))(defvar *all-agents*)(defun define-agents ()  (let ((all-agents nil))    (dolist (species (all-species))      (dolist (agent (species-agents species))        (if (compiled-ok? agent)        ;; stuff done in read-flip          (let ((agent-name (*logo-name-conc (name-of species) '- (name-of agent))))            (u::read-flip-fcn agent-name nil (u::process-breed-refs                                              (agent-lisp-code agent)))            (push agent-name all-agents)            (setf (downloaded? agent) t))          (warn "Agent ~A had compile problems"  agent))))    (setf *all-agents* all-agents)))(defun *logo-name-conc (&rest symbols)  (let ((*package* (find-package :cl-user)))    (apply #'symbol-conc symbols)))(defun setup-demons ()  (dolist (agent *all-agents*)    (u::setup-a-demon (*logo-name-conc agent '-agent) (list agent)))  (u::setup-a-demon (*logo-name-conc 'die-demon1-demon) (list 'u::die-demon1)))      (defun start-utility-agents ()  (run-*logo "die-demon1-demon"))(defun start-agent (agent-name)  (run-*logo (symbol-name agent-name))  agent-name)(defun stop-agent (agent-name)  (run-*logo (concatenate 'string "STOP" (symbol-name agent-name)))  agent-name)#|; done through blocks now(defun start-all-agents ()  (dolist (a *all-agents*)    (run-*logo (format nil "~A-agent" a)))); use run-*logo(defun run-command (string)  (u::run-command string)               ; no error handling;  (u::run-the-line nil string nil)  )|#(defun run-*logo (string)  (u::run-command string))(defmethod download ((b agent-block))  (u::beh-eval-flip nil)  (mapc #'maybe-start-after-download (all-agent-blocks)));;; this will find ones that aren't in a species(defun all-agent-blocks ()  (find-views *win* #'(lambda (x) (typep x 'agent-block))))(defmethod* maybe-start-after-download ((block agent-block))  (when (and switched-on? complete?)    (start-agent-block block)));;; some old stuff#|  (defun download (&optional reset-world)  (u::download-beh reset-world));;; this logic not used in vft version, and probably should be flushed from *logo(defmethod download ((b starlogo-agent-block))  (download-agent-blocks))(defun download-agent-blocks ()  (download)  (mapc #'maybe-start-after-download (all-of 'agent-block)))(defmethod* maybe-start-after-download ((block agent-block))  (setf status :downloaded)  (when (eq user-status :on)    (start-agent-block block)))|#