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

;; 'auto-shell-command.el'は、ファイルセーブ時に指定したシェルコマンドを実行することが出来るものです。
;; 似たようなツールとしてはflymakeやautotest、Guardといったものがあります。

;; 特徴
;;   1. ファイル名単位で実行するコマンドを指定することが出来る
;;   2. 一時的にコマンドの実行をON/OFFすることが出来る(まとめて複数のファイルを編集する時に便利)
;;   3. ファイルの監視からプロセスの実行までを全てEmacsの機能でまかなえるため安定して動作する、全てのOSで動く
;;   4. 外部ツール(git revert等)によるファイル書き換えによって、期待していなかったコマンドの誤作動が起きない
;;   5. Emacs再起動時に消える刹那的なコマンドを登録することが出来る

;; URL
;;   https://github.com/ongaeshi/auto-shell-command/blob/master/auto-shell-command.el

;;; Install:

;; Need 'emacs-deferred'
;;   (auto-install-from-url https://github.com/kiwanami/emacs-deferred/raw/master/deferred.el")
;;   (auto-install-from-url "https://raw.github.com/ongaeshi/auto-shell-command/master/auto-shell-command.el")

;;; Setting:

;; (require 'auto-shell-command)

;; ;; Shortcut setting (Temporarily on/off auto-shell-command run)
;; (global-set-key "\C-c\C-m" 'ascmd:toggle)      ; Temporarily on/off auto-shell-command run
;; (global-set-key (kbd "C-c C-,") 'ascmd:popup)  ; Pop up '*Auto Shell Command*'

;; ;; Notification of results to Growl (optional)
;; (defun ascmd:notify (msg) (deferred:process-shell (format "growlnotify -m %s -t emacs" msg))))

;; ;; Easier to popup on errors (optional, need '(require 'popwin)')
;; (push '("*Auto Shell Command*" :height 20) popwin:special-display-config)

;;; Command-list Setting:

;; ;; とあるCプロジェクトの設定例 (下が優先高)
;; (ascmd:add '("/path/to/dir"                  "make"))     ; 基本は'make'
;; (ascmd:add '("/path/to/dir/.gitignore"       "make run")) ; ルートフォルダ直下の'.gitignore'を触ったら'make run'(実行)
;; (ascmd:add '("/path/to/dir/doc"              "make doc")) ; 'doc'以下を触ったら'make doc'(ドキュメント生成)
;; (ascmd:add '("/path/to/dir/BBB"              "(cd /path/to/dir/AAA && make && cd ../BBB && make)")) ; BBBをビルドする時は先にAAAをビルドする必要が・・・(良くあることだよね？)

;; ;; とあるRubyプロジェクトの設定例
;; (ascmd:add '("/path/test/runner.rb"          "rake test"))                     ; 'test/runner.rb'を触ったらフルテスト(時間がかかる)
;; (ascmd:add '("/path/test/test_/.*\.rb"       "ruby -I../lib -I../test $FILE")) ; 'test/test_*.rb'を触ったら編集したファイルだけを単体でテスト(時間節約)

;; ;; ブラウザとの連携
;; (ascmd:add '("Resources/.*\.js" "wget -O /dev/null http://0.0.0.0:9090/run")) ; 'Resources/*.js'以下を触ったら'http://0.0.0.0:9090/run'にアクセス

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
