import SwiftUI
import SwiftData

@main
struct VPNManagerApp: App {
    @ObservedObject private var biometric = BiometricManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Customer.self, PaymentHistory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if biometric.isUnlocked {
                    ContentView()
                        .onAppear {
                            NotificationManager.shared.requestPermission()
                            insertSampleDataIfNeeded()
                        }
                } else {
                    LockView()
                }
            }
            .preferredColorScheme(.dark)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    biometric.lock()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private func insertSampleDataIfNeeded() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Customer>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let calendar = Calendar.current
        let today = Date()

        let sampleData: [(String, Double, String, Int, String, String, Int)] = [
            ("MaxManager", 45, "USDT", 30, "max1", "max2", 0),
            ("Hojjy", 1000, "Manat", 25, "hoja1", "hoja2", 4),
            ("Orash", 300, "Manat", 13, "orash11", "OrasH123456$", 4),
            ("Selim", 30, "USDT", 20, "selim11", "selim22", 10),
            ("Merdan", 400, "Manat", 20, "merdan", "MerdaN1234$$", 27),
            ("Aga", 300, "Manat", 10, "aga1", "aga1", 28)
        ]

        for (name, amount, currency, users, uname, pass, daysFromNow) in sampleData {
            let date = calendar.date(byAdding: .day, value: daysFromNow, to: today)!
            let c = Customer(
                name: name, paymentAmount: amount, currency: currency,
                userCount: users, username: uname,
                paymentDate: date, isMonthlyBilling: true
            )
            context.insert(c)
            try? context.save()
            KeychainManager.shared.savePassword(pass, for: c.id)
            NotificationManager.shared.scheduleNotifications(for: c)
        }
    }
}
