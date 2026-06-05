import SwiftUI

@main
struct ChromaTunerApp: App {
    @StateObject private var audioManager = AudioManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioManager)
        }
    }
}
