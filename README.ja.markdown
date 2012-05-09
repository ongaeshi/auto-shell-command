# README.ja

## 名前
auto-shell-command.el

## 概要
ファイルセーブ時に指定したシェルコマンドを(非同期で)実行するelispです。似たようなツールとして *flymake* や *autotest* 、 *Guard* があります。

[ongaeshi/auto-shell-command - Github](https://github.com/ongaeshi/auto-shell-command)

## 特徴
1. **ファイル名単位** で実行するコマンドを指定することが出来る
2. **一時的にコマンドの実行をON/OFF**することが出来る(まとめて複数のファイルを編集する時に便利)
3. ファイルの監視からプロセスの実行までEmacsの機能でまかなっているため安定して動作する。Emacsが動く全てのOSで動作する。
4. 外部ツールによるファイル書き換えによって起こる期待していなかったコマンドの誤作動が起きない
5. Emacs再起動時に消える一時的なコマンドを登録することが出来る

## インストール
*emacs-deferred* のインストールが必要です。

*auto-install* が使える人は以下のelispを実行して下さい。

```elisp:
(auto-install-from-url "https://github.com/kiwanami/emacs-deferred/raw/master/deferred.el")
(auto-install-from-url "https://raw.github.com/ongaeshi/auto-shell-command/master/auto-shell-command.el")
```

もしくは以下のファイルをロードパスの通った場所に置いて下さい。

1. [deferred.el](https://raw.github.com/kiwanami/emacs-deferred/master/deferred.el)
2. [auto-shell-command.el](https://raw.github.com/ongaeshi/auto-shell-command/master/auto-shell-command.el)

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

## コマンドリストの設定例
```elisp
;; コマンドの登録
(ascmd:add '("対象ファイルの正規表現" "ファイルセーブ時に実行するコマンド"))

;; 後に評価したS式が優先高
(ascmd:add '("…" "…"))
```

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
