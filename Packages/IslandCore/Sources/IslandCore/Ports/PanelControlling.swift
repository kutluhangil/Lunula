import Foundation

@MainActor public protocol PanelControlling: AnyObject {
    func setMouseEventsIgnored(_ ignored: Bool)
    func makeKey(_ key: Bool)
}
