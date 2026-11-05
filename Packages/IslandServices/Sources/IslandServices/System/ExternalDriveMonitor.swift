import AppKit
import Foundation
import IslandCore
import Observation

public struct MountedDrive: Identifiable, Equatable, Sendable {
    public var id: String { url.path() }
    public var name: String
    public var url: URL

    public init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}

/// Watches removable/external volume mounts via `NSWorkspace` notifications and provides 1-tap safe eject.
@MainActor @Observable public final class ExternalDriveMonitor: AlertProviding {
    @ObservationIgnored public var onAlert: (@MainActor (TransientAlert) -> Void)?
    @ObservationIgnored private var mountObserver: NSObjectProtocol?
    @ObservationIgnored private var unmountObserver: NSObjectProtocol?

    public private(set) var drives: [MountedDrive] = []

    public init() {}

    public func start() {
        guard mountObserver == nil else { return }
        refreshDrives()
        let nc = NSWorkspace.shared.notificationCenter
        mountObserver = nc.addObserver(forName: NSWorkspace.didMountNotification, object: nil, queue: .main) {
            [weak self] note in
            let url = note.userInfo?[NSWorkspace.localizedVolumeNameUserInfoKey] as? String
            let volumeURL = note.userInfo?["NSWorkspaceVolumeURLKey"] as? URL
            Task { @MainActor [weak self] in
                self?.refreshDrives()
                let title = url ?? volumeURL?.lastPathComponent ?? "USB"
                self?.onAlert?(
                    TransientAlert(
                        id: UUID(), kind: .custom,
                        detail: .text(title: title, subtitle: nil, symbol: "externaldrive.fill.badge.checkmark"),
                        tint: .green, duration: 2.4, priority: .normal))
            }
        }
        unmountObserver = nc.addObserver(forName: NSWorkspace.didUnmountNotification, object: nil, queue: .main) {
            [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshDrives() }
        }
    }

    public func stop() {
        let nc = NSWorkspace.shared.notificationCenter
        if let mountObserver { nc.removeObserver(mountObserver) }
        if let unmountObserver { nc.removeObserver(unmountObserver) }
        mountObserver = nil
        unmountObserver = nil
    }

    public func eject(_ url: URL, safeDisconnectMessage: String) {
        let volumeName = url.lastPathComponent
        Task.detached { [weak self] in
            do {
                try NSWorkspace.shared.unmountAndEjectDevice(at: url)
                await MainActor.run {
                    self?.refreshDrives()
                    self?.onAlert?(
                        TransientAlert(
                            id: UUID(), kind: .custom,
                            detail: .text(
                                title: volumeName, subtitle: safeDisconnectMessage, symbol: "eject.circle.fill"),
                            tint: .green, duration: 2.4, priority: .normal))
                }
            } catch {
                await MainActor.run { self?.refreshDrives() }
            }
        }
    }

    public func refreshDrives() {
        let keys: [URLResourceKey] = [
            .volumeNameKey, .volumeIsRemovableKey, .volumeIsEjectableKey, .volumeIsInternalKey,
        ]
        guard
            let urls = FileManager.default.mountedVolumeURLs(
                includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes])
        else {
            drives = []
            return
        }
        drives = urls.compactMap { url -> MountedDrive? in
            guard let vals = try? url.resourceValues(forKeys: Set(keys)) else { return nil }
            let removable = vals.volumeIsRemovable == true || vals.volumeIsEjectable == true
            let isExternal = vals.volumeIsInternal == false
            guard removable || isExternal else { return nil }
            let name = vals.volumeName ?? url.lastPathComponent
            return MountedDrive(name: name, url: url)
        }
    }
}
