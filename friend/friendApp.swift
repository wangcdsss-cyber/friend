import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UserNotifications

#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        if ProcessInfo.processInfo.environment["USE_FIREBASE_EMULATOR"] == "1" {
            let authHost = ProcessInfo.processInfo.environment["AUTH_EMULATOR_HOST"] ?? "localhost"
            let authPort = Int(ProcessInfo.processInfo.environment["AUTH_EMULATOR_PORT"] ?? "9099") ?? 9099
            Auth.auth().useEmulator(withHost: authHost, port: authPort)

            let host = ProcessInfo.processInfo.environment["FIRESTORE_EMULATOR_HOST"] ?? "localhost"
            let port = Int(ProcessInfo.processInfo.environment["FIRESTORE_EMULATOR_PORT"] ?? "8080") ?? 8080
            Firestore.firestore().useEmulator(withHost: host, port: port)

            let storageHost = ProcessInfo.processInfo.environment["STORAGE_EMULATOR_HOST"] ?? "localhost"
            let storagePort = Int(ProcessInfo.processInfo.environment["STORAGE_EMULATOR_PORT"] ?? "9199") ?? 9199
            Storage.storage().useEmulator(withHost: storageHost, port: storagePort)
        }
        
        // Push Notification Setup (defer permission request to after first screen)
        UNUserNotificationCenter.current().delegate = self
        
        // Messaging Delegate
        #if canImport(FirebaseMessaging)
        Messaging.messaging().delegate = self
        #endif
        
        return true
    }

    func enablePushNotifications() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    // Receive device token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        #if canImport(FirebaseMessaging)
        Messaging.messaging().apnsToken = deviceToken
        #endif
    }
    
    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([[.banner, .sound, .badge]])
    }
}

#if canImport(FirebaseMessaging)
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: "fcmToken")
            NotificationCenter.default.post(name: Notification.Name("FCMTokenUpdated"), object: token)
        }
    }
}
#endif

@main
struct friendApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            RootView(appDelegate: delegate)
                .environmentObject(authManager)
        }
    }
}

private struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    let appDelegate: AppDelegate
    @State private var didEnablePush = false

    var body: some View {
        Group {
            switch authManager.sessionState {
            case .signedInReady:
                MainTabView()
            case .signedInNeedsProfile:
                InitialProfileSetupView()
            case .signedOut, .checking:
                AuthEntryView()
            }
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-ui_testing_force_logout") {
                authManager.signOut()
            }
        }
        .onChange(of: authManager.sessionState) { _, newValue in
            guard newValue == .signedInReady, !didEnablePush else { return }
            didEnablePush = true
            appDelegate.enablePushNotifications()
        }
        .onOpenURL { url in
            authManager.handleIncomingAuthLink(url)
        }
    }
}
