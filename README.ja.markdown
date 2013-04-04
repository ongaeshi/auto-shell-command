auto-shell-command.el
=====================

ファイルセーブ時に指定したシェルコマンドを**非同期で**実行するelispです。似たようなツールとして *flymake* や *autotest* , *Guard* があります。

ファイルの監視からプロセスの実行など主要な機能はEmacsのAPIだけで実装しているため **Emacsが動く全てのOS**で動作します。

以下のような特徴を持ちます。

1. ファイル名をキーに実行するコマンドを指定します。同じ拡張子のファイルでも名前によって違うコマンドを指定することが可能です
2. コマンドの実行を一時的にサスペンドすることが出来ます。まとめて複数のファイルを編集する時に便利です
3. 特定のファイルに対して、一時的にコマンドを追加、上書きすることが出来ます
4. 外部ツールによるファイルの書き換えが起こってもコマンドは実行されません。予期しないファイル書き換えにより大量のプロセスが走ってしまうような事故は起きません

## インストール
*emacs-deferred* が必要です。

*auto-install* が使える人は以下のelispを実行して下さい。

```elisp:
(auto-install-from-url "https://github.com/kiwanami/emacs-deferred/raw/master/deferred.el")
(auto-install-from-url "https://raw.github.com/ongaeshi/auto-shell-command/master/auto-shell-command.el")
```

もしくは以下のファイルをロードパスの通った場所に置いて下さい。

* [deferred.el](https://raw.github.com/kiwanami/emacs-deferred/master/deferred.el)
* [auto-shell-command.el](https://raw.github.com/ongaeshi/auto-shell-command/master/auto-shell-command.el)

## 初期設定
```elisp:.eamcs.d/init.el
(require 'auto-shell-command)

;; キーバインドの設定
(global-set-key (kbd "C-c C-m") 'ascmd:toggle) ; Temporarily on/off auto-shell-command run
(global-set-key (kbd "C-c C-,") 'ascmd:popup)  ; Pop up '*Auto Shell Command*'
(global-set-key (kbd "C-c C-.") 'ascmd:exec)   ; Exec-command specify file name

;; ;; エラー時のポップアップを見やすくする
;; (push '("*Auto Shell Command*" :height 20 :noselect t) popwin:special-display-config)

;; ;; 結果の通知をGrowlで行う (optional)
;; (defun ascmd:notify (msg) (deferred:process-shell (format "growlnotify -m %s -t emacs" msg))))

```

## コマンドリストの設定
```elisp
;; コマンドの登録
(ascmd:add '("対象ファイルの正規表現" "ファイルセーブ時に実行するコマンド"))
;; 簡単な例
(ascmd:add '("/path/to/dir" "ls"))      ; '/path/to/dir'以下のファイルをセーブしたら`ls`を実行
;; 後に評価したS式が優先高
(ascmd:add '("/path/to/dir/foo.c" "ls -la"))      ; 'foo.c'だけは`ls -la`を実行
;; 特殊変数も使える
(ascmd:add '("/path/to/dir/.*\.c" "cat $FILE"))      ; それ以外の.cファイルは`cat ファイル名`を実行
```

## 特殊編集
* $FILE ... "/path/to/dir/foo.c" -> "foo.c"
* $DIR  ... "/path/to/dir/foo.c" -> "/path/to/dir/"

## サンプル
とある**C言語のプロジェクト**の設定例

```elisp
;; 下が優先高
(ascmd:add '("/path/to/dir"                  "make"))     ; 基本は'make'
(ascmd:add '("/path/to/dir/.gitignore"       "make run")) ; ルートフォルダ直下の'.gitignore'を触ったら'make run'(実行)
(ascmd:add '("/path/to/dir/doc"              "make doc")) ; 'doc'以下を触ったら'make doc'(ドキュメント生成)
(ascmd:add '("/path/to/dir/BBB"              "(cd /path/to/dir/AAA && make && cd ../BBB && make)")) ; BBBをビルドする時は先にAAAをビルドする必要が・・・(良くあることだよね？)
```

とある**Rubyプロジェクト**の設定例

```elisp
(ascmd:add '("junk/.*\.rb" "ruby $FILE"))                                      ; junk/以下のRubyスクリプトは無条件で実行
(ascmd:add '("/path/test/runner.rb"          "rake test"))                     ; 'test/runner.rb'を触ったらフルテスト(時間がかかる)
(ascmd:add '("/path/test/test_/.*\.rb"       "ruby -I../lib -I../test $FILE")) ; 'test/test_*.rb'を触ったら編集したファイルだけを単体でテスト(時間節約)
```

ブラウザとの連携

```elisp
(ascmd:add '("Resources/.*\.js" "wget -O /dev/null http://0.0.0.0:9090/run")) ; 'Resources/*.js'以下を触ったら'http://0.0.0.0:9090/run'にアクセス
```

## 一時的に使うコマンドを登録する
M-x ascmd:add を使います

* Path: 対象ファイル名(正規表現も使えます)
* Command: ファイルセーブ時に実行するコマンド

を指定して下さい。

### 設定例
1. M-x ascmd:add
2. Path: **/path/to/abc.rb**
3. Command: **ruby $FILE arg1**

*/path/to/abc.rb* をセーブするたびに *ruby /path/to/abc.rb arg1* が実行されます。この設定はEmacsを再起動すると消える一時的なものです。

### 再起動しても消えないようにする
M-x ascmd:add を実行すると *(ascmd:add '("/path/to/abc.rb" "ruby $FILE arg1"))* といったS式がキルリングにセーブされています。
これを .emacs.d/init.el 等に貼付けておけばOKです。

## ファイルを書き換えずに関連づけたコマンドを実行する
1. M-x ascmd:exec
2. 実行したいコマンドが登録されたファイルを指定します
3. ファイルの実体がなくても登録されたコマンドがあれば実行します

## ライセンス
GPLv3

## Thanks
- [kiwanami/emacs-deferred](https://github.com/kiwanami/emacs-deferred)

----
Copyright (C) 2012, 2013 ongaeshi <<ongaeshi0621@gmail.com>>
