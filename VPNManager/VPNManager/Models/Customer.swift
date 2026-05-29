import Foundation
import SwiftData

@Model
final class Customer {
    var id: UUID
    var name: String
    var paymentAmount: Double
    var currency: String
    var userCount: Int
    var username: String
    var notes: String
    var paymentDate: Date
    var isMonthlyBilling: Bool
    var status: CustomerStatus
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var paymentHistory: [PaymentHistory]

    init(
        id: UUID = UUID(),
        name: String,
        paymentAmount: Double,
        currency: String = "USDT",
        userCount: Int,
        username: String,
        notes: String = "",
        paymentDate: Date,
        isMonthlyBilling: Bool = true,
        status: CustomerStatus = .active
    ) {
        self.id = id
        self.name = name
        self.paymentAmount = paymentAmount
        self.currency = currency
        self.userCount = userCount
        self.username = username
        self.notes = notes
        self.paymentDate = paymentDate
        self.isMonthlyBilling = isMonthlyBilling
        self.status = status
        self.createdAt = Date()
        self.paymentHistory = []
    }

    var isOverdue: Bool {
        paymentDate < Calendar.current.startOfDay(for: Date())
    }

    var isDueToday: Bool {
        Calendar.current.isDateInToday(paymentDate)
    }

    var isDueTomorrow: Bool {
        Calendar.current.isDateInTomorrow(paymentDate)
    }

    var isDueSoon: Bool {
        let now = Date()
        let sevenDays = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        return paymentDate >= Calendar.current.startOfDay(for: now) && paymentDate <= sevenDays
    }

    var formattedAmount: String {
        let formatted = paymentAmount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(paymentAmount))
            : String(format: "%.2f", paymentAmount)
        return "\(formatted) \(currency)"
    }
}

enum CustomerStatus: String, Codable, CaseIterable {
    case active = "Active"
    case expired = "Expired"
    case notExtended = "Not Extended"
}

struct CustomerExport: Codable {
    var id: UUID
    var name: String
    var paymentAmount: Double
    var currency: String
    var userCount: Int
    var username: String
    var password: String
    var notes: String
    var paymentDate: Date
    var isMonthlyBilling: Bool
    var status: CustomerStatus
    var createdAt: Date
    var paymentHistory: [PaymentHistoryExport]
}

struct PaymentHistoryExport: Codable {
    var id: UUID
    var date: Date
    var amount: Double
    var currency: String
    var note: String
}
