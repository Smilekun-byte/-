# CLAUDE.md — マイ課題 AI作業ガイド

## このプロジェクトとは
Moodle iCal → SwiftData → WidgetKit の iOS課題管理アプリ。
単なるTodoではなく「学生の時間的不安を観測可能な空間へ変換する」ための
Cognitive Visualization Toolである。

## 現在のフェーズ
Phase 5（OSS公開準備）。コア機能は完成済み。
次の開発フェーズ：課程名の手動タグ付け機能（Phase 2への準備）

## 今作業中のこと
← ここを毎回更新する。例：「courseName フィールドを Assignment に追加中」

---

## 絶対に触ってはいけないもの
- Assignment.swift のモデル定義（SwiftDataマイグレーションが走る）
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

## データモデル（Assignment.swift の主要フィールド）
uid           // Moodle同期時の衝突防止（主キー）
rawTitle      // Moodle生データ（cleanTitleで変換）
deadline      // Date型
courseName    // 手動タグ（iCalには課程名が含まれないため）
taskType      // TaskType enum
isCompleted   // ローカル完了状態
isManualEntry // Moodle由来 or ユーザー追加の識別
userPriority  // 0.0〜1.0（主観的重要度）
userNotes     // ローカルメモ

---

## 長期ロードマップ

### Phase 1 — Aggregation（完了 + 仕上げ中）
目標：情報の断片化をなくす
- [x] Moodle iCal同期 + SwiftData保存
- [x] カレンダーヒートマップ（☕🟡🟠🔥）
- [x] WidgetKit（Small / Medium）
- [x] 0:00締切トラップ検知・警告
- [ ] courseName 手動タグ付け（iCalに課程名がないため）

### Phase 2 — Context（次フェーズ）
目標：「タスクがある」から「タスクを理解する」へ
- [ ] userPriority + Matrix View（横軸=deadline、縦軸=重要度）
- [ ] 予想所要時間フィールド
- [ ] 同一週内のdeadline衝突検出
- [ ] タスク状態：未着手 / 進行中 / 完了 / 期限切れ

### Phase 3 — Rhythm
目標：受動的リマインダー → 能動的提案
- [ ] AI Assistance（Silent Cognitive Assistant）
      ✅「今週は比較的余裕があります」
      ❌「今日やりましょう」（命令・説教・強制はしない）
- [ ] 負荷傾向分析・完了パターン観測

### Phase 4 — Shared Signals
目標：将来の拡張への扉を開ける
- [ ] 匿名集計・課程難易度シグナル
- [ ] アーキテクチャ準備：ユーザーID体系、データのローカル非依存化

---

## AI拡張性への準備
今すぐAIを実装するためではなく、将来の接続点を壊さないため。
Assignment に残すべき情報：
taskType / courseName / userPriority / completion history / stress density

---

## OSS戦略
- Lite（OSS）：Moodle Sync + Calendar + Heatmap + Basic Widget（無料・完全公開）
- Pro：Matrix View + Advanced Widgets + Stress Analytics + Rhythm Analysis
