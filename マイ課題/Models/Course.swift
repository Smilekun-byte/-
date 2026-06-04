import Foundation
import SwiftData

@Model
final class Course {
    @Attribute(.unique) var categoryID: String
    var name: String
    var colorHex: String

    @Relationship(deleteRule: .nullify, inverse: \Assignment.course)
    var assignments: [Assignment] = []

    init(categoryID: String, name: String, colorHex: String = "#4A90D9") {
        self.categoryID = categoryID
        self.name = name
        self.colorHex = colorHex
    }
}
