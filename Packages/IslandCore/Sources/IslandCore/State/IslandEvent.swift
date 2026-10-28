import Foundation

public enum IslandHitTarget: Hashable, Sendable {
    case island
    case bubble(ActivityID)
}

public enum IslandEvent: Equatable, Sendable {
    case pointerEnteredHotZone
    case pointerDwellElapsed(speed: Double)
    case pointerExitedIsland
    case exitGraceElapsed
    case clicked(IslandHitTarget)
    case swipedDown
    case swipedUp
    case escapePressed
    case clickedOutside
    case toggleRequested
    case pageSelected(IslandPage)
    case fileDragApproached
    case fileDragLeft
    case activitiesChanged(IslandLayout)
    case alertRaised(TransientAlert)
    case alertExpired
    case fullscreenChanged(Bool)
    case displayConfigurationChanged
    case systemWillSleep
    case systemDidWake
    case optionsChanged(IslandOptions)
}
