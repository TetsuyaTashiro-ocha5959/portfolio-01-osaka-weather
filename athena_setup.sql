-- Athenaデータベース作成
CREATE DATABASE IF NOT EXISTS osaka_weather_db;

-- テーブル作成
CREATE EXTERNAL TABLE weather_data (
    date string,
    temperature_2m_max double,
    temperature_2m_min double,
    precipitation_sum double,
    weathercode int,
    latitude double,
    longitude double,
    timezone string,
    elevation double,
    fetch_date string
)
PARTITIONED BY (year string, month string, day string)
ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
LOCATION 's3://portfolio-01-osaka-weather-raw-2026-tetsu/';

-- パーティション追加
ALTER TABLE weather_data ADD PARTITION (year='2026', month='06', day='25')
LOCATION 's3://portfolio-01-osaka-weather-raw-2026-tetsu/2026/06/25/';

ALTER TABLE weather_data ADD PARTITION (year='2026', month='06', day='26')
LOCATION 's3://portfolio-01-osaka-weather-raw-2026-tetsu/2026/06/26/';