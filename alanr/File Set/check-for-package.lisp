(in-package :ccl)(defun check-for-initial-package-statement (file)    (with-open-file (f (merge-pathnames ".lisp" file))      (multiple-value-bind (result error) (read f)        (if (and (not error) (listp result) (= (length result) 2)                 (symbolp (car result))                 (eq (car result) 'in-package))          (format t "~&~a is ok~%" file)          (format t "~&Trouble with ~a~%" file)))))(iterate-over-files (file-set "streamview102")                      'check-for-initial-package-statement                      #'identity)(defun check-fileset-files-in-packages (fileset)  (iterate-over-files (file-set fileset)                      'check-for-initial-package-statement                      #'identity))