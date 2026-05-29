import Foundation
import SwiftUI

extension Date {
    var formattedShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: self)
    }

    var daysUntil: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: self)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
}

extension Color {
    static let appBackground = Color(red: 0.07, green: 0.07, blue: 0.10)
    static let cardBackground = Color(red: 0.13, green: 0.13, blue: 0.18)
    static let cardBorder = Color(red: 0.22, green: 0.22, blue: 0.30)
    static let accentIndigo = Color(red: 0.38, green: 0.32, blue: 0.90)
    static let accentPurple = Color(red: 0.60, green: 0.30, blue: 0.90)
    static let statusActive = Color(red: 0.25, green: 0.78, blue: 0.52)
    static let statusExpired = Color(red: 0.93, green: 0.27, blue: 0.27)
    static let statusNotExtended = Color(red: 0.93, green: 0.55, blue: 0.10)
    static let dueSoon = Color(red: 0.93, green: 0.65, blue: 0.10)
    static let textSecondary = Color(red: 0.60, green: 0.60, blue: 0.70)
}

extension CustomerStatus {
    var color: Color {
        switch self {
        case .active: return .statusActive
        case .expired: return .statusExpired
        case .notExtended: return .statusNotExtended
        }
    }

    var icon: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .expired: return "xmark.circle.fill"
        case .notExtended: return "clock.fill"
        }
    }
}
