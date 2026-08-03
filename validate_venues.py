#!/usr/bin/env python3
"""venues.geocoded.json の最低限の整合性チェック(フェーズiOS-4o)。

週次自動更新(weekly_update.sh)がClaudeにJSONを書き換えさせた直後、
GitHubへpushする前にこのスクリプトを通す。アプリ側(LossyArrayDecoding)は
「壊れた要素をスキップして残りを表示する」形で耐性を持たせているが、
そもそも壊れたデータをpushしないに越したことはないため、データ生成元側の
予防策として置いている。

exit code 0 = 問題なし、1 = 問題あり(標準エラーに詳細を出力)。
"""
import json
import sys

TOKYO_BOUNDS = (35.5, 35.95, 139.3, 139.95)
REQUIRED_VENUE_FIELDS = ["name", "events"]
REQUIRED_EVENT_FIELDS = ["title", "date", "is_real"]


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "venues.geocoded.json"
    errors = []

    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"[FATAL] JSONとして読み込めません: {e}", file=sys.stderr)
        return 1

    venues = data.get("venues")
    if not isinstance(venues, list) or not venues:
        print("[FATAL] venues配列が存在しないか空です", file=sys.stderr)
        return 1

    for i, v in enumerate(venues):
        name = v.get("name", f"(index {i}, name不明)")
        for field in REQUIRED_VENUE_FIELDS:
            if field not in v:
                errors.append(f"会場「{name}」: 必須フィールド '{field}' が欠落")

        lat, lng = v.get("lat"), v.get("lng")
        if lat is not None and lng is not None:
            if not (TOKYO_BOUNDS[0] <= lat <= TOKYO_BOUNDS[1] and TOKYO_BOUNDS[2] <= lng <= TOKYO_BOUNDS[3]):
                errors.append(f"会場「{name}」: 座標が東京都心の範囲外 (lat={lat}, lng={lng})")

        for j, e in enumerate(v.get("events", [])):
            title = e.get("title", f"(event index {j})")
            for field in REQUIRED_EVENT_FIELDS:
                if field not in e:
                    errors.append(f"会場「{name}」イベント「{title}」: 必須フィールド '{field}' が欠落")
            if "performers" not in e:
                errors.append(f"会場「{name}」イベント「{title}」: performers が欠落(空配列[]にすべき)")

    if errors:
        print(f"[NG] {len(errors)}件の問題:", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    print(f"[OK] {len(venues)}会場、問題なし")
    return 0


if __name__ == "__main__":
    sys.exit(main())
