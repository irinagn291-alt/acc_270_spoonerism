import SwiftUI
import UIKit

/// Role: Onset. Root shell. Onboarding cover, then the locked Quiz onset. ReviewScreen is applied after onboarding.
struct ContentView: View {
    @State private var desk: OnsetDesk
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(desk: OnsetDesk = OnsetDesk.live()) {
        _desk = State(wrappedValue: desk)
    }

    var body: some View {
        ZStack {
            MarrowInk.background.ignoresSafeArea()
            if desk.isBooting {
                Image(MarrowArt.splash)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            } else if desk.showsOnboarding {
                OnboardingView(
                    onSkip: { Task { await desk.finishOnboarding() } },
                    onFinish: { Task { await desk.finishOnboarding() } }
                )
            } else {
                QuizView(desk: desk)
            }
        }
        .preferredColorScheme(.light)
        .tint(MarrowInk.accent)
        .animation(MarrowMotion.snap(reduceMotion), value: desk.showsOnboarding)
        .animation(MarrowMotion.snap(reduceMotion), value: desk.isBooting)
        .task { await desk.boot() }
        .onChange(of: scenePhase) { _, phase in
            Task { await desk.handle(phase: phase) }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            desk.refreshDay()
        }
    }
}

#Preview {
    ContentView()
}
