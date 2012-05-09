# auto-shell-command.el
ファイルセーブ時に指定したシェルコマンドを**非同期で**実行するelispです。似たようなツールとして *flymake* や *autotest* 、 *Guard* があります。

1. ファイル名にマッチする正規表現で実行するコマンドを指定
2. コマンドの実行を一時的に抑制出来る (まとめて複数のファイルを編集する時に便利)
3. Emacsが動く全てのOSで動作する。ファイルの監視からプロセスの実行までをEmacsの機能でまかなっているため。
4. Emacs再起動時に消える一時的なコマンドを登録することが出来る
5. 外部ツールによるファイル書き換えによって起こる、期待外れなコマンドの誤作動が起きない

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
(global-set-key "\C-c\C-m" 'ascmd:toggle)      ; 一時的にauto-shell-commandの実行をON/OFFする
(global-set-key (kbd "C-c C-,") 'ascmd:popup)  ; '*Auto Shell Command*'をポップアップする

;; 結果の通知をGrowlで行う (optional)
(defun ascmd:notify (msg) (deferred:process-shell (format "growlnotify -m %s -t emacs" msg))))

;; エラー時のポップアップを見やすくする (optional, '(require 'popwin)'が必要です)
(push '("*Auto Shell Command*" :height 20) popwin:special-display-config)
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
* $FILE "/path/to/dir/foo.c" -> "foo.c"
* $DIR  "/path/to/dir/foo.c" -> "/path/to/dir/"

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
(ascmd:add '("/path/test/runner.rb"          "rake test"))                     ; 'test/runner.rb'を触ったらフルテスト(時間がかかる)
(ascmd:add '("/path/test/test_/.*\.rb"       "ruby -I../lib -I../test $FILE")) ; 'test/test_*.rb'を触ったら編集したファイルだけを単体でテスト(時間節約)
```

ブラウザとの連携

```elisp
(ascmd:add '("Resources/.*\.js" "wget -O /dev/null http://0.0.0.0:9090/run")) ; 'Resources/*.js'以下を触ったら'http://0.0.0.0:9090/run'にアクセス
```

## 作者
* ongaeshi <ongaeshi0621@gmail.com>

## ライセンス
GPLv3

## Thanks
- [kiwanami/emacs-deferred](https://github.com/kiwanami/emacs-deferred)