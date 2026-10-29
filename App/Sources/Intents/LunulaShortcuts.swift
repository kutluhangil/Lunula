import AppIntents

struct LunulaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowActivityIntent(), phrases: ["Show activity in \(.applicationName)"],
            shortTitle: "intent.show.title", systemImageName: "sparkles")
        AppShortcut(
            intent: StartTimerIntent(), phrases: ["Start a timer in \(.applicationName)"],
            shortTitle: "intent.timer.title", systemImageName: "timer")
        AppShortcut(
            intent: ToggleIslandIntent(), phrases: ["Toggle \(.applicationName)"], shortTitle: "intent.toggle.title",
            systemImageName: "capsule")
    }
}
