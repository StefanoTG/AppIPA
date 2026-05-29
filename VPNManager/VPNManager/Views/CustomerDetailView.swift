import SwiftUI
import SwiftData

struct CustomerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var customer: Customer
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showCopied: String? = nil
    @State private var showingHistory = false

    private var password: String {
        KeychainManager.shared.getPassword(for: customer.id)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                actionButtons
                infoCard
                if !customer.notes.isEmpty { notesCard }
                if !customer.paymentHistory.isEmpty { historyCard }
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(customer.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accentIndigo)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddEditCustomerView(customer: customer)
        }
        .alert("Delete Customer", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) { deleteCustomer() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(customer.name)? This cannot be undone.")
        }
        .overlay(copiedToast)
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(customer.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(customer.userCount) users")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                StatusBadge(status: customer.status)
            }

            Divider().background(Color.cardBorder)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(customer.formattedAmount)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Next payment")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(customer.paymentDate.formattedShort)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(customer.isOverdue ? .statusExpired : customer.isDueSoon ? .dueSoon : .white)
                }
            }

            if customer.isOverdue {
                let days = abs(customer.paymentDate.daysUntil)
                Label("\(days) day(s) overdue", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.statusExpired)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .background(Color.statusExpired.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cardBorder, lineWidth: 1))
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ActionButton(title: "Extended", icon: "checkmark.circle.fill", color: .statusActive) {
                    extendPayment()
                }
                ActionButton(title: "Didn't Extend", icon: "xmark.circle.fill", color: .statusExpired) {
                    markNotExtended()
                }
            }
            HStack(spacing: 10) {
                ActionButton(title: "Copy Username", icon: "doc.on.doc.fill", color: .accentIndigo) {
                    UIPasteboard.general.string = customer.username
                    showCopied = "Username copied"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showCopied = nil }
                }
                ActionButton(title: "Copy Password", icon: "key.fill", color: .accentPurple) {
                    UIPasteboard.general.string = password
                    showCopied = "Password copied"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showCopied = nil }
                }
            }
            HStack(spacing: 10) {
                ActionButton(title: "Edit", icon: "pencil", color: .dueSoon) {
                    showingEditSheet = true
                }
                ActionButton(title: "Delete", icon: "trash.fill", color: .statusExpired) {
                    showingDeleteAlert = true
                }
            }
        }
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            InfoRow(label: "Username", value: customer.username, icon: "person.fill")
            Divider().background(Color.cardBorder).padding(.leading, 44)
            InfoRow(label: "Password", value: password.isEmpty ? "—" : String(repeating: "•", count: min(password.count, 12)), icon: "lock.fill", isPassword: true, actualValue: password)
            Divider().background(Color.cardBorder).padding(.leading, 44)
            InfoRow(label: "User count", value: "\(customer.userCount)", icon: "person.2.fill")
            Divider().background(Color.cardBorder).padding(.leading, 44)
            InfoRow(label: "Billing", value: customer.isMonthlyBilling ? "Monthly" : "One-time", icon: "calendar.badge.clock")
        }
        .padding(.vertical, 4)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cardBorder, lineWidth: 1))
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textSecondary)
            Text(customer.notes)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cardBorder, lineWidth: 1))
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Payment History", systemImage: "clock.arrow.circlepath")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textSecondary)

            ForEach(customer.paymentHistory.sorted { $0.date > $1.date }.prefix(5)) { record in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.date.formattedShort)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        if !record.note.isEmpty {
                            Text(record.note)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    Spacer()
                    Text("\(String(format: "%.0f", record.amount)) \(record.currency)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.statusActive)
                }
                .padding(.vertical, 4)
                if record.id != customer.paymentHistory.sorted { $0.date > $1.date }.prefix(5).last?.id {
                    Divider().background(Color.cardBorder)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cardBorder, lineWidth: 1))
    }

    @ViewBuilder
    private var copiedToast: some View {
        if let msg = showCopied {
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.statusActive)
                    Text(msg)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                .padding(.bottom, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.spring(response: 0.3), value: showCopied)
        }
    }

    private func extendPayment() {
        let history = PaymentHistory(amount: customer.paymentAmount, currency: customer.currency, note: "Extended")
        customer.paymentHistory.append(history)

        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: customer.paymentDate) {
            customer.paymentDate = newDate
        }
        customer.status = .active
        NotificationManager.shared.scheduleNotifications(for: customer)
        try? modelContext.save()
    }

    private func markNotExtended() {
        customer.status = .notExtended
        NotificationManager.shared.cancelNotifications(for: customer)
        try? modelContext.save()
    }

    private func deleteCustomer() {
        NotificationManager.shared.cancelNotifications(for: customer)
        KeychainManager.shared.deletePassword(for: customer.id)
        modelContext.delete(customer)
        try? modelContext.save()
        dismiss()
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    var isPassword: Bool = false
    var actualValue: String = ""

    @State private var showPassword = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentIndigo)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                Text(isPassword && !showPassword ? value : (isPassword ? actualValue : value))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }

            Spacer()

            if isPassword {
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
