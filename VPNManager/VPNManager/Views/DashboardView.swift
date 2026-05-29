import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var customers: [Customer]

    private var totalCustomers: Int { customers.count }
    private var activeCount: Int { customers.filter { $0.status == .active }.count }
    private var expiredCount: Int { customers.filter { $0.status == .expired || $0.status == .notExtended }.count }
    private var dueSoonCount: Int { customers.filter { $0.isDueSoon && $0.status == .active }.count }

    private var monthlyIncome: Double {
        customers.filter { $0.status == .active && $0.isMonthlyBilling }.reduce(0) { sum, c in
            if c.currency == "USDT" || c.currency == "USD" { return sum + c.paymentAmount }
            return sum
        }
    }

    private var monthlyIncomeManat: Double {
        customers.filter { $0.status == .active && $0.isMonthlyBilling }.reduce(0) { sum, c in
            if c.currency == "Manat" { return sum + c.paymentAmount }
            return sum
        }
    }

    private var overdueCustomers: [Customer] {
        customers.filter { $0.isOverdue && $0.status == .active }
            .sorted { $0.paymentDate < $1.paymentDate }
    }

    private var upcomingCustomers: [Customer] {
        customers.filter { $0.isDueSoon && !$0.isOverdue }
            .sorted { $0.paymentDate < $1.paymentDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statsGridView
                    if !overdueCustomers.isEmpty { overdueSection }
                    if !upcomingCustomers.isEmpty { upcomingSection }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var statsGridView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(title: "Total", value: "\(totalCustomers)", subtitle: "customers", icon: "person.2.fill", gradient: [.accentIndigo, .accentPurple])
                StatCard(title: "Active", value: "\(activeCount)", subtitle: "customers", icon: "checkmark.circle.fill", gradient: [.statusActive, Color(red: 0.15, green: 0.65, blue: 0.42)])
            }
            HStack(spacing: 12) {
                StatCard(title: "Expired", value: "\(expiredCount)", subtitle: "customers", icon: "xmark.circle.fill", gradient: [.statusExpired, Color(red: 0.75, green: 0.15, blue: 0.15)])
                StatCard(title: "Due Soon", value: "\(dueSoonCount)", subtitle: "this week", icon: "clock.fill", gradient: [.dueSoon, Color(red: 0.80, green: 0.45, blue: 0.05)])
            }
            if monthlyIncome > 0 || monthlyIncomeManat > 0 {
                incomeCard
            }
        }
    }

    private var incomeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "banknote.fill")
                    .foregroundColor(.accentIndigo)
                Text("Monthly Income")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }
            HStack(spacing: 20) {
                if monthlyIncome > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.0f USDT", monthlyIncome))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("USD / USDT")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                if monthlyIncome > 0 && monthlyIncomeManat > 0 {
                    Divider().frame(height: 36).background(Color.cardBorder)
                }
                if monthlyIncomeManat > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.0f ₼", monthlyIncomeManat))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Manat")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cardBorder, lineWidth: 1))
    }

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.statusExpired)
            ForEach(overdueCustomers) { customer in
                NavigationLink(destination: CustomerDetailView(customer: customer)) {
                    MiniCustomerRow(customer: customer)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Due Soon", systemImage: "clock.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.dueSoon)
            ForEach(upcomingCustomers) { customer in
                NavigationLink(destination: CustomerDetailView(customer: customer)) {
                    MiniCustomerRow(customer: customer)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                Spacer()
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cardBorder, lineWidth: 1))
    }
}

struct MiniCustomerRow: View {
    let customer: Customer

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(customer.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("\(customer.formattedAmount) · \(customer.userCount) users")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(customer.paymentDate.formattedShort)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(customer.isOverdue ? .statusExpired : .dueSoon)
                let days = customer.paymentDate.daysUntil
                Text(days < 0 ? "\(abs(days))d overdue" : days == 0 ? "Today" : "\(days)d left")
                    .font(.system(size: 11))
                    .foregroundColor(customer.isOverdue ? .statusExpired : .dueSoon)
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(customer.isOverdue ? Color.statusExpired.opacity(0.4) : Color.dueSoon.opacity(0.3), lineWidth: 1))
    }
}
