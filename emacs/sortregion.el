;; goal: sanitize package lists so they can be reasobably diff'ed

;; approach: define an emacs function which transforms this:

;; fasel="apt-transport-https alsa-utils apache2 autoconf automake avahi-daemon bash-completion \
;; u-boot-tools usb-modeswitch usbutils v4l-utils vim wget wireless-tools \
;; wpasupplicant wvdial zd1211-firmware"

;; into this (in-place):

;; fasel="	\
;; 	alsa-utils	\
;; 	apache2	\
;; 	apt-transport-https	\
;; 	autoconf	\
;; 	automake	\
;; 	avahi-daemon	\
;; 	bash-completion	\
;; 	u-boot-tools	\
;; 	usb-modeswitch	\
;; 	usbutils	\
;; 	v4l-utils	\
;; 	vim	\
;; 	wget	\
;; 	wireless-tools	\
;; 	wpasupplicant	\
;; 	wvdial	\
;; 	zd1211-firmware	\
;; "

;; usage: mark region including double quotes, then execute M-/


;; file this into a Python script:

;; #!/usr/bin/python

;; import sys
;; data=sorted(sys.stdin.read().replace('\n', '').replace('\\', '').replace('"', '').split())
;; tabbed = ['\t' + name for name in data]
;; print '"\t\\\n'+ '\t\\\n'.join(tabbed) + '\t\\\n"'

;; fix scriptName below
;; add to .emacs



;; lifted from: http://ergoemacs.org/emacs/elisp_perl_wrapper.html

(defun do-something-region (startPos endPos)
  "Do some text processing on region.
This command calls the external script “wc”."
(interactive "r")
  (let (scriptName)
    (setq scriptName "/home/mah/omap-image-builder/emacs/fixpkglists.py") ; full path to your script
    (shell-command-on-region startPos endPos scriptName nil t nil t)
    ))

(global-set-key (kbd "M-/") 'do-something-region )
