import Foundation
import IslandCoreTestSupport
import Testing

@testable import IslandCore

private let mbp14 = ScreenDescriptor.mbp14
private let external = ScreenDescriptor.external

@Suite struct DisplaySelectionTests {
    @Test func notchedOnlySelectsNotchedScreen() {
        #expect(DisplaySelection.screens(from: [mbp14, external], mode: .notchedOnly).map(\.id) == [1])
    }
    @Test func notchedOnlyFallsBackToMainWhenNoNotchedScreen() {
        var ext = external
        ext.isMain = true
        #expect(DisplaySelection.screens(from: [ext], mode: .notchedOnly).map(\.id) == [2])
    }
    @Test func allDisplaysSelectsEvery() {
        #expect(DisplaySelection.screens(from: [mbp14, external], mode: .allDisplays).count == 2)
    }
    @Test func mainDisplayFallsBackToFirstScreenWhenNoMain() {
        var a = external
        a.isMain = false
        var b = mbp14
        b.isMain = false
        #expect(DisplaySelection.screens(from: [a, b], mode: .mainDisplay).map(\.id) == [a.id])
    }
    @Test func mainDisplaySelectsMain() {
        #expect(DisplaySelection.screens(from: [mbp14, external], mode: .mainDisplay).map(\.id) == [1])
    }
}
