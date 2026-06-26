# portfolio-01-osaka-weather

大阪の天気データを用いたサーバーレスデータレイクパイプライン

## アーキテクチャ

[EventBridge: 毎日7時(JST)] → [Lambda: Python] → [S3: JSON Lines]
↓
[Glue Crawler] → [Athena: SQL]
↓
[QuickSight: ダッシュボード]

## 使用サービス

- Amazon S3
- AWS Lambda
- Amazon EventBridge
- Amazon Athena
- Amazon QuickSight
- Terraform

## データソース

- Open-Meteo API（大阪：緯度34.6937、経度135.5023）

## インフラ構築手順

### 1. Terraformで基盤構築

terraform init
terraform plan
terraform apply

### 2. LambdaコードをS3にアップロード

lambda_function.zip を S3://portfolio-01-osaka-weather-raw-2026-tetsu/lambda/ にアップロード

### 3. Athenaでテーブル作成

athena_setup.sql をAthenaクエリエディタで実行

### 4. QuickSightでダッシュボード作成

- データソース：Athena（osaka-weather-db.weather_data）
- グラフ：気温推移（折れ線）、降水量（棒グラフ）

## ファイル構成

portfolio-01-osaka-weather/
├── main.tf # Terraform設定
├── lambda_function.py # Lambda関数コード
├── lambda_function.zip # Lambdaデプロイパッケージ
├── athena_setup.sql # Athenaテーブル作成SQL
└── README.md # 本ファイル

## 学んだこと

- S3の日付パーティショニングによるデータ管理
- LambdaでのJSONフラット化（ネストJSON → JSON Lines）
- Athenaでのパーティション付きテーブル設計
- QuickSightでのダッシュボード作成
- TerraformによるIaC管理
