# venue-data

Venue アプリ(iOS)が起動時にリモート取得するデータファイル置き場。

- `venues.geocoded.json` — 会場・イベント情報
- `nearby_food.json` — 一軒目(近くの飲食店)情報

アプリ側は `raw.githubusercontent.com` 経由でこれらのファイルを取得し、
取得に失敗した場合はアプリ同梱の古いコピーにフォールバックする。
