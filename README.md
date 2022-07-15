# lambda_custom_runtime_bash

## 用途

以下の挙動を確認するため検証のプロジェクト。

- Lambda のカスタマイズランタイムを使ったシェルスクリプトの実行
- 必要なライブラリのインストール
- aws cli の実行
- 環境変数の設定と参照

## 事前準備

### aws コマンドをインストールしておく

インストール方法は任意。Docker イメージでも構わない。

```sh
➜  aws --version
aws-cli/2.4.29 Python/3.9.12 Darwin/19.6.0 source/x86_64 prompt/off
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

```sh
➜  zip function.zip function.sh bootstrap
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

```sh
➜  zip function.zip function.sh bootstrap
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

これらの環境変数は environment.conf に定義する。
environment.conf は environment.conf.sample をコピーして作成する。

```sh
➜  cp environment.conf.sample environment.conf

➜  cat environment.conf
GREP="value1"
BUCKET="value2"

➜  vim environment.conf  #=> エディタで environment.conf の value1, value2 を適切な内容に更新する
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
