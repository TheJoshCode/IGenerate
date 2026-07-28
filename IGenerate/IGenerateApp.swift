import SwiftUI

@main
struct IGenerateApp: App {
    @StateObject private var store = GenerationStore()

    init() {
        UITabBar.appearance().backgroundColor = .white
        UITabBar.appearance().tintColor = .black
        UINavigationBar.appearance().backgroundColor = .white
        UINavigationBar.appearance().tintColor = .black
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .preferredColorScheme(.light) // app is intentionally monochrome, not theme-adaptive
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            GenerateView()
                .tabItem {
                    Label("Generate", systemImage: "wand.and.stars")
                }

            GenerationsView()
                .tabItem {
                    Label("Generations", systemImage: "square.grid.2x2")
                }
        }
        .tint(Theme.ink)
    }
}
