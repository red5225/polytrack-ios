import SwiftUI

@main
struct PolyTrackMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacContentView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
    }
}
