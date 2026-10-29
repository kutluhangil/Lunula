import Foundation

@MainActor public protocol ActivityProviding: AnyObject {
    var activities: [Activity] { get }
    var onActivitiesChange: (@MainActor () -> Void)? { get set }
}

@MainActor public protocol AlertProviding: AnyObject {
    var onAlert: (@MainActor (TransientAlert) -> Void)? { get set }
}
