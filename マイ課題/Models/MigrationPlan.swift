import Foundation
import SwiftData

// V1 スキーマのスナップショット — 編集禁止
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [SchemaV1.Assignment.self] }

    @Model final class Assignment {
        @Attribute(.unique) var uid: String
        var rawTitle: String
        var deadline: Date
        var rawDescription: String
        var isCompleted: Bool = false
        var userNotes: String = ""
        var lastUpdatedByUser: Date?
        var isManualEntry: Bool = false

        init(uid: String, rawTitle: String, deadline: Date, rawDescription: String) {
            self.uid = uid
            self.rawTitle = rawTitle
            self.deadline = deadline
            self.rawDescription = rawDescription
        }
    }
}

// V2 スキーマ — Course エンティティ追加・Assignment に categoryID/course を追加
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Assignment.self, Course.self] }
}

// V1 → V2 はオプショナルフィールドの追加のみなのでライトウェイトマイグレーションで対応
enum MaiKadaiMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }
    static var stages: [MigrationStage] {
        [MigrationStage.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)]
    }
}
