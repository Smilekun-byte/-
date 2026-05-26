import Foundation
import SwiftData

// V1→V2（categoryID / course 追加）は Optional フィールドのみの追加のため
// SwiftData の自動ライトウェイトマイグレーションで対応。
// 今後の破壊的マイグレーション（型変更・削除）が発生した場合はここに
// VersionedSchema + SchemaMigrationPlan を定義する。
