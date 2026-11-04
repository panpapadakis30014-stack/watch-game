import Foundation

/// Screenshot modes, selected with the launch argument `-RingwardDemo start|midgame`.
/// These open Ringward directly, without the game picker.
enum DemoMode {
    case start, midgame
}

/// Lanternfall screenshot modes: `-LanternfallDemo picker|start|midgame|levelup`.
enum LanternfallDemoMode: String {
    case picker, start, midgame, levelup
}

/// Picker screenshot modes: `-PickerDemo top|bottom` (scrolled to the start or the end).
enum PickerDemoMode: String {
    case top, bottom
}

struct LaunchOptions {
    let demo: DemoMode?
    var lanternfallDemo: LanternfallDemoMode? = nil
    var pickerDemo: PickerDemoMode? = nil

    static var current: LaunchOptions {
        parse(ProcessInfo.processInfo.arguments)
    }

    static func parse(_ arguments: [String]) -> LaunchOptions {
        var options = LaunchOptions(demo: parseRingwardDemo(arguments))
        if let i = arguments.firstIndex(of: "-LanternfallDemo"), i + 1 < arguments.count {
            options.lanternfallDemo = LanternfallDemoMode(rawValue: arguments[i + 1])
        }
        if let i = arguments.firstIndex(of: "-PickerDemo"), i + 1 < arguments.count {
            options.pickerDemo = PickerDemoMode(rawValue: arguments[i + 1])
        }
        return options
    }

    private static func parseRingwardDemo(_ arguments: [String]) -> DemoMode? {
        guard let i = arguments.firstIndex(of: "-RingwardDemo"), i + 1 < arguments.count else {
            return nil
        }
        switch arguments[i + 1] {
        case "start": return .start
        case "midgame": return .midgame
        default: return nil
        }
    }
}
