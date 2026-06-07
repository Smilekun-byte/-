# マイ課題 — Moodleの「0:00締切トラップ」を救うiOSウィジェット

![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-blue?logo=apple)
![License](https://img.shields.io/badge/License-AGPL--3.0-blue)
![OSS](https://img.shields.io/badge/OSS-無料・完全公開-brightgreen)

> **大学のMoodleは、締め切りを「5月30日 0:00」と表示する。**  
> それは「30日の深夜」ではなく、「29日の深夜」を意味することが多い。  
> このアプリは、その罠を検知し、あなたの単位を守る。

---

## 📸 スクリーンショット

| 課題リスト | カレンダー熱量表示 | ホーム画面ウィジェット |
|:---:|:---:|:---:|
| *(準備中)* | *(準備中)* | *(準備中)* |

---

## 🎯 解決する問題

| Moodle側の課題 | マイ課題の解決策 |
|---|---|
| タイトルが不鮮明（例：`「提出:D07」の提出期限`） | 表示時に自動クレンジング（DBは汚さない） |
| **0:00締切の罠**（前日深夜と混同しやすい） | `isMidnightDeadline` フラグで橙色の警告バナーを表示 |
| 詳細情報が不足（提出形式の未記載など） | タスクごとにローカルメモ（`userNotes`）を追記可能 |
| 公式ウィジェットが存在しない | WidgetKit対応：ホーム画面で残り時間をリアルタイム表示 |
| 完了状態がMoodleと同期されない | スワイプで手動完了マーク（ローカル管理） |

---

## ✨ 主な機能

- **課題カウントダウンリスト** — 締め切り順にソートし、0:00締切を自動警告
- **自前実装カレンダー（月曜始まり）** — 課題密集度をヒートマップ（☕🟡🟠🔥）で可視化
- **ホーム画面ウィジェット** — Small / Medium サイズで次の締め切りを常時表示
- **Keychain 認証保護** — iCal URLに含まれる`authtoken`をiOS Keychainに暗号化保存
- **UID主キーマージ** — Moodle同期時にユーザーの完了状態・メモを絶対に上書きしない

---

## 🛠 必要環境

| 項目 | バージョン |
|---|---|
| iOS | 17.0 以上 |
| Xcode | 15.0 以上 |
| Swift | 5.9 以上 |
| 対応デバイス | iPhone / iPad |

---

## 🚀 セットアップ

### 1. リポジトリをクローン

```bash
git clone https://github.com/YOUR_USERNAME/maikadai.git
cd maikadai
```

### 2. iCalKit パッケージを追加

Xcodeで開き、`File → Add Package Dependencies` から以下を追加：

```
https://github.com/kiliankoe/iCalKit.git
```

### 3. App Groups を設定

両ターゲット（`マイ課題` と `MaiKadaiWidgetExtension`）の  
`Signing & Capabilities → App Groups` に以下を追加：

```
group.com.YOUR_BUNDLE_ID.maikadai
```

`Services/AssignmentSnapshot.swift` 内の `appGroupID` も合わせて変更してください。

### 4. Moodle iCal URL を取得・登録

1. Moodleにログイン
2. **ダッシュボード → カレンダー → カレンダーをエクスポート** を開く
3. 「すべてのイベント」を選択してURLをコピー
4. アプリの **設定タブ** にURLを貼り付けて保存
5. 課題タブの 🔄 ボタンで同期

> ⚠️ このURLには個人認証トークン（`authtoken`）が含まれます。  
> 他者には絶対に共有しないでください。アプリはiOS Keychainに暗号化して保存します。

---

## 🏗 アーキテクチャ

```
マイ課題/
├── App/                    # エントリポイント・SwiftDataコンテナ
├── Models/
│   └── Assignment.swift    # SwiftDataモデル（UID主キー・計算プロパティ）
├── ViewModels/
│   ├── AssignmentViewModel.swift  # 同期・UIDマージロジック
│   └── CalendarViewModel.swift    # ヒートマップ事前計算（O(1)アクセス）
├── Views/
│   ├── Calendar/           # 自前実装月間カレンダー（月曜始まり）
│   ├── AssignmentListView  # メインリスト（スワイプ完了）
│   ├── AssignmentDetailView # 詳細・メモ編集
│   └── SettingsView        # iCal URL登録・Keychain管理
└── Services/
    ├── ICalParser.swift     # iCalKit アダプター（RFC5545準拠）
    ├── KeychainManager.swift # authtoken 安全保存
    ├── CalendarProvider.swift # 月曜JST固定・文字列キー正規化
    └── AssignmentSnapshot.swift # ウィジェット共有データ（App Groups）

MaiKadaiWidget/             # WidgetKit Extension
├── MaiKadaiWidget.swift    # TimelineProvider
├── MaiKadaiWidgetView.swift # Small / Medium UI
└── SharedData.swift        # App Groups 読み取り
```

### 設計上の重要な決定

| 決定 | 理由 |
|---|---|
| `cleanTitle` を計算プロパティに | DBを汚さず、パーサー変更時にマイグレーション不要 |
| 日付キーを `"yyyy-MM-dd"` 文字列に正規化 | タイムゾーンズレによるカレンダードットの消失バグを根絶 |
| iCalKit を最初から採用 | 自前Regexの後でライブラリ移行すると二重実装になるため |
| App Groups + UserDefaults でウィジェット共有 | SwiftDataをWidgetに渡す複雑さを避け、シリアライズで解決 |

---

## 🗺 ロードマップ

- [x] Phase 1 — SwiftData モデル・Keychain セキュリティ基盤
- [x] Phase 2 — UI実装（0:00警告・スワイプ完了・空状態）
- [x] Phase 3 — iCal パース・UID マージ同期ロジック
- [x] Phase 4 — WidgetKit（Small / Medium）
- [ ] Phase 5 — OSS公開・README整備 ← **今ここ**
- [ ] セカンダリマッチング（`SHA256(Title+Deadline)` によるUID変更耐性）
- [ ] Push通知（締め切り前日アラート）
- [ ] iPad 最適化・マルチカラム対応

---

## 🤝 コントリビューション

IssueやPRを歓迎します。

- **バグ報告**: Issueにて `bug` ラベルを付けて報告してください
- **機能提案**: Issueにて `enhancement` ラベルで提案してください
- **対応Moodleバージョン**: 動作確認できた大学・Moodleバージョンを教えていただけると助かります

コードは英語、コメントは日本語で記述しています（審査員・国内コントリビューター向け）。

---

## ⚠️ 免責事項

- 本アプリはMoodle公式とは無関係の非公式ツールです
- iCal URLの取得・利用は各大学の利用規約に従ってください
- 締め切りの見落としによる学業上の損失について、開発者は一切の責任を負いません
- 本アプリで表示される締め切り情報は必ずMoodle公式で最終確認してください

---

## 📄 ライセンス

[AGPL-3.0](LICENSE) © 2026

プロプライエタリ製品での利用には商用ライセンスが必要です。

📩 Instagram DM: [@maikadai](https://www.instagram.com/maikadai)

---

<details>
<summary>English Summary</summary>

## マイ課題 (My Assignments)

An open-source iOS app that parses Moodle iCal feeds and provides:
- Assignment countdown list with midnight-deadline trap detection
- Custom calendar with deadline density heatmap
- Home screen widget (WidgetKit)
- Secure iCal URL storage via iOS Keychain

Built with SwiftUI, SwiftData, WidgetKit, and iCalKit.  
Designed for Japanese university students. UI is in Japanese.

**Tech Stack**: Swift 5.9 · SwiftUI · SwiftData · WidgetKit · iCalKit · Keychain

</details>
