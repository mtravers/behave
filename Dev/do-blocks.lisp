;;; rationalize compilation a bit;;; status: seesm to work, but DO block has bad appearance problems and other;;; examples need reformatting.(defmethod* register-agent-block ((block agent-block))  (handler-case    (progn      (setf agent (make-instance                    *agent-class*                    :name-of agent-name                    :species (species-named species)                    :block block                    :body (list (generate-code block))))      (compile-agent agent)      (agent-complete block)      agent)    (error (condition)           (agent-incomplete block (princ-to-string condition))     ; +++ might want to store condition somewhere;           (warn "couldn't make agent from block ~A because ~A" block condition)           )))(defun compile-agent-body (body)  (parse-type 'agent (car body)))(defmethod* generate-blocks ((a agent))  (block-for-exp (car body) 'agent))(defform (do agent          :block-class agent-block)         (action)  action)                               ; gee that's simple(defexample (fish-example "Fish")    (defspecies fish :number 100 :color 'red)  (defspecies shark :number 1 :color 'grey)    (defagent (swim fish)    (if (always)      ;   (turn (arand 1))                    ; deal with 2 actions      (go (east) (slider 3))))                   ; should be (random (slider speed 0 20)) or some such    (defagent (school fish)    (if (always)      (go (towards (a-random fish))    ; awkward!          (slider 9))))     ; should be (random (slider school-strength 0 20))    '(defagent (elbow fish)     (if (on (a fish))                            ; make on work       (go (randomly) .6)))    (defagent (flee fish)                   ; second rule of life    (if (near (a shark) (slider 13))      (go (away-from (it)) (slider 30))))      (defagent (hunt shark)    (if (always)                             ; except when target is dead...how to deal with that?      (go (towards (the-closest fish)) (slider 12))))    )