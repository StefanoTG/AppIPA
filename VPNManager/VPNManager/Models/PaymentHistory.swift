import Foundation
import SwiftData

@Model
final class PaymentHistory {
    var id: UUID
    var date: Date
    var amount: Double
    var currency: String
    var note: String

    init(id: UUID = UUID(), date: Date = Date(), amount: Double, currency: String, note: String = "") {
        self.id = id
        self.date = date
        self.amount = amount
        self.currency = currency
        self.note = note
    }
}
