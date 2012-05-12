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

;; Run the shell command asynchronously that you specified when you save the file. 
;; And there flymake autotest, is Guard as a similar tool.

;; Feature
;;   1. Speicify targete file's regexp and command to execute when the save
;;   2. Can temporarily suspend the execution of the command
;;   3. Emacs is running on the OS of all work
;;   4. It is possible to register a temporary command disappear restart Emacs
;;   5. Caused by rewriting the file does not occur by external tools, malfunctions of the command disappointing

;; URL
;;   https://github.com/ongaeshi/auto-shell-command

;;; Install:

;; Require 'emacs-deferred'
;;   (auto-install-from-url "https://github.com/kiwanami/emacs-deferred/raw/master/deferred.el")
;;   (auto-install-from-url "https://raw.github.com/ongaeshi/auto-shell-command/master/auto-shell-command.el")

;;; Initlial Setting:

;; (require 'auto-shell-command)

;; ;; Shortcut setting (Temporarily on/off auto-shell-command run)
;; (global-set-key "\C-c\C-m" 'ascmd:toggle)      ; Temporarily on/off auto-shell-command run
;; (global-set-key (kbd "C-c C-,") 'ascmd:popup)  ; Pop up '*Auto Shell Command*'

;; ;; Notification of results to Growl (optional)
;; (defun ascmd:notify (msg) (deferred:process-shell (format "growlnotify -m %s -t emacs" msg))))

;; ;; Easier to popup on errors (optional, need '(require 'popwin)')
;; (push '("*Auto Shell Command*" :height 20) popwin:special-display-config)

;;; Command-list Setting:

;; ;; High priority under
;; (ascmd:add '("/path/to/dir"                  "make"))     ; Exec 'make'
;; (ascmd:add '("/path/to/dir/.gitignore"       "make run")) ; If you touch beneath the root folder '. gitignore' -> 'make run'
;; (ascmd:add '("/path/to/dir/doc"              "make doc")) ; If you touch the folloing 'doc' -> 'make doc'
;; (ascmd:add '("/path/to/dir/BBB"              "(cd /path/to/dir/AAA && make && cd ../BBB && make)")) ; When you build the BBB, need to build the first AAA

;; Configuration example of Ruby
;; (ascmd:add '("/path/test/runner.rb"          "rake test"))                     ; If you touch 'test/runner.rb' -> 'rake test' (Take time)
;; (ascmd:add '("/path/test/test_/.*\.rb"       "ruby -I../lib -I../test $FILE")) ; If you touch 'test/test_*.rb', test by itself only the edited file (Time-saving)

;; Cooperation with the browser
;; (ascmd:add '("Resources/.*\.js" "wget -O /dev/null http://0.0.0.0:9090/run")) ; If you touch the following: 'Resources/*.js' access to 'http://0.0.0.0:9090/run'

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
(defun ascmd:add (v)
  (interactive)
  (push v ascmd:setting))

;; Result buffer name
(defvar ascmd:buffer-name "*Auto Shell Command*")

;; Pop up '*Auto Shell Command*'
(defun ascmd:popup ()
  (interactive)
  (pop-to-buffer ascmd:buffer-name))

;;; Private:

;; Command list
(setq ascmd:setting nil)

;; Exec-command when you save file
(add-hook 'after-save-hook 'ascmd:exec)

(defun ascmd:exec ()
  (interactive)
  (if ascmd:active
      (find-if '(lambda (v) (apply 'ascmd:exec1 (buffer-file-name) v)) ascmd:setting)))

(defun ascmd:exec-file-name (file-name)
  (interactive "fSpecify target file :")
  (find-file file-name)                 ; Don't work when use 'save-window-excursion'
  (find-if '(lambda (v) (apply 'ascmd:exec1 file-name v)) ascmd:setting))

;; ;; Experiment : To run the command without having to buffer switching
;; (defun ascmd:exec-file-name (file-name)
;;   (interactive "fSpecify target file :")
;;   (lexical-let ((file-name file-name)
;;                 (buffer (current-buffer)))
;;     (deferred:$
;;       (deferred:next
;;         (lambda ()
;;           (find-file file-name)                 ; Don't work when use 'save-window-excursion'
;;           (find-if '(lambda (v) (apply 'ascmd:exec1 file-name v)) ascmd:setting)))
;;       (deferred:wait 100)
;;       (deferred:nextc it
;;         (lambda () (switch-to-buffer buffer))))))

(defun ascmd:exec1 (file-name path command)
  (if (string-match path file-name)
      (progn
        (ascmd:shell-deferred (ascmd:query-reqplace command file-name))
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
        (lambda ()
          (if notify-start (ascmd:notify "start"))
          (setq ascmd:process-count (+ ascmd:process-count 1))))
      ;; main
      (deferred:process-shell arg)
      (deferred:error it (lambda (err) (setq result "failed") (pop-to-buffer ascmd:buffer-name) err))
      ;; after
      (deferred:nextc it
        (lambda (x)
          (with-current-buffer (get-buffer-create ascmd:buffer-name)
            (delete-region (point-min) (point-max))
            (insert x))
          (setq ascmd:process-count (- ascmd:process-count 1))
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

;; Display mode-line
(setq ascmd:process-count 0)

(defun ascmd:process-count-clear ()
  (interactive)
  (setq ascmd:process-count 0))

(defun ascmd:display-process-count ()
  (if (> ascmd:process-count 0)
      (format "[ascmd:%d] " ascmd:process-count)
    ""))

(add-to-list 'default-mode-line-format
             '(:eval (ascmd:display-process-count)))

(provide 'auto-shell-command)
;;; auto-shell-command.el ends here
