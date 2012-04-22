;;; auto-shell-command.el --- 

;; Copyright (C) 2012 ongaeshi

;; Author: ongaeshi
;; Keywords: shell, save, async, deferred

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

;; 

;;; Code:

(eval-when-compile (require 'cl))
(require 'deferred)

;;; Parameter:

(defun auto-shell-command:notify (msg)
  (message msg)                                                    ; simple
  ;;(deferred:process-shell (format "growlnotify -m %s -t emacs" msg))  ; Growl(OSX)
  ;; (deferred:process-shell (format "growlnotify %s /t:emacs" msg))  ; Growl(Win)
  )

; 自動でコンパイルするか？
(defvar auto-shell-command:active t)

;;; Main:

(defun auto-shell-command:shell-deferred (arg &optional notify-start)
  (lexical-let ((arg arg)
                (notify-start notify-start)
                (result "success"))
    (deferred:$
      ;; before
      (deferred:next
        (lambda () (if notify-start (auto-shell-command:notify "start"))))
      ;; main
      (deferred:process-shell arg)
      (deferred:error it (lambda (err) (setq result "failed") err))
      ;; after
      (deferred:nextc it
        (lambda (x)
          (with-current-buffer (get-buffer-create "*Auto Shell Command*")
            (delete-region (point-min) (point-max))
            (insert x))
          (auto-shell-command:notify result))))))

; 自動コンパイルのON/OFF
(defun auto-shell-command:toggle ()
  (interactive)
  (if auto-shell-command:active
      (setq auto-shell-command:active nil)
    (setq auto-shell-command:active t))
  (message "auto-shell-command %s" auto-shell-command:active))

;; @latertodo C-cC-mに割り当て(後で外すかも)
(global-set-key "\C-c\C-m" 'auto-shell-command:toggle)

; 実行するコマンドリスト
;
; ex.
;   (setq auto-shell-command-setting
;         (("/path/to/dir/BBB/test" 'match-dir  "make test"                                ("cpp hpp"))
;          ("/path/to/dir/doc"      'match-dir  "make all doc"                             ("html"))
;          ("/path/to/dir/AAA"      'match-dir  "make all && (cd /path/to/dir/BBB/; make)")
;          ("/path/to/dir/BBB"      'match-dir  "(cd /path/to/dir/AAA/; make) && make")
;          ("/path/to/dir"          'buffer-dir "make")))
(defvar auto-shell-command-setting nil)

; 一つのコマンドを実行
(defun auto-shell-command:exec1 (path command)
  (if (string-match path (buffer-file-name))
      (progn
        (auto-shell-command:shell-deferred command)
        ; (auto-shell-command:shell-deferred command t) ; notify-start
        t)
    nil))

; auto-shell-commandの実行
(defun auto-shell-command:exec ()
  (interactive)
  (if auto-shell-command:active
      (find-if '(lambda (v) (apply 'auto-shell-command:exec1 v)) auto-shell-command-setting)))

; ファイルセーブ時にコンパイル
(add-hook 'after-save-hook 'auto-shell-command:exec)

(provide 'auto-shell-command)
;;; auto-shell-command.el ends here
