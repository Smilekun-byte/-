# CLAUDE.md — マイ課題 AI作業ガイド

## このプロジェクトとは
Moodle iCal → SwiftData → WidgetKit の iOS課題管理アプリ。
単なるTodoではなく「学生の時間的不安を観測可能な空間へ変換する」ための
Cognitive Visualization Toolである。

## 現在のフェーズ
Phase 1 完了（v1〜v5）。これから Phase 2 に入る。

## 今作業中のこと
← ここを毎回更新する。例：「v6: Course エンティティ追加中」

---

## 実装済み（Phase 1 / 変更禁止）
- v1: Moodle iCal同期 + SwiftData保存
- v2: カレンダー + Heatmap（☕🟡🟠🔥）
- v3: WidgetKit（Small / Medium）
- v4: 0:00締切トラップ検知・警告
- v5: OSS公開・README整備

---

## 絶対に触ってはいけないもの
- Assignment.swift の既存フィールド（変更・削除禁止。追加は計画的にOK）
- KeychainManager.swift（セキュリティ審査済み）
- UID マージロジック（AssignmentViewModel.sync()）
- 日付キーの正規化方式（"yyyy-MM-dd" 文字列 — タイムゾーンズレ対策済み）

---

## アーキテクチャ原則（変えないこと）
1. State-Driven UI — View はロジックを持たない
2. Single Source of Truth — Moodle取得タスクと手動タスクを分離しない
3. cleanTitle は計算プロパティ（DBを汚さない）
4. ウィジェット共有は App Groups + UserDefaults（SwiftDataは使わない）
5. Objective × Subjective Separation
   - 横軸 = deadline（客観・変更不可）
   - 縦軸 = userPriority（主観・ドラッグで調整可能）

---

## iOS 26 アーキテクチャ方針
- Xcode 26 SDK でビルド（Liquid Glass UI は自動適用、TabBar / NavigationStack は変更不要）
- minimum target は iOS 26（後方互換は維持しない）
- SwiftData は model inheritance を活用して Course エンティティを設計する
- Foundation Models（on-device AI）は Phase 3 で導入予定。今は実装しない。接続点のみ設計に残す
- CloudKit 同期は Phase 4 予定。今は SwiftData の local container のみ使用

---

## データモデル（現在の Assignment.swift フィールド）
uid           // Moodle同期時の衝突防止（主キー）
rawTitle      // Moodle生データ（cleanTitleで変換）
deadline      // Date型
isCompleted   // ローカル完了状態
isManualEntry // Moodle由来 or ユーザー追加の識別
userNotes     // ローカルメモ

---

## Phase 2 で追加するもの（次に実装する）

### v6: Course エンティティ + CATEGORIES 自動紐付け

**背景**
iCal の各イベントには CATEGORIES フィールドがある。
値は課程の一意IDになっている（例：2026_99FE210）。
課程名は iCal に含まれないが、この ID をキーにすれば
ユーザーが一度だけ名前を付ければ以降は自動紐付けできる。

**実装内容**
- Course を SwiftData の独立 @Model として新規追加
  - categoryID: String  // CATEGORIES の値（主キー）
  - name: String        // ユーザーが付けた課程名
  - colorHex: String    // カレンダー表示用のカラーラベル
- Assignment に以下を追加（マイグレーション必須）
  - categoryID: String? // CATEGORIES の値（既存データは nil）
  - course: Course?     // @Relationship で Course と紐付け
- 未命名の Course が検出されたとき、課程名入力シートを表示する
  （入力必須ではなく、スキップも可能にする。スキップ時は categoryID を仮名として表示）
- 以降は同じ categoryID のタスクを自動で同じ Course に紐付け

**マイグレーション注意**
Assignment.swift にフィールドを追加するため
VersionedSchema + SchemaMigrationPlan を必ず同時に実装すること。
追加フィールドはすべて Optional（String? / nil）にして既存データを保護する。

---

### v7: Matrix View

**App 内（新 Tab）**
- 横軸 = deadline までの距離（自動計算・変更不可）
- 縦軸 = userPriority（0.0〜1.0）
- ドラッグで userPriority を調整できる
- これが実際の操作画面

**主画面 Widget（WidgetKit）**
- Matrix の現在状態を読み取り専用で表示
- ドラッグ不可（WidgetKit の仕様上の制限）
- タップすると App 内の Matrix View に遷移

**データ追加（マイグレーション必須）**
- Assignment に userPriority: Double を追加（デフォルト 0.5）

---

## 長期ロードマップ

### Phase 2 — Context（今ここ）
目標：「タスクがある」から「タスクを理解する」へ
- [ ] v6: Course エンティティ + CATEGORIES 自動紐付け
- [ ] v7: Matrix View（横軸=deadline、縦軸=userPriority、ドラッグ調整）
- [ ] v8: 予想所要時間フィールド
- [ ] v9: 同一週内の deadline 衝突検出

### Phase 3 — Rhythm
目標：受動的リマインダー → 能動的提案
- [ ] Foundation Models（on-device AI）で Rhythm 分析
- [ ] AI は Silent Cognitive Assistant として動作
      ✅「今週は比較的余裕があります」
      ❌「今日やりましょう」（命令・説教・強制はしない）
- [ ] 負荷傾向分析・完了パターン観測

### Phase 4 — Shared Signals
目標：将来の拡張への扉を開ける
- [ ] CloudKit 同期（SwiftData shared container）
- [ ] 匿名集計・課程難易度シグナル
- [ ] ユーザーID体系・データのローカル非依存化

---

## 将来への拡張ポイント（今は実装しない）
今設計に含める理由は「将来壊さないため」であり「今実装するため」ではない。
- Course エンティティに将来の共有・統計用フィールドを追加できる余地を残す
- Assignment の completion history は Phase 3 の AI 分析のために記録を蓄積しておく
- userPriority の履歴変化は将来の Rhythm 分析に使える

---

## OSS戦略
- Lite（OSS）：Moodle Sync + Calendar + Heatmap + Basic Widget（無料・完全公開）
- Pro：Matrix View + Advanced Widgets + Stress Analytics + Rhythm Analysis
