(in-package :cl-user)#| ######################################################################Micro-loader for Lisp systemsCopyright � 1996 Michael TraversAuthor: Michael Travers (mt@media.mit.edu)-------------------------------------------------------------------------The smallest possible system loader.  Example of use:(load-system  (car *loading-files*)  '("file-1"   "file-2"   ...   ))###################################################################### |#;;; Micro-loader(defun load-system (base-path file-list)  (with-compilation-unit ()    (mapc #'(lambda (file)              (let ((full-file (concatenate 'string base-path file)))                (compile/load full-file)))          file-list)))(defun compile/load (file)  (let ((source (source-file file))        (fasl (fasl-file file)))    (when (> (file-write-date source)             (or (file-write-date fasl) 0))      (compile-file source :output-file fasl))    (load fasl)))(defun source-file (file)  (make-pathname :defaults file :type "lisp"))(defun fasl-file (file)  (make-pathname :defaults file :type #-POWERPC "fasl" #+POWERPC "pfsl"))