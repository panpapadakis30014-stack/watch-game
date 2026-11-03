import Foundation

/// Screenshot modes, selected with the launch argument `-RingwardDemo start|midgame`.
enum DemoMode {
    case start, midgame
}

struct LaunchOptions {
    let demo: DemoMode?

    static var current: LaunchOptions {
        parse(ProcessInfo.processInfo.arguments)
    }

    static func parse(_ arguments: [String]) -> LaunchOptions {
        guard let i = arguments.firstIndex(of: "-RingwardDemo"), i + 1 < arguments.count else {
            return LaunchOptions(demo: nil)
        }
        switch arguments[i + 1] {
        case "start": return LaunchOptions(demo: .start)
        case "midgame": return LaunchOptions(demo: .midgame)
        default: return LaunchOptions(demo: nil)
        }
    }
}
