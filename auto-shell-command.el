;;; auto-shell-command.el --- 

;; Copyright (C) 2012 ongaeshi

;; Author: ongaeshi
;; Keywords: shell, save, async, deferred, auto

;; This program is free software; you can redistribute it and/or modify
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

;; @todo

;;; Samples:

;; @todo
;; ex.
;;  書き直す
;;   (setq auto-shell-command:setting
;;         (("/path/to/dir/BBB/test" 'match-dir  "make test"                                ("cpp hpp"))
;;          ("/path/to/dir/doc"      'match-dir  "make all doc"                             ("html"))
;;          ("/path/to/dir/AAA"      'match-dir  "make all && (cd /path/to/dir/BBB/; make)")
;;          ("/path/to/dir/BBB"      'match-dir  "(cd /path/to/dir/AAA/; make) && make")
;;          ("/path/to/dir"          'buffer-dir "make")))

;;; Code:

(eval-when-compile (require 'cl))
(require 'deferred)

(setq ascmd:version "0.1")

;;; Public:

;; Notify function
(defun ascmd:notify (msg)
  (message msg)                                                        ; emacs's message function
  ;;(deferred:process-shell (format "growlnotify -m %s -t emacs" msg)) ; Growl(OSX)
  ;;(deferred:process-shell (format "growlnotify %s /t:emacs" msg))   ; Growl(Win)
  )

;; Toggle after-save-hook (Recommended to set the key bindings)
(defun ascmd:toggle ()
  (interactive)
  (if ascmd:active
      (setq ascmd:active nil)
    (setq ascmd:active t))
  (message "auto-shell-command %s" ascmd:active))

(defvar ascmd:active t)

;; Add to command list
(defun ascmd:add (v) (push v ascmd:setting))

;; Result buffer name
(defvar ascmd:buffer-name "*Auto Shell Command*")

;;; Private:

;; Command list
(setq ascmd:setting nil)

;; Exec-command when you save file
(add-hook 'after-save-hook 'ascmd:exec)

(defun ascmd:exec ()
  (interactive)
  (if ascmd:active
      (find-if '(lambda (v) (apply 'ascmd:exec1 v)) ascmd:setting)))

(defun ascmd:exec1 (path command)
  (if (string-match path (buffer-file-name))
      (progn
        (ascmd:shell-deferred (ascmd:query-reqplace command (buffer-file-name)))
        ; (ascmd:shell-deferred command t) ; notify-start
        t)
    nil))

(defun ascmd:shell-deferred (arg &optional notify-start)
  (lexical-let ((arg arg)
                (notify-start notify-start)
                (result "success"))
    (deferred:$
      ;; before
      (deferred:next
        (lambda () (if notify-start (ascmd:notify "start"))))
      ;; main
      (deferred:process-shell arg)
      (deferred:error it (lambda (err) (setq result "failed") (pop-to-buffer ascmd:buffer-name) err))
      ;; after
      (deferred:nextc it
        (lambda (x)
          (with-current-buffer (get-buffer-create ascmd:buffer-name)
            (delete-region (point-min) (point-max))
            (insert x))
          (ascmd:notify result))))))

;; query-replace special variable
(defun ascmd:query-reqplace (command match-path)
  (let (
        (file-name (file-name-nondirectory match-path))
        (dir-name  (file-name-directory match-path))
        (command command)
        )
    (setq command (replace-regexp-in-string "$FILE" file-name command t))
    (setq command (replace-regexp-in-string "$DIR" dir-name command t))
    command))

(provide 'auto-shell-command)
;;; auto-shell-command.el ends here
