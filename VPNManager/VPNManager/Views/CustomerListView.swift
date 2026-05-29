import SwiftUI
import SwiftData

enum CustomerFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case dueSoon = "Due Soon"
    case expired = "Expired"
    case notExtended = "Not Extended"
}

struct CustomerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Customer.paymentDate) private var customers: [Customer]
    @State private var searchText = ""
    @State private var selectedFilter: CustomerFilter = .all
    @State private var showingAddCustomer = false

    private var filteredCustomers: [Customer] {
        var result = customers
        switch selectedFilter {
        case .all: break
        case .active: result = result.filter { $0.status == .active }
        case .dueSoon: result = result.filter { $0.isDueSoon }
        case .expired: result = result.filter { $0.status == .expired }
        case .notExtended: result = result.filter { $0.status == .notExtended }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                if filteredCustomers.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredCustomers) { customer in
                                NavigationLink(destination: CustomerDetailView(customer: customer)) {
                                    CustomerCard(customer: customer)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Customers")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search by name")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCustomer = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(LinearGradient(colors: [.accentIndigo, .accentPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                }
            }
            .sheet(isPresented: $showingAddCustomer) {
                AddEditCustomerView()
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CustomerFilter.allCases, id: \.self) { filter in
                    FilterChip(title: filter.rawValue, isSelected: selectedFilter == filter) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.appBackground)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.2.slash")
                .font(.system(size: 52))
                .foregroundColor(.textSecondary)
            Text(searchText.isEmpty ? "No customers yet" : "No results for \"\(searchText)\"")
                .font(.headline)
                .foregroundColor(.textSecondary)
            if searchText.isEmpty && selectedFilter == .all {
                Button(action: { showingAddCustomer = true }) {
                    Text("Add first customer")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: [.accentIndigo, .accentPurple], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            Spacer()
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected
                    ? LinearGradient(colors: [.accentIndigo, .accentPurple], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [Color.cardBackground, Color.cardBackground], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.clear : Color.cardBorder, lineWidth: 1))
        }
    }
}

struct CustomerCard: View {
    let customer: Customer

    private var cardBorderColor: Color {
        if customer.isOverdue { return .statusExpired.opacity(0.5) }
        if customer.isDueToday || customer.isDueTomorrow { return .dueSoon.opacity(0.5) }
        return .cardBorder
    }

    private var dateColor: Color {
        if customer.isOverdue { return .statusExpired }
        if customer.isDueToday || customer.isDueTomorrow { return .dueSoon }
        return .textSecondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(customer.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Text(customer.username)
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                StatusBadge(status: customer.status)
            }

            Divider().background(Color.cardBorder)

            HStack(spacing: 0) {
                InfoPill(icon: "dollarsign.circle.fill", value: customer.formattedAmount, color: .accentIndigo)
                Spacer()
                InfoPill(icon: "person.fill", value: "\(customer.userCount) users", color: .accentPurple)
                Spacer()
                InfoPill(icon: "calendar", value: customer.paymentDate.formattedShort, color: dateColor)
            }

            if customer.isOverdue || customer.isDueToday || customer.isDueTomorrow {
                let days = customer.paymentDate.daysUntil
                HStack(spacing: 6) {
                    Image(systemName: customer.isOverdue ? "exclamationmark.triangle.fill" : "clock.fill")
                        .font(.caption)
                    Text(customer.isOverdue ? "\(abs(days)) day(s) overdue" : days == 0 ? "Due today" : "Due tomorrow")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(dateColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(dateColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardBorderColor, lineWidth: 1))
    }
}

struct StatusBadge: View {
    let status: CustomerStatus

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.icon)
                .font(.system(size: 11))
            Text(status.rawValue)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct InfoPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
    }
}
