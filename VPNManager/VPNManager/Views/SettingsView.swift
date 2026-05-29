import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var customers: [Customer]
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var exportData: Data?
    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var showingClearAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    dataSection
                    securitySection
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ShareSheet(data: data, filename: "vpn_customers_backup.json")
                }
            }
            .fileImporter(isPresented: $showingImportPicker, allowedContentTypes: [.json]) { result in
                handleImport(result: result)
            }
            .alert("Settings", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
            .alert("Clear All Data", isPresented: $showingClearAlert) {
                Button("Delete All", role: .destructive) { clearAllData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all \(customers.count) customers. This cannot be undone.")
            }
        }
    }

    private var dataSection: some View {
        settingsSection(title: "Data & Backup") {
            SettingsRow(icon: "square.and.arrow.up.fill", title: "Export to JSON", subtitle: "Backup all customers", color: .accentIndigo) {
                exportCustomers()
            }
            Divider().background(Color.cardBorder).padding(.leading, 52)
            SettingsRow(icon: "square.and.arrow.down.fill", title: "Import from JSON", subtitle: "Restore from backup", color: .accentPurple) {
                showingImportPicker = true
            }
            Divider().background(Color.cardBorder).padding(.leading, 52)
            SettingsRow(icon: "trash.fill", title: "Clear All Data", subtitle: "\(customers.count) customers", color: .statusExpired) {
                showingClearAlert = true
            }
        }
    }

    private var securitySection: some View {
        settingsSection(title: "Security") {
            SettingsRow(icon: "faceid", title: "Biometric Lock", subtitle: "Face ID / Touch ID enabled", color: .statusActive, action: nil)
            Divider().background(Color.cardBorder).padding(.leading, 52)
            SettingsRow(icon: "lock.shield.fill", title: "Keychain Storage", subtitle: "Passwords stored securely", color: .accentIndigo, action: nil)
        }
    }

    private var aboutSection: some View {
        settingsSection(title: "About") {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [.accentIndigo, .accentPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("VPN Manager")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Version 1.0 · Private Use")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textSecondary)
                .padding(.leading, 16)
                .padding(.bottom, 6)
            VStack(spacing: 0) { content() }
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cardBorder, lineWidth: 1))
        }
    }

    private func exportCustomers() {
        let passwords = KeychainManager.shared.getAllPasswords()
        let exports: [CustomerExport] = customers.map { c in
            CustomerExport(
                id: c.id, name: c.name, paymentAmount: c.paymentAmount,
                currency: c.currency, userCount: c.userCount, username: c.username,
                password: passwords[c.id.uuidString] ?? "",
                notes: c.notes, paymentDate: c.paymentDate,
                isMonthlyBilling: c.isMonthlyBilling, status: c.status,
                createdAt: c.createdAt,
                paymentHistory: c.paymentHistory.map {
                    PaymentHistoryExport(id: $0.id, date: $0.date, amount: $0.amount, currency: $0.currency, note: $0.note)
                }
            )
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(exports) {
            exportData = data
            showingExportSheet = true
        }
    }

    private func handleImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            guard let data = try? Data(contentsOf: url) else {
                alertMessage = "Could not read the file."
                showAlert = true
                return
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            guard let imports = try? decoder.decode([CustomerExport].self, from: data) else {
                alertMessage = "Invalid backup file format."
                showAlert = true
                return
            }
            var imported = 0
            for exp in imports {
                let c = Customer(
                    id: exp.id, name: exp.name, paymentAmount: exp.paymentAmount,
                    currency: exp.currency, userCount: exp.userCount, username: exp.username,
                    notes: exp.notes, paymentDate: exp.paymentDate,
                    isMonthlyBilling: exp.isMonthlyBilling, status: exp.status
                )
                for h in exp.paymentHistory {
                    c.paymentHistory.append(PaymentHistory(id: h.id, date: h.date, amount: h.amount, currency: h.currency, note: h.note))
                }
                modelContext.insert(c)
                KeychainManager.shared.savePassword(exp.password, for: exp.id)
                NotificationManager.shared.scheduleNotifications(for: c)
                imported += 1
            }
            try? modelContext.save()
            alertMessage = "Successfully imported \(imported) customers."
            showAlert = true
        case .failure(let error):
            alertMessage = "Import failed: \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func clearAllData() {
        for customer in customers {
            NotificationManager.shared.cancelNotifications(for: customer)
            KeychainManager.shared.deletePassword(for: customer.id)
            modelContext.delete(customer)
        }
        try? modelContext.save()
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: (() -> Void)?

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .disabled(action == nil)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let data: Data
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: tempURL)
        return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
