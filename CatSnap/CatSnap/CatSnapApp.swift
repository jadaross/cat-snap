import SwiftUI
import Sentry

@main
struct CatSnapApp: App {
    @State private var session = AuthSession()

    init() {
        setupSentry()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(session)
        }
    }

    private func setupSentry() {
        // Configure Sentry for crash reporting
        guard let dsn = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String,
              !dsn.isEmpty else {
            // Skip Sentry initialization if DSN is not configured
            return
        }

        #if DEBUG
        // In debug builds, enable debug logging and disable session tracking
        SentrySDK.start { options in
            options.dsn = dsn
            options.debug = true
            options.tracesSampleRate = 0.0
            options.sessionTracking = false
            options.enableAppHangTracking = false
            options.enableWatchdogTerminationTracking = false
        }
        #else
        // In release builds, enable full crash reporting with reasonable sampling
        SentrySDK.start { options in
            options.dsn = dsn
            options.debug = false
            options.tracesSampleRate = 0.1
            options.sessionTracking = true
            options.enableAppHangTracking = true
            options.enableWatchdogTerminationTracking = true
            options.environment = "production"
        }
        #endif
    }
}
