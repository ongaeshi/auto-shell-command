auto-shell-command.el
=====================

Run the shell command **asynchronously** that you specified when you save the file. 
And there *flymake* *autotest*, is *Guard* as a similar tool.

1. Specify target file's regexp and command to execute when the save
2. Can temporarily suspend the execution of the command
3. Emacs is running on the OS of all work
4. It is possible to register a temporary command disappear restart Emacs
5. Caused by rewriting the file does not occur by external tools, malfunctions of the command disappointing

## Install
Requires *emacs-deferred*.

People can use the *auto-install*. Please execute the following elisp.

```elisp:
(auto-install-from-url "https://github.com/kiwanami/emacs-deferred/raw/master/deferred.el")
(auto-install-from-url "https://raw.github.com/ongaeshi/auto-shell-command/master/auto-shell-command.el")
```

Also put the location of the load path through the following files or.

* [deferred.el](https://raw.github.com/kiwanami/emacs-deferred/master/deferred.el)
* [auto-shell-command.el](https://raw.github.com/ongaeshi/auto-shell-command/master/auto-shell-command.el)

## Initial setting
```elisp:.eamcs.d/init.el
(require 'auto-shell-command)

;; Set of key bindings
(global-set-key (kbd "C-c C-m") 'ascmd:toggle) ; Temporarily on/off auto-shell-command run
(global-set-key (kbd "C-c C-,") 'ascmd:popup)  ; Pop up '*Auto Shell Command*'
(global-set-key (kbd "C-c C-.") 'ascmd:exec)   ; Exec-command specify file name

;; ;; Popup on errors
;; (push '("*Auto Shell Command*" :height 20 :noselect t) popwin:special-display-config)

;; ;; Notification of results to Growl (optional)
;; (defun ascmd:notify (msg) (deferred:process-shell (format "growlnotify -m %s -t emacs" msg))))
```

## Command list setting
```elisp
;; Register command
(ascmd:add '("Target file's regexp" "Command to be executed when the file save"))
;; A simple example
(ascmd:add '("/path/to/dir" "ls"))      ; After you have run the `ls` save the following files: '/path/to/dir'
;; High priority S-exp was evaluated after
(ascmd:add '("/path/to/dir/foo.c" "ls -la"))      ; 'foo.c' will only run the `ls-la`
;; Special variables
(ascmd:add '("/path/to/dir/.*\.c" "cat $FILE"))      ; Other .c file run the `cat FILE_NAME`
```

## Special variables
* $FILE ... "/path/to/dir/foo.c" -> "foo.c"
* $DIR  ... "/path/to/dir/foo.c" -> "/path/to/dir/"

## Samples
Configuration example of **C**

```elisp
;; High priority under
(ascmd:add '("/path/to/dir"                  "make"))     ; Exec 'make'
(ascmd:add '("/path/to/dir/.gitignore"       "make run")) ; If you touch beneath the root folder '. gitignore' -> 'make run'
(ascmd:add '("/path/to/dir/doc"              "make doc")) ; If you touch the folloing 'doc' -> 'make doc'
(ascmd:add '("/path/to/dir/BBB"              "(cd /path/to/dir/AAA && make && cd ../BBB && make)")) ; When you build the BBB, need to build the first AAA
```

Configuration example of **Ruby**

```elisp
(ascmd:add '("/path/test/runner.rb"          "rake test"))                     ; If you touch 'test/runner.rb' -> 'rake test' (Take time)
(ascmd:add '("/path/test/test_/.*\.rb"       "ruby -I../lib -I../test $FILE")) ; If you touch 'test/test_*.rb', test by itself only the edited file (Time-saving)
```

Cooperation with the browser

```elisp
(ascmd:add '("Resources/.*\.js" "wget -O /dev/null http://0.0.0.0:9090/run")) ; If you touch the following: 'Resources/*.js' access to 'http://0.0.0.0:9090/run'
```

## Lisence
GPLv3

## Thanks
- [kiwanami/emacs-deferred](https://github.com/kiwanami/emacs-deferred)

----
Copyright (C) 2012, 2013 ongaeshi <<ongaeshi0621@gmail.com>>
