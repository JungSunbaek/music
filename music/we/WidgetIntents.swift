import AppIntents
import WidgetKit

struct PlayPauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Play/Pause"
    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.jungsunbaek.music")
        defaults?.set("playpause", forKey: "widgetCommand")
        defaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines() // 추가
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Track"
    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.jungsunbaek.music")
        defaults?.set("next", forKey: "widgetCommand")
        defaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines() // 추가
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Track"
    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.jungsunbaek.music")
        defaults?.set("previous", forKey: "widgetCommand")
        defaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines() // 추가
        return .result()
    }
}
