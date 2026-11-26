
import SwiftUI
@main struct ADMINMINHDUCApp: App {
    @StateObject private var license = LicenseManager()
    var body: some Scene {
        WindowGroup {
            Group { if license.isActive { MainView() } else { LicenseActivationView() } }
                .environmentObject(license).preferredColorScheme(.dark)
                .task { license.beginLaunchSession() }
        }
    }
}
