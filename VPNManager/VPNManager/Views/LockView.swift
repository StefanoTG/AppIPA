import SwiftUI
import LocalAuthentication

struct LockView: View {
    @ObservedObject var biometric = BiometricManager.shared

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appBackground, Color(red: 0.10, green: 0.08, blue: 0.18)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.accentIndigo, .accentPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .shadow(color: .accentIndigo.opacity(0.5), radius: 20)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text("VPN Manager")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Authenticate to continue")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                if let error = biometric.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.statusExpired)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                Button(action: { biometric.authenticate() }) {
                    HStack(spacing: 12) {
                        Image(systemName: biometricIcon)
                            .font(.title3)
                        Text(biometricLabel)
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.accentIndigo, .accentPurple], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .accentIndigo.opacity(0.4), radius: 12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                biometric.authenticate()
            }
        }
    }

    private var biometricIcon: String {
        switch biometric.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.open.fill"
        }
    }

    private var biometricLabel: String {
        switch biometric.biometricType {
        case .faceID: return "Unlock with Face ID"
        case .touchID: return "Unlock with Touch ID"
        default: return "Unlock with Passcode"
        }
    }
}
