# lambda_custom_runtime_bash

## 目的

以下の挙動を確認するための検証プロジェクト。

- Lambda のカスタムランタイムを使ったシェルスクリプトの実行
- 必要なライブラリのインストール
- aws cli の実行
- 環境変数の設定と参照
- Slack への通知
- シェルスクリプトから外部ファイルの参照

## 事前準備

### aws コマンドをインストールしておく

インストール方法は任意。Docker イメージでも構わない。

```sh
➜  aws --version
aws-cli/2.4.29 Python/3.9.12 Darwin/19.6.0 source/x86_64 prompt/off
```

AWS SAM を使ったデプロイが良ければ <https://docs.aws.amazon.com/ja_jp/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html> などを参考に `sam` をインストールしておく。

```sh
➜  sam --version
SAM CLI, version 1.47.0
```

### デプロイ先のプロファイルを登録しておく

IAM の credentials.csv を使用してプロファイルを登録する。
CLI から Lambda へデプロイするために必要。

### ロールを作成しておく

マネジメントコンソールなどで以下のポリシーを付与したロールを作成する。

- AmazonS3ReadOnlyAccess
- AWSLambdaExecute

## デプロイ

### 初回（新規登録）

以下のファイルを zip に固める。

- bootstrap
- function.sh
- filter.conf

```sh
➜  zip function.zip function.sh bootstrap filter.conf
```

作成した zip ファイルを `aws lambda` を使って Lambda にデプロイする。

```sh
➜  aws lambda create-function --function-name {関数名} --zip-file fileb://function.zip --handler function.handler --runtime provided --role arn:aws:iam::XXX:role/{ロール名} --profile {プロファイル名}
```

- {関数名}：任意の名前を付ける
- arn:aws:iam::XXX:role/{ロール名}：事前準備で作成した ARN を指定する
- {プロファイル名}：事前準備で登録したプロファイル名を指定する

### プログラムの更新

以下のファイルを zip に固める。

- bootstrap
- function.sh
- filter.conf

```sh
➜  zip function.zip function.sh bootstrap filter.conf
```

作成した zip ファイルを `aws lambda` を使って Lambda にデプロイする。

```sh
➜  aws lambda update-function-code --function-name {関数名} --zip-file fileb://function.zip --profile {プロファイル名}
```

- {関数名}：任意の名前を付ける
- {プロファイル名}：事前準備で登録したプロファイル名を指定する

## 環境変数の登録／更新

Lambda に次の環境変数を設定しておき、プログラムから値を参照する。

| キー | 用途 |
| :---: | :--- |
| BUCKET | プログラムから参照する S3 のバケット名 |
| GREP | S3 からダウンロードしたファイルを `grep` する正規表現 |
| SLACK_WEBHOOK_URL | 実行結果を通知する Slack の Webhook URL |

これらの環境変数は environment.conf に定義する。
environment.conf は environment.conf.sample をコピーして作成する。

```sh
➜  cp environment.conf.sample environment.conf

➜  cat environment.conf
GREP="value1"
BUCKET="value2"
SLACK_WEBHOOK_URL="value3"

➜  vim environment.conf  #=> エディタで environment.conf の value1, value2 などを適切な内容に更新する
```

環境変数を `aws lambda` を使って Lambda に反映する。

```sh
➜  aws lambda update-function-configuration --function-name {関数名} --environment Variables={`cat environment.conf | tr -s "\n" | tr '\n' ','`} --profile {プロファイル名}
```

- {関数名}：任意の名前を付ける
- {プロファイル名}：事前準備で登録したプロファイル名を指定する

Variables は `Variables='{GREP="value1",BUCKET="value2"}'` の形式で指定する。
シングルクォートで全体を囲み、それぞれの値はダブルクォートで囲むこと。

ただし、少々面倒なので、以下のコマンドにより environment.conf を読み込んで指定の形式に分解できる。

```sh
{`cat environment.conf | tr -s "\n" | tr '\n' ','`}
```

## フィルタの設定

WAF を通過した URI をリストする。
通過した URI はアプリケーション的に正しい URI が多いため、`grep -v` で除外する。
この除外する URI は filter.conf に定義する。
filter.conf は filter.conf.sample をコピーして作成する。

```sh
➜  cp filter.conf.sample filter.conf

➜  cat filter.conf
uri1
uri2
uri3

➜  vim filter.conf  #=> エディタで filter.conf の uri1, uri2 などを適切な内容に更新する
```

## AWS SAM によるデプロイ

### 扱うファイルの説明

以下のファイルは CLI だろうと SAM でも必要なファイル。SAM 用に更新する、といった作業も不要。

- bootstrap
- filter.conf
- function.sh

以下は SAM 版では不要になる。別のファイルに置き換わる、もしくは SAM が処理してくれる。

- environment.conf → template.yaml に定義するため不要
- function.zip → `sam` が自動的に zip を作成し、AWS に送信するため不要

以下は SAM 版では必須になる。

- Makefile
- samconfig.toml
- template.yaml

#### Makefile

ビルドの実行手順を Makefile として作成する。
このプログラムでは bootstrap, filter.conf, function.sh のファイルが必要になるため、それらを `ARTIFACTS_DIR` にコピーするだけになる。

ちなみに、このプロジェクトの場合 `ARTIFACTS_DIR` は `.aws-sam/build/BashCustomRuntimeFunction` になる。

#### samconfig.toml

SAM の設定を定義する。

samconfig.toml は samconfig.toml.sample をコピーして作成する。
"# TBD" の部分を適宜更新すること。

```sh
➜  cp samconfig.toml.sample samconfig.toml

➜  vim samconfig.toml  #=> エディタで samconfig.toml の TBD を適切な内容に更新する
```

#### template.yaml

デプロイする各 AWS サービスの設定を定義する。

template.yaml は template.yaml.sample をコピーして作成する。

"# TBD" の部分を適宜更新すること。

EventBridge によって毎日 9:30 に定期実行する設定となっている点に注意すること。

```sh
➜  cp template.yaml.sample template.yaml

➜  vim template.yaml  #=> エディタで template.yaml の TBD を適切な内容に更新する
```

### ビルド

プロジェクト直下で `sam build` を実行する。

```sh
➜  sam build
```

### デプロイ

プロジェクト直下で `sam deploy` を実行する。

```sh
➜  sam deploy --profile {プロファイル名}
```

- {プロファイル名}：事前準備で登録したプロファイル名を指定する
