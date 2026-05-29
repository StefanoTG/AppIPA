import LocalAuthentication
import Foundation

final class BiometricManager: ObservableObject {
    static let shared = BiometricManager()
    @Published var isUnlocked = false
    @Published var authError: String?

    private init() {}

    var biometricType: LABiometryType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        return context.biometryType
    }

    func authenticate() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Unlock VPN Manager to view your customer data."
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, authError in
                DispatchQueue.main.async {
                    if success {
                        self?.isUnlocked = true
                        self?.authError = nil
                    } else {
                        self?.authError = authError?.localizedDescription ?? "Authentication failed"
                        self?.isUnlocked = false
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.isUnlocked = true
            }
        }
    }

    func lock() {
        isUnlocked = false
    }
}
