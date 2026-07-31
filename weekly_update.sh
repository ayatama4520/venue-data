#!/bin/bash
# Venue会場データの週次自動更新スクリプト(フェーズiOS-4m)。
#
# クラウドのスケジュール実行(claude.ai routines)はサンドボックス環境の
# ネットワークegressが全面的にブロックされており、会場公式サイトへの
# アクセスができなかった。このMac上のlaunchdから直接Claude Code CLIを
# 非対話モード(-p)で呼び出す方式に切り替えている。
#
# 実行結果はログファイルに保存し、macOS通知でCEOに知らせる
# (「更新内容をチャット上で確認したい」という要望への対応。ヘッドレス実行
# のため厳密には「チャット」ではないが、通知+ログで同等の可視性を確保する)。

set -euo pipefail

REPO_DIR="/Users/ayatatamaoka/tama-company/apps/venue-data"
LOG_DIR="/Users/ayatatamaoka/tama-company/outputs/venue"
LOG_FILE="$LOG_DIR/weekly_update_log.md"
DATE_STR=$(date "+%Y-%m-%d %H:%M")

mkdir -p "$LOG_DIR"
cd "$REPO_DIR"
git pull --quiet origin main

PROMPT="あなたはVenue(東京の音楽イベント地図アプリ)の会場データを最新化するタスクを行います。カレントディレクトリに venues.geocoded.json (会場・イベント情報) があります。

## やること
venues.geocoded.json 内の各会場について、source_url(公式サイト)のイベントスケジュールページを確認し、以下を行ってください:
1. 新しく確認できた今後のイベントを events 配列に追加する(既存データのスキーマ: title, date, performers, is_real, source_url, open_time, start_time, price_advance, price_door, price_note, detail_page_url に従うこと)
2. 日付が7日以上前になった過去のイベントは events 配列から削除する
3. 既存イベントの日程・料金等に公式サイト側で変更があれば更新する

## 絶対に守ること(データ品質方針)
- 各会場の公式サイト・公式SNS以外を情報源にしないこと(まとめサイト・非公式情報は使わない)
- 確認できない情報は追加しない。推測でイベントを作らない
- 新しい会場を追加しない(会場追加はCEOの承認が必要な別プロセスのため、このタスクの対象外)
- 各会場の name/address/lat/lng/genre/geocode_precision フィールドは変更しない(events配列のみ更新対象)
- JSON全体の構造・キー順序・フォーマット(インデント等)はできるだけ壊さないこと
- performers は出演者が確認できない場合も必ず空配列 [] として記載すること(キー自体を省略しない)。アプリ側のデコード必須項目のため、キー欠落があるとアプリのデータ読み込みが全会場分エラーになる

## 完了後
変更した内容を venues.geocoded.json に反映し、git でコミット・push してください(コミットメッセージには変更概要を含めること。main ブランチに直接pushでよい)。

最後に、必ず以下を含む報告を出力してください(CEOが人力で確認するため、この報告が最も重要です):
- 確認した会場数、実際に変更があった会場数
- 変更があった会場ごとに: 会場名、追加したイベント数(タイトルと日付も列挙)、削除したイベント数、変更した項目
- 確認できたが情報源が不十分で更新を見送った会場があれば、その会場名と理由

変更が1件もなかった場合も、その旨を明記してください。"

OUTPUT=$(claude -p "$PROMPT" \
  --permission-mode acceptEdits \
  --allowedTools "Bash,Read,Write,Edit,Glob,Grep,WebFetch,WebSearch" \
  --output-format text 2>&1) || OUTPUT="[エラー] スクリプトが異常終了しました。$OUTPUT"

{
  echo ""
  echo "---"
  echo ""
  echo "## $DATE_STR"
  echo ""
  echo "$OUTPUT"
} >> "$LOG_FILE"

SUMMARY_LINE=$(echo "$OUTPUT" | grep -m1 -E "確認した会場数|変更が1件もなかった|エラー" || echo "詳細はログを確認してください")
osascript -e "display notification \"$SUMMARY_LINE\" with title \"Venue 週次データ更新\" subtitle \"$DATE_STR\""
