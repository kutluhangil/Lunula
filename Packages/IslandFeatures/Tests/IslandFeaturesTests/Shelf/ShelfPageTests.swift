import AppKit
import SwiftUI
import Testing

@testable import IslandFeatures

@MainActor @Suite struct ShelfPageTests {
    @Test func rendersEmptyAndFilled() {
        #expect(ImageRenderer(content: ShelfPage(items: []).frame(width: 492, height: 140)).cgImage != nil)
        let item = ShelfItemModel(
            id: UUID(), name: "Sunum.key", icon: NSImage(systemSymbolName: "doc", accessibilityDescription: nil)!,
            isReference: true, isMissing: false)
        #expect(ImageRenderer(content: ShelfPage(items: [item]).frame(width: 492, height: 140)).cgImage != nil)
    }

    @Test func airDropServiceIsAvailable() { #expect(NSSharingService(named: .sendViaAirDrop) != nil) }

    @Test func commandClickTogglesSelection() {
        let a = UUID()
        let b = UUID()
        var s = ShelfSelection()
        s.click(a, command: false)
        s.click(b, command: true)
        #expect(s.ids == [a, b])
        s.click(a, command: true)
        #expect(s.ids == [b])
        s.click(a, command: false)
        #expect(s.ids == [a])
    }
}
