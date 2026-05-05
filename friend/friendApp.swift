import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import FirebaseFirestore
import FirebaseStorage
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
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

        var settings = Firestore.firestore().settings
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
        
        // Push Notification Setup
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
        application.registerForRemoteNotifications()
        
        // Messaging Delegate
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // Receive device token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // Receive FCM token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        // Store token in UserDefaults to retrieve it later when user logs in
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: "fcmToken")
            // If user is already logged in, update it in Firestore
            NotificationCenter.default.post(name: Notification.Name("FCMTokenUpdated"), object: token)
        }
    }
    
    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([[.banner, .sound, .badge]])
    }
}

@main
struct friendApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
    }
}

private struct RootView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else if Auth.auth().currentUser != nil {
                InitialProfileSetupView()
            } else {
                AuthEntryView()
            }
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-ui_testing_force_logout") {
                authManager.signOut()
            }
        }
        .onOpenURL { url in
            authManager.handleIncomingAuthLink(url)
        }
    }
}
