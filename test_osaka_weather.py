import urllib.request
import json
from datetime import datetime

# 大阪（梅田/難波あたり）の緯度経度
LATITUDE = 34.6937
LONGITUDE = 135.5023

url = (
    f"https://api.open-meteo.com/v1/forecast?"
    f"latitude={LATITUDE}&longitude={LONGITUDE}"
    f"&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode"
    f"&timezone=Asia%2FTokyo"
    f"&forecast_days=7"
)

print(f"URL: {url}")
print("---")

request = urllib.request.Request(url)
with urllib.request.urlopen(request) as response:
    data = json.loads(response.read().decode())

print(f"取得時刻: {datetime.now()}")
print(f"緯度: {data['latitude']}, 経度: {data['longitude']}")

daily = data["daily"]
for i in range(len(daily["time"])):
    date = daily["time"][i]
    max_temp = daily["temperature_2m_max"][i]
    min_temp = daily["temperature_2m_min"][i]
    rain = daily["precipitation_sum"][i]
    print(f"{date}: 最高{max_temp}°C / 最低{min_temp}°C / 降水{rain}mm")

# 保存
with open("osaka_weather_sample.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("\n---")
print("osaka_weather_sample.json に保存しました")