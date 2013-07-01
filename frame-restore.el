;;; frame-restore.el --- Restore Emacs frame -*- lexical-binding: t; -*-

;; Copyright (c) 2012, 2013 Sebastian Wiesner <lunaryorn@gmail.com>
;;
;; Author: Sebastian Wiesner <lunaryorn@gmail.com>
;; URL: https://github.com/lunaryorn/frame-restore.el
;; Keywords:  frames convenience
;; Version: 0.1
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

;; Save and restore parameters of Emacs frames.

;; Just call `frame-restore' in your `init.el':
;;
;;    (frame-restore)

;;; Code:

(require 'dash)

(defgroup frame-restore nil
  "Save and restore frame parameters."
  :group 'frames
  :link '(url-link :tag "Github" "https://github.com/lunaryorn/frame-restore.el")
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

(defcustom frame-restore-initial-frame t
  "Whether to restore the parameters of the initial frame.

If t, restore the frame, otherwise don't."
  :type 'boolean
  :group 'frame-restore)

(defun frame-restore--write-parameters (params)
  "Write PARAMS to `frame-restore-parameters-file'."
  (with-temp-file frame-restore-parameters-file
    (prin1 (--filter (memq (car it) frame-restore-parameters) params)
           (current-buffer))
    (terpri (current-buffer))))

(defun frame-restore-save-parameters ()
  "Save frame parameters of the currently selected frame.

Save parameters in `frame-restore-parameters' to
`frame-restore-parameters-file'.

Return t, if the parameters were saved, or nil otherwise."
  (condition-case nil
      (when (display-graphic-p) ; GUI frames only!
        (frame-restore--write-parameters (frame-parameters))
        t)
    (file-error nil)))

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
      (--filter (memq (car it) frame-restore-parameters) params))))

(defun frame-restore-initial-frame ()
  "Restore the frame parameters of the initial frame.

Load parameters in `frame-restore-parameters' from
`frame-restore-parameters-file' and update `initial-frame-alist'
accordingly.

Return the new `initial-frame-alist', or nil if reading failed."
  (condition-case nil
      (-when-let* ((params (frame-restore--read-parameters)))
        (setq initial-frame-alist
              (frame-restore--add-alists params initial-frame-alist)))
    (error nil)))

;;;###autoload
(defun frame-restore ()
  "Save and restore parameters of the Emacs frame."
  (unless noninteractive                ; Skip noninteractive sessions
    (add-hook 'kill-emacs-hook #'frame-restore-save-parameters)
    (when frame-restore-initial-frame
      (add-hook 'after-init-hook #'frame-restore-initial-frame))))

(provide 'frame-restore)

;;; frame-restore.el ends here
