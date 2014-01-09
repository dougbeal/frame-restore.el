;;; frame-restore.el --- Restore Emacs frame -*- lexical-binding: t; -*-

;; Copyright (c) 2012, 2013 Sebastian Wiesner <lunaryorn@gmail.com>
;;
;; Author: Sebastian Wiesner <lunaryorn@gmail.com>
;; URL: https://github.com/lunaryorn/frame-restore.el
;; Keywords:  frames convenience
;; Version: 0.2-cvs
;; Package-Requires: ((dash "1.2") (emacs "24.1"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Save and restore selected parameters of Emacs frames.

;; Just call `frame-restore' in your `init.el':
;;
;;    (frame-restore)

;;; Code:

(require 'dash)

(defgroup frame-restore nil
  "Save and restore frame parameters."
  :group 'frames
  :link '(url-link :tag "Github" "https://github.com/dougbeal/frame-restore.el")
  :link '(emacs-commentary-link :tag "Commentary" "frame-restore")
  :link '(emacs-library-link :tag "Source" "frame-restore"))

(defcustom frame-restore-parameters-file
  (locate-user-emacs-file "frame-restore-parameters")
  "File to store frame parameters in."
  :type 'file
  :group 'frame-restore)

(defcustom frame-restore-parameters
  '(left top width height maximized fullscreen)
  "Frame parameters to save and restore.

See Info node `(elisp)Frame Parameters' for information about
frame parameters."
  :type '(repeat (symbol :tag "Frame parameter"))
  :group 'frame-restore)

(defcustom frame-restore-save-parameters t
  "Whether to save parameters when Emacs exits.

If t, save selected `frame-restore-parameters' from all frames."
  :type 'boolean
  :group 'frame-restore)

(defcustom frame-restore-frames t
  "Whether to restore the parameters of the saved frames.

If t, restore frames and saved parameters from `frame-restore-parameters-file'."
  :type 'boolean
  :group 'frame-restore)

(defun frame-restore--filter-parameters (params)
  "Filter out frame PARAMS not in the `frame-restore-parameters'."
  (--filter (memq (car it) frame-restore-parameters) params)
  )

(defun frame-restore--write-parameters (frame-params)
  "Write FRAME-PARAMS to `frame-restore-parameters-file'."
  (with-temp-file frame-restore-parameters-file
    (prin1 (-mapcat (lambda (params)
                      (list (frame-restore--filter-parameters params)))
                    frame-params)
           (current-buffer))
           (terpri (current-buffer))))

(defun frame-restore-save-parameters ()
  "Save parameters in `frame-restore-parameters' of each frame to
`frame-restore-parameters-file'.

Return t, if the parameters were saved, or nil otherwise."
  (condition-case err
      (when (display-graphic-p) ; GUI frames only!
        (frame-restore--write-parameters 
         (-map-when 'display-graphic-p 'frame-parameters (frame-list)))
        t)
    (file-error 
     (setq message-log-max t)
     (message 
      "error: %s" (error-message-string err)))))



(defun frame-restore--add-alists (a b)
  "Add alist A to B and return the result.

Remove duplicate keys."
  (append a (--remove (assq (car it) a) b) nil))

(defun frame-restore--read-parameters ()
  "Read parameters from `frame-restore-parameters-file'."
  (with-temp-buffer
    (insert-file-contents frame-restore-parameters-file)
    (goto-char (point-min))
    (-when-let (params (read (current-buffer)))
      (-map  (lambda (frame-params)
               (--filter (memq (car it) frame-restore-parameters) frame-params))
             params)    
      )

    ))
      

(defun frame-restore-initial-frame ()
  "Restore the frame parameters of the initial frame.

Load parameters in `frame-restore-parameters' from
`frame-restore-parameters-file' and update `initial-frame-alist'
accordingly.

Return the new `initial-frame-alist', or nil if reading failed."
  (with-demoted-errors
      (-when-let* ((params (frame-restore--read-parameters)))
        (setq 
         initial-frame-alist         (frame-restore--add-alists (car params) initial-frame-alist)
         frame-restore-subsequent-frame-parameters (cdr params))
        (message "frame-restore: %s" initial-frame-alist))
      (frame-restore-subsequent-frames)))


(defun frame-restore-subsequent-frames ()
  "Restore the frame parameters of subsequent frames.

`frame-restore-initial-frame' must be called first."
  (--each frame-restore-subsequent-frame-parameters
    (make-frame it)
    (message "frame-restore: %s" it)))

;;;###autoload
(defun frame-restore ()
  "Install hooks to save and restore selected parameters every Emacs frame."
  (if (and (display-graphic-p) (not noninteractive)) 
      (progn
        (when frame-restore-save-parameters
          (add-hook 'kill-emacs-hook 'frame-restore-save-parameters))
        (when frame-restore-frames
          (add-hook 'after-init-hook 'frame-restore-initial-frame)))
    (message "frame-restore: noninteractive or doesn't support frames")))



(provide 'frame-restore)

;; Local Variables:
;; coding: utf-8
;; End:

;;; frame-restore.el ends here
