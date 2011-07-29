(in-package :cl-user)(defparameter for-*logo t)(setf *load-verbose* t       *compile-verbose* t       ccl::*control-key-mapping* :command)(defparameter *beh-directory*  (car ccl::*loading-files*))(ccl::set-logical-pathname-translations  "beh" `(("beh:**;*.*" ,(make-pathname :directory (append (pathname-directory *beh-directory*) '("**")) :name :wild :type :wild))))(load "beh:micro-loader");;; we need to have AlanR's loader too(unless (fboundp 'ccl::load-if-newer)  (setf ccl::*warn-if-redefine-kernel* nil)  (load "beh:alanr;file set;load-manually.lisp")  (load "beh:mt;mt-load-newer-patches.lisp")  (load "beh:alanr;file set;fileset-file-set")  (ccl::load-if-newer "fileset")  (load "beh:mt;mt-load-newer-patches.lisp")  )(defparameter general-files '( "mt;closstar"    "mt;mt-pkg"    "mt;mt-utils"    "mt;mcl-hacks"    "mt;clos-library"    "mt;sound"    "mt;startup-manager"    "starlogo;starlogo-load.lisp"       ; +++ should be conditional on for-*logo        "source;beh-package"    "source;resources"    "source;general-agents"    "source;beh-sheet"    "source;view-library"    "source;beh-window"    "source;bevel"    "source;pict-button"    "source;form-blocks"    "source;agent-blocks"    "source;layout"    "source;species-block"    "source;slider-blocks"    "source;blink"                      ; can be removed if people hate it    "source;palette"    "source;wiz-gestures"               ; comment out for release    "source;canned-agents"    "source;menus"))(defparameter *logo-files   '("source;less-abrupt-layout"               ; at the moment, works only with *logo    "source;starlogo;starlogo-agents"         ; include in non-starlogo version please    "source;starlogo;glue"    "source;starlogo;sl-download"    "source;starlogo;download-beh"                     ; in user package    "source;starlogo;beh-examples"    ))(defparameter vft-files  '("source;vft;vft-slider"    "source;vft;vft-agents"    "source;vft;vft-compile"    "source;vft;tcp"    "source;vft;vft-examples"     ))(load-system  "beh:" (if for-*logo   (append general-files *logo-files)   (append general-files vft-files)))