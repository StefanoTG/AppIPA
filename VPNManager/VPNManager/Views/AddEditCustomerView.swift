import SwiftUI
import SwiftData

struct AddEditCustomerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var customer: Customer?

    @State private var name = ""
    @State private var paymentAmount = ""
    @State private var currency = "USDT"
    @State private var userCount = ""
    @State private var username = ""
    @State private var password = ""
    @State private var notes = ""
    @State private var paymentDate = Date()
    @State private var isMonthlyBilling = true
    @State private var showPassword = false
    @State private var formError: String? = nil

    private let currencies = ["USDT", "USD", "Manat", "Other"]
    private let isEditing: Bool

    init(customer: Customer? = nil) {
        self.customer = customer
        self.isEditing = customer != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    formSection(title: "Customer Info") {
                        FormField(label: "Name", placeholder: "e.g. Merdan", text: $name)
                        Divider().background(Color.cardBorder)
                        HStack(spacing: 0) {
                            FormField(label: "Amount", placeholder: "e.g. 400", text: $paymentAmount)
                                .keyboardType(.decimalPad)
                            Picker("", selection: $currency) {
                                ForEach(currencies, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                            .tint(.accentIndigo)
                        }
                        Divider().background(Color.cardBorder)
                        FormField(label: "User count", placeholder: "e.g. 20", text: $userCount)
                            .keyboardType(.numberPad)
                    }

                    formSection(title: "Credentials") {
                        FormField(label: "Username", placeholder: "VPN panel username", text: $username)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Divider().background(Color.cardBorder)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Password")
                                    .font(.system(size: 11))
                                    .foregroundColor(.textSecondary)
                                Group {
                                    if showPassword {
                                        TextField("VPN panel password", text: $password)
                                    } else {
                                        SecureField("VPN panel password", text: $password)
                                    }
                                }
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            }
                            Spacer()
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    formSection(title: "Billing") {
                        DatePicker("Payment date", selection: $paymentDate, displayedComponents: .date)
                            .foregroundColor(.white)
                            .tint(.accentIndigo)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        Divider().background(Color.cardBorder)
                        Toggle(isOn: $isMonthlyBilling) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Monthly billing")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Auto-extend by 1 month")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .tint(.accentIndigo)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    formSection(title: "Notes") {
                        TextField("Optional notes...", text: $notes, axis: .vertical)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .lineLimit(3...6)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }

                    if let error = formError {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.statusExpired)
                            .padding(.horizontal, 16)
                    }

                    Button(action: saveCustomer) {
                        Text(isEditing ? "Save Changes" : "Add Customer")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient(colors: [.accentIndigo, .accentPurple], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .accentIndigo.opacity(0.4), radius: 10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .padding(.top, 12)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Customer" : "Add Customer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.accentIndigo)
                }
            }
            .onAppear { loadExistingData() }
        }
        .preferredColorScheme(.dark)
    }

    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
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
        .padding(.horizontal, 16)
    }

    private func loadExistingData() {
        guard let c = customer else { return }
        name = c.name
        paymentAmount = c.paymentAmount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(c.paymentAmount))
            : String(c.paymentAmount)
        currency = c.currency
        userCount = String(c.userCount)
        username = c.username
        password = KeychainManager.shared.getPassword(for: c.id)
        notes = c.notes
        paymentDate = c.paymentDate
        isMonthlyBilling = c.isMonthlyBilling
    }

    private func saveCustomer() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            formError = "Customer name is required."
            return
        }
        guard let amount = Double(paymentAmount.replacingOccurrences(of: ",", with: ".")), amount > 0 else {
            formError = "Enter a valid payment amount."
            return
        }
        guard let count = Int(userCount), count > 0 else {
            formError = "Enter a valid user count."
            return
        }
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            formError = "Username is required."
            return
        }
        formError = nil

        if let c = customer {
            c.name = name
            c.paymentAmount = amount
            c.currency = currency
            c.userCount = count
            c.username = username
            c.notes = notes
            c.paymentDate = paymentDate
            c.isMonthlyBilling = isMonthlyBilling
            KeychainManager.shared.savePassword(password, for: c.id)
            NotificationManager.shared.scheduleNotifications(for: c)
            try? modelContext.save()
        } else {
            let newCustomer = Customer(
                name: name, paymentAmount: amount, currency: currency,
                userCount: count, username: username, notes: notes,
                paymentDate: paymentDate, isMonthlyBilling: isMonthlyBilling
            )
            modelContext.insert(newCustomer)
            try? modelContext.save()
            KeychainManager.shared.savePassword(password, for: newCustomer.id)
            NotificationManager.shared.scheduleNotifications(for: newCustomer)
        }
        dismiss()
    }
}

struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
