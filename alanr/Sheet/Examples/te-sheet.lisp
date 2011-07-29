(in-package :ccl);; Some supercontainer of views build on basic-te's must be of this class. This;; arranges to catch (defclass textedit-basic-sheet (sheet-view quickdraw-bottleneck-mixin)  ()  (:default-initargs :depth 1 :allow-other-keys t));; swine textedit doesn't respect drawing only within its viewrect.;; Intersect any requests with the viewrect here.(defmethod rectproc ((v textedit-basic-sheet) verb rect &aux vc)  (declare (ignore verb))  (if (typep *current-view* 'te-basic)    (progn      (with-pointers ((teptr (textedit-handle *current-view*)))        (let ((r (pref teptr :terec.viewrect)))          (#_sectrect rect r rect)))      (call-next-method)      (unless *te-updating*        (when (setq vc (view-container v))          (#_rectrgn *temp-rgn* rect)          (#_offsetrgn :ptr *temp-rgn* :long            (convert-coordinates-up #@(0 0) *current-view* vc))          (invalidate-region vc *temp-rgn* t))))    (call-next-method)))      