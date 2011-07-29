(in-package :beh)#| ######################################################################General classes (species, agent, form) and parserCopyright � 1996-7 Michael TraversPart of the Behave! systemSend questions, comments, and fixes to mt@media.mit.edu.###################################################################### |#;;; these are set for a particular version of Behave!(defvar *species-class*)(defvar *agent-class*)(defclass* species (track-named-instances-mixin)  ((slots :accessor species-slots :initform nil :initarg :slots)   (pict :initarg :pict :initform nil)   (agents :initform (make-hash-table :test #'eq))   (proto-agents :initform (make-hash-table :test #'eq))))(defun reset-species ()  (remove-all-instances (class-prototype (find-class *species-class*)))  (setf (get 'breed :xtranslations) nil))(defclass* agent (named-instance-mixin)  ((species :initarg :species)   (body :initarg :body)   (block :initarg :block :initform nil :reader agent-block)))(defmethod* initialize-instance :after ((agent agent) &rest ignore)  (add-agent species agent))(defmethod* add-agent ((species species) agent)  (setf (gethash (name-of agent) agents) agent))(defmethod* species-agents ((species species))  (let ((result nil))    (maphash #'(lambda (ignore agent)                 (push agent result))             agents)    result))(defmethod* species-proto-agents ((species species))  (let ((result nil))    (maphash #'(lambda (ignore agent)                 (push agent result))             proto-agents)    result))(defmacro defspecies (species &body parameters)  `(progn     (defparameter ,species       (make-instance              *species-class*              :name-of ',species              ,@parameters))     (defprim ,species breed)))(defun species-named (name)  (find-named-instance-of *species-class* name))(defmacro defagent ((name species) &body body)  `(let ((agent (make-instance                  *agent-class*                  :name-of ',name                  :species (species-named ',species)                  :body ',body)))     (compile-agent agent)     agent))(defun all-species ()  (all-of *species-class*))(defun all-agents ()  (mapcan #'species-agents          (all-species)))(defvar *species*)                      ; bound to objects of current compilation(defvar *agent*)(defclass* form ()  ((name :initarg :name :reader name )   (type :initarg :type :reader type)   (args :initarg :args :reader args)   (block-class :initarg :block-class :reader block-class)   (body :initarg :body :reader body)   (layout :initarg :layout :initform nil)   (hidden :initarg :hidden :reader hidden :initform nil)))(defmethod* print-object ((form form) stream)  (print-unreadable-object (form stream :identity t :type t)    (format stream "(~A ~A) ~A" name type args)))(defvar *all-types* nil)(defmacro defform ((name type &key (block-class 'form-block) layout hidden)                   arglist &body body)  `(defform-1 ',name ',type ',arglist ',body ',block-class ',layout ',hidden))(defmacro defprim (name type &key (block-class 'form-block) layout hidden)  `(defform-1 ',name ',type nil '(',name) ',block-class ',layout ',hidden))(defun defform-1 (name type args body block-class layout hidden)  (awhen (find name               (get type :xtranslations) :key #'name)    (deletef it (get type :xtranslations)))  (pushnew type *all-types*)  (let ((form (make-instance 'form                :name name                :type type                :args (mapcar #'(lambda (argdef)                                  (if (symbolp argdef)                                    (list argdef argdef)                                    argdef))                              args)                :block-class block-class                :body body                :layout layout                :hidden hidden)))    (push form (get type :xtranslations))    form))(defvar *number-form*)                  ; this is a special crock to handle numbers, set elsewhere(defun walk-type (type thing func)  ;; handle special cases  (case type    (number     (cond ((numberp thing)            (return-from walk-type              (funcall func (list 'number thing) *number-form*)))           ((and (listp thing) (numberp (car thing)))            (return-from walk-type              (funcall func (cons 'number thing) *number-form*)))))    (raw     (return-from walk-type       (funcall func thing nil)))    ;; not used...I think    (primitive     (error "How primitive")))  (dolist (translation (get type :xtranslations)                       (error "In (~A ~A), can't parse ~a as ~a" (name-of *agent*) (name-of *species*) thing type))    (cond ((and (atom thing)                (eq thing (name translation)))           (return (funcall func thing nil)))          ((and (listp thing)                (eq (car thing)                    (name translation)))           (unless (= (1- (length thing)) (length (args translation)))             (error "In (~A ~A), wrong number of arguments in ~A" (name-of *agent*) (name-of *species*) thing)             (setf (compiled-ok? *agent*) nil))           (return (funcall func thing translation))))))(defun parse-type (type thing)  (walk-type type thing             #'(lambda (thing translation)                 (if translation                   (progv (mapcar #'car (args translation))                          (mapcar #'(lambda (arg term)                                      (parse-type (cadr arg)                                                  term))                                  (args translation)                                  (cdr thing))                     (eval (car (body translation))))                   thing))))