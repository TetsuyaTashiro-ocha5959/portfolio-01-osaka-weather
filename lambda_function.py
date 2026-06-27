import json
import urllib.request
import os
from datetime import datetime, timezone, timedelta
import boto3

# 大阪（梅田/難波あたり）の緯度経度を定数として定義
LATITUDE = 34.6937
LONGITUDE = 135.5023

def lambda_handler(event, context):
    # 環境変数からバケット名を取得
    bucket_name = os.environ['BUCKET_NAME']
    
    # JSTで日付を取得
    jst = timezone(timedelta(hours=+9))
    now = datetime.now(jst)

    # 日付を取得
    today = now.strftime('%Y-%m-%d')
    year = now.strftime('%Y')
    month = now.strftime('%m')
    day = now.strftime('%d')
    
    # Open Meteo APIからデータを取得
    url = (
        f"https://api.open-meteo.com/v1/forecast?"
        f"latitude={LATITUDE}&longitude={LONGITUDE}"
        f"&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode"
        f"&timezone=Asia%2FTokyo"
        f"&forecast_days=7"
    )
    
    # APIからデータを取得
    request = urllib.request.Request(url)
    with urllib.request.urlopen(request) as response:
        api_data = json.loads(response.read().decode())
    
    # 1行に1日分のデータを入れるJSONLに変換
    daily = api_data.get("daily", {})
    time_list = daily.get("time", [])
    temp_max_list = daily.get("temperature_2m_max", [])
    temp_min_list = daily.get("temperature_2m_min", [])
    rain_list = daily.get("precipitation_sum", [])
    weather_list = daily.get("weathercode", [])
    
    # 共通情報としてデータを追加
    common = {
        "latitude": api_data.get("latitude"),
        "longitude": api_data.get("longitude"),
        "timezone": api_data.get("timezone"),
        "elevation": api_data.get("elevation"),
        "fetch_date": today
    }
    
    # 各行をJSON Lines形式で書き出す
    lines = []
    for i in range(len(time_list)):
        # 変数recordに日付、最高気温、最低気温、降水量、天気コードを追加
        record = {
            "date": time_list[i],
            "temperature_2m_max": temp_max_list[i] if i < len(temp_max_list) else None,
            "temperature_2m_min": temp_min_list[i] if i < len(temp_min_list) else None,
            "precipitation_sum": rain_list[i] if i < len(rain_list) else None,
            "weathercode": weather_list[i] if i < len(weather_list) else None,
        }
        # 変数recordに共通情報を追加
        record.update(common)
        # 変数recordのデータをjson.dumpsでJSONに変換し、linesに追加
        lines.append(json.dumps(record, ensure_ascii=False))
    
    # 変数linesに入っているデータを改行で結合して、変数bodyに代入
    body = "\n".join(lines)
    
    # S3クライアントを作成
    s3 = boto3.client('s3')
    # バケット名とキーを作成
    key = f"{year}/{month}/{day}/osaka_weather.jsonl"  # 拡張子を .jsonl に変更
    
    # S3にデータを保存
    s3.put_object(
        Bucket=bucket_name,
        Key=key,
        Body=body.encode('utf-8'),
        ContentType='application/json'
    )
    
    # 保存したデータの件数を表示
    print(f"Saved {len(lines)} records to s3://{bucket_name}/{key}")
    
    # 成功したことを返す
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Weather data flattened and saved',
            'records': len(lines),
            'bucket': bucket_name,
            'key': key
        })
    }