# Exment 自動テストの実行

この環境で、Exment 本体の自動テスト（PHPUnit）を実行する手順です。
Exment の CI（exceedone/exment の `.github/workflows/unittest.yml`）と同じ流れです。

## 準備

docker-exment のフォルダで、次のようにソースを配置します。

```bash
$ git clone https://github.com/exceedone/docker-exment.git
$ cd docker-exment
$ git clone https://github.com/exceedone/exment-boilerplate.git exment-boilerplate
# テストしたい Exment 本体
$ git clone https://github.com/exceedone/exment.git exment-boilerplate/exment
# composer.dev.lock は exment-admin-core をこのフォルダから読み込みます
$ git clone https://github.com/exceedone/exment-admin-core.git exment-boilerplate/exment-admin-core
```

## 環境の作成

MySQL の例です。MariaDB は `mariadb`、SQL Server は `sqlsrv` に読み替えてください。

```bash
# コンテナを起動
$ make mysql-up

# 開発用の composer ファイルに差し替え（./exment の Exment 本体を使うようになります）
$ docker compose -f docker-compose.yml exec -T php cp composer.dev.json composer.json
$ docker compose -f docker-compose.yml exec -T php cp composer.dev.lock composer.lock

# composer install、.env の作成、キーの作成
$ make mysql-init
```

## テストの実行

```bash
# Unit テスト
$ docker compose -f docker-compose.yml exec -T php composer run exment:test:unit

# Feature テスト
$ docker compose -f docker-compose.yml exec -T php composer run exment:test:feature

# Browser テスト
$ docker compose -f docker-compose.yml exec -T php composer run exment:test:browser
```

テストを始める前に `php artisan exment:inittest` が実行され、データベースは初期化されます。
大事なデータが入っている環境では実行しないでください。

## カバレッジの取得

PCOV はふだんは無効です（`docker/php/volumes/php.ini` の `pcov.enabled=0`）。
次のコマンドを使うと、その実行の間だけ PCOV を有効にしてカバレッジを取得します。

```bash
# Unit + Feature を実行して、結果をまとめる
$ make test-coverage

# 個別に実行する場合
$ make test-coverage-unit
$ make test-coverage-feature
$ make test-coverage-merge

# Browser テスト（PCOV では落ちるため、カバレッジなしで実行）
$ make test-browser
```

結果は `exment-boilerplate/storage/logs/coverage/` に出力されます。
