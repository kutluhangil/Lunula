import Foundation

public protocol BookmarkCoding: Sendable {
    func bookmark(for url: URL) throws -> Data
    func resolve(_ data: Data) throws -> (url: URL, isStale: Bool)
}

/// Sandbox-safe references to user files outside the container.
public struct SecurityScopedBookmarkCoding: BookmarkCoding {
    public init() {}

    /// Read-write scope when possible; files reachable only read-only (e.g. ~/Downloads) get a read-only scope.
    public func bookmark(for url: URL) throws -> Data {
        do {
            return try url.bookmarkData(
                options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            return try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil,
                relativeTo: nil)
        }
    }

    public func resolve(_ data: Data) throws -> (url: URL, isStale: Bool) {
        var stale = false
        let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, bookmarkDataIsStale: &stale)
        return (url, stale)
    }
}

/// Unscoped bookmarks for tests.
public struct PlainBookmarkCoding: BookmarkCoding {
    public init() {}

    public func bookmark(for url: URL) throws -> Data { try url.bookmarkData() }

    public func resolve(_ data: Data) throws -> (url: URL, isStale: Bool) {
        var stale = false
        let url = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale)
        return (url, stale)
    }
}
