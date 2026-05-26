import Foundation

/// iCal パース後の中間データ構造。SwiftData には保存せず、マージ処理の入力として使う。
struct NetworkAssignmentItem {
    let uid: String
    let rawTitle: String
    let deadline: Date
    let rawDescription: String
    let categoryID: String?
}
