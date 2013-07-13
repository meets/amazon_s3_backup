# s3-backup
バックアップファイルをAmazonS3にアップロードするrakeタスク。


## セットアップ
	bundle install --path vendor/bundle


## 実行
	bin/backup.sh

または

	bundle exec rake backup


# バックアップ対象の作成
適当に圧縮すれば良いが、md5値が同一であればアップロードしない処理が入るので、変更がないものは再圧縮しないほうが効率は良い。
gistの方に適当な圧縮スクリプトは配置済み。

[tarpack.sh](https://gist.github.com/meets/5989994)


# s3のアレコレ
バケットの作成や各種プロパティ設定はAWSのコンソールから予め行う事を前提にしていることに注意。

各種設定を行ったバケットを用意し、IAMで制限ユーザを作成してアップロードさせる。

ユーザの作成はgistにメモしてある。

[https://gist.github.com/meets/5990119](https://gist.github.com/meets/5990119)