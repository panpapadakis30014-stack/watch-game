import Foundation
import Observation

/// Which game is on screen. The picker comes first; each game's start and end
/// screens offer a "Games" button back to it. `-RingwardDemo` skips the
/// picker so Ringward's screenshots stay exactly as before.
@MainActor
@Observable
final class HubModel {
    enum Route {
        case picker, ringward, lanternfall
    }

    private(set) var route: Route
    let ringward: AppModel
    let lanternfall: LanternfallModel
    let showsPicker: Bool

    init(options: LaunchOptions) {
        if options.demo != nil {
            ringward = AppModel(options: options)
            lanternfall = LanternfallModel(demo: .start)
            route = .ringward
            showsPicker = false
        } else if let lf = options.lanternfallDemo {
            ringward = AppModel(options: LaunchOptions(demo: .start))
            lanternfall = LanternfallModel(demo: lf)
            route = lf == .picker ? .picker : .lanternfall
            showsPicker = true
        } else {
            ringward = AppModel(options: options)
            lanternfall = LanternfallModel(demo: nil)
            route = .picker
            showsPicker = true
        }
        if showsPicker {
            ringward.exitToPicker = { [weak self] in self?.route = .picker }
            lanternfall.exitToPicker = { [weak self] in self?.route = .picker }
        }
    }

    func open(_ target: Route) {
        switch target {
        case .ringward: ringward.showStart()
        case .lanternfall: lanternfall.showStart()
        case .picker: break
        }
        route = target
    }
}
