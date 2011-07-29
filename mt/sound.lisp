;;; warning: used to be in ccl using mt, but that sucked.(in-package :mt)#|;;; Sound Manager interfaceHistory:12/8/96 12:19  cleanup, remove some stuff to mcl-hacks.1/16/97 2:28   changed package to mt|#(defvar *sound-channel* nil)            ; apparently you can only have one open;;; actually the solution is to open the channel without a synthesizer parameter.  What a crock(defun sound-new-channel (&optional (synth-type 0))  (rlet ((ptrptr :pointer))    (%put-ptr ptrptr (%null-ptr))    (errcheck (#_SndNewChannel ptrptr synth-type #$initMono (%null-ptr)))    (%get-ptr ptrptr)))#|;;; A version that bypasses the inane and seemingly broken load checking;;; but it doesn't work either(defun sound-new-channel (&optional (synth-type #$sampledSynth))  (rlet ((ptrptr :pointer))    (%put-ptr ptrptr (%null-ptr))    (errcheck (#_SndNewChannel ptrptr 0 0 (%null-ptr)))    (let ((chan (%get-ptr ptrptr)))      (errcheck (#_SndAddModifier chan (%null-ptr) synth-type 0))      chan)))|#(defun sound-setup ()  (setf *sound-channel* (sound-new-channel)))(defun sound-play-async (snd-handle &optional (channel *sound-channel*))  (#_SndPlay channel snd-handle t))(defun sound-command (cmd &optional (channel *sound-channel*) (p1 0) (p2 0))  (rlet ((cmdrec :sndcommand :cmd cmd :param1 p1 :param2 p2))    (#_SndDoImmediate channel cmdrec)))(defun flush-sound-channel (&optional (channel *sound-channel*))  (sound-command #$flushCmd channel))(defun quiet-sound-channel (&optional (channel *sound-channel*))  (sound-command #$quietCmd channel));;; you can call this without calling sound-setup first.(defun sound-play (snd-handle)  (#_SndPlay (if *sound-channel*                *sound-channel*               (%null-ptr))   snd-handle nil))(defun sound-channel-busy (&optional (channel *sound-channel*))  (rlet ((status :scstatus))    (#_SndChannelStatus channel     #.(record-descriptor-length (find-record-descriptor :scstatus))     status)    (rref status :scstatus.scchannelbusy)))(defun sound-get-resource (n)  (#_GetResource "snd " n))(defun all-sounds () (all-resources-of-type "snd "))(defun set-sample (snd-resource-handle)  (#_HLock snd-resource-handle)  (with-dereferenced-handles ((snd-ptr snd-resource-handle))    (rlet ((command :sndcommand                    :cmd #$soundCmd                    :param2 (%ptr-to-int snd-ptr)))    (#_SndDoImmediate *sound-channel* command))))(defun play-freq (freq dur)  (rlet ((command :sndcommand :cmd #$freqDurationCmd :param1 dur :param2 freq))    (#_SndDoImmediate *sound-channel* command)));;; Squarewaves#|;;; For some reason it thinks my fx has inadequate hardware to make squarewaves..(defvar *sound-square-channel*)(defun setup-synth ()  (setf *sound-square-channel* (sound-new-channel #$squareWaveSynth)))(defun play-freq (freq dur)  (rlet ((command :sndcommand :cmd #$freqDurationCmd :param1 dur :param2 freq))    (#_SndDoCommand *sound-square-channel* command t)))|#;;; Recording;;; Returns sound handle (defun sound-record (&optional (dialog-pos #@(100 100)))  (rlet ((p :pointer))    (%put-ptr p (%null-ptr))    (let ((errcode (#_SndRecord (%null-ptr) dialog-pos #$siBetterQuality p)))      (if (zerop errcode)        (%get-ptr p)        errcode))))(export '(sound-setup          sound-play sound-play-async sound-record           flush-sound-channel quiet-sound-channel sound-channel-busy          ))(provide :sound) 