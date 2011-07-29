(in-package :ccl);; Basic textedit engine. Makes a view the height of which matches the height of ;; the textedit box. Compatible with sheet-views, if some supercontainer is of class;; te-basic-sheet. This class has no interaction, use stuff built on it to do interaction.;; Call maybe-size-changed when something is done which might change the size of the;; paragraph (e.g. _TeKey).;; Incremental redisplay with gworld is based on the fact that textedit erases areas;; before it draws. By catching the erase rectangles we know which areas to invalidate.;; Note that this assumes that there is a single paragraph in the view. Multiple;; paragraphs are constructed by making strings of several views of this kind.(defvar *null-caret-hook*  nil)(def-load-pointers *null-caret-hook* ()  (setq *null-caret-hook*        (let ((words (%lap-words '((add ($ 4) sp) (rts)))))          (let ((r (#_newptr (* 2 (length words)))))            (loop for w in words                   for offset from 0 by 2                  do (%put-word r w offset))            r))))(defclass te-basic (key-handler-mixin a-view)  ((textedit-handle :initarg :textedit-handle :accessor textedit-handle)   (width :initarg :width :accessor width)   (last-height :initarg :last-height :initform (make-length 0 :inches) :accessor last-height)   (last-width :initarg :last-width :initform nil :accessor last-width)   (style :initarg :style :initform nil :accessor style)   (width-set :initarg :width-set :initform nil :accessor width-set)   (show-caret? :initarg :show-caret? :initform t :accessor show-caret?)   (space-before :initarg :space-before :initform (make-length 0 :inches) :accessor space-before)   (space-after :initarg :space-after :initform (make-length 0 :inches) :accessor space-after)   (left-margin :initarg :left-margin :initform (make-length 0 :inches) :accessor left-margin)   (right-margin :initarg :right-margin :initform (make-length 0 :inches) :accessor right-margin)   (marks :initarg :marks :initform nil :accessor marks))  (:default-initargs :allow-other-keys t :width (make-length 2 :inches)))(defmethod initialize-instance ((p te-basic) &key width (text ""))  (if (null width)    (setf (width p) (make-length (point-h (view-size p)) :pixels))    (setf (width p) width))  (setf (width-set p) (copy-length (width p)))  (setf (textedit-handle p)        (let ((r (rect #@(0 0) (make-point (length-value width :pixels) 32767))))          (#_testylnew r r)))  (call-next-method)  (when (null (show-caret? p))    (setf (rref (textedit-handle p) terec.carethook) *null-caret-hook*))  (set-text p text)  )(defmethod cursor-on ((p te-basic))  (setf (rref (textedit-handle p) terec.carethook) (%null-ptr)))(defmethod cursor-off ((p te-basic))  (setf (rref (textedit-handle p) terec.carethook) *null-caret-hook*))(defmethod print-object ((v te-basic) stream)  (let ((h (textedit-handle v)))    (let ((text (#_tegettext h)))      (format stream "#<� #x~x \"~A�\">" (%address-of v)              (coerce                (loop for i below (min (#_gethandlesize text) 20)                     collecting (code-char (%get-unsigned-byte (%get-ptr text) i)))               'string)))))(defmethod set-text ((p te-basic) new-text)  (let ((text-handle (%str-to-handle new-text)))    ;; a good example of why you have to lock handles. If you don't lock text-handle    ;; and just pass %get-ptr of it to _tesettext, it periodically junks what gets stuffed in    ;; the textedit string.    (with-pointers ((textptr text-handle))      (#_tesettext textptr (length new-text) (textedit-handle p)))    (#_disposehandle text-handle))  (#_tecaltext (textedit-handle p))  (size-changed p)  (invalidate-view p t))(defmethod get-text ((p te-basic))  (let ((string-handle (#_tegettext (textedit-handle p))))    (with-pointers ((string-ptr string-handle))      (%str-from-ptr string-ptr (#_gethandlesize string-handle)))))(defmethod number-of-lines ((p te-basic))  (rref (textedit-handle p) terec.nlines))(defmethod line-vertical-position ((p te-basic) line-number)  (point-v (#_tegetpoint (rref (textedit-handle p) (terec.linestarts line-number))            (textedit-handle p))))(defmethod height ((p te-basic))  (let ((l #.(make-length 0 :pixels)))    (set-length-value l (list (+ (length-value (space-after p) :pixels)                           (line-vertical-position p (number-of-lines p)))                        :pixels))    l))(defmethod line-starts ((p te-basic))  (loop for i below (number-of-lines p)        collecting (line-vertical-position p i)))(defmethod maybe-size-changed ((p te-basic))  (unless (and (equalp (last-height p) (height p))               (equalp (last-width  p) (width p)))    (size-changed p)))(defmethod size-rects ((p te-basic))  (rlet ((r :rect             :topleft (make-point (length-value (left-margin p) :pixels)                                 (length-value (space-before p) :pixels))            :bottomright (make-point (- (length-value (width p) :pixels)                                        (length-value (right-margin p) :pixels))                                     (- (length-value (height p) :pixels)                                        (length-value (space-after p) :pixels)))))    (with-pointers ((teptr (textedit-handle p)))      (copy-record r :rect (pref teptr :terec.destrect))      (copy-record r :rect (pref teptr :terec.viewrect)))))(defmethod size-changed ((p te-basic))  (with-focused-view p    (let ((last-height (last-height p)))      (size-rects p)      (#_tecaltext (textedit-handle p))      (size-rects p)      (setf (last-width p) (copy-length (width p)))      (setf (last-height p) (copy-length (height p)))      (set-view-size p (length-value (width p) :pixels) (length-value (height p) :pixels))      (invalidate-corners p (make-point 0 (- (length-value last-height :pixels)                                             (length-value (space-after p) :pixels)))                          (view-size p) nil)      )))(defmethod set-width ((p te-basic) new-width)  (unless (equalp new-width (width p))    (setf (last-width p) (width p))    (setf (width-set p) (copy-length new-width))    (setf (width p) new-width)    (maybe-size-changed p)    (invalidate-view p t)))(defmethod focus-view :before ((v te-basic) &optional font-view)  (declare (ignore font-view))  (when (and (textedit-handle v) (wptr v))    (setf (rref (textedit-handle v) :terec.inport) (wptr v))))(defvar *te-updating* nil)(defmethod view-draw-contents ((v te-basic))  (let ((te (textedit-handle v)))    (let ((*te-updating* t))      (#_eraserect (rect (view-size v)))      (#_teupdate (rect (view-size v)) te)      (call-next-method)      )))(defmethod key-handler-idle ((v te-basic) &optional foo)  (declare (ignore foo))  (with-focused-view v    (#_teidle (textedit-handle v)))  (call-next-method))(defmethod view-key-event-handler ((v te-basic) char)  (with-focused-view v    (insert-char v char)    (maybe-size-changed v)))(defmethod insert-char ((v te-basic) char)  (#_tekey char (textedit-handle v)))(defmethod edit-activate ((v te-basic))  (with-focused-view v    (let ((window (view-window v)))      (#_teactivate (textedit-handle v))      (view-put v :last-key-handler (current-key-handler window))      (when (not (member v (%get-key-handler-list window)))        (view-put window '%key-handler-list (cons v (%get-key-handler-list window))))      (set-current-key-handler window v))))(defmethod edit-deactivate ((v te-basic))  (with-focused-view v    (#_tesetselect 0 0 (textedit-handle v))    (#_tedeactivate (textedit-handle v))    (when (view-get v :last-key-handler)      (set-current-key-handler (view-window v) (view-get v :last-key-handler)))))(defmethod set-cursor-from-click ((v te-basic) where)  (with-focused-view v    (let ((offset (#_tegetoffset where (textedit-handle v))))      (#_tesetselect offset offset (textedit-handle v)))))  