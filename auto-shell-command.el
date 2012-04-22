;;; auto-shell-command.el --- 

;; Copyright (C) 2012 ongaeshi

;; Author: ongaeshi
;; Keywords: shell, auto, async

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

;;; Code:

; 後でdeferredへの依存を無くす？
(defun auto-shell-command:shell-deferred (arg)
  (deferred:$
    (deferred:process-shell arg)
    (deferred:nextc it
      (lambda (x)
        (with-current-buffer (get-buffer-create "*Auto Shell Command*")
          (delete-region (point-min) (point-max))
          (insert x))
        ; (deferred:process-shell "growlnotify success /t:emacs /i:c:/app/emacs/bin/emacs.ico"))))) ; win
        (deferred:process-shell "growlnotify -m success -t emacs"))))) ; OSX

; 自動でコンパイルするか？
(defvar auto-shell-command:active t)

; 自動コンパイルのON/OFF
(defun auto-shell-command:toggle ()
  (interactive)
  (if auto-shell-command:active
      (setq auto-shell-command:active nil)
    (setq auto-shell-command:active t))
  (message "auto-shell-command %s" auto-shell-command:active))

;; C-cC-mに割り当て(後で外すかも)
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
