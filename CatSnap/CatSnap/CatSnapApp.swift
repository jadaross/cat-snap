import SwiftUI

@main
struct CatSnapApp: App {
    @State private var session = AuthSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(session)
        }
    }
}
