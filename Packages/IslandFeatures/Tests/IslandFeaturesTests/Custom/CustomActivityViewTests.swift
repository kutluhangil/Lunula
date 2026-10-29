import IslandCore
import SwiftUI
import Testing

@testable import IslandFeatures

@MainActor @Suite struct CustomActivityViewTests {
    @Test func invalidSymbolFallsBackToSparkle() {
        #expect(CustomSymbol.resolve("not.a.real.symbol") == "sparkle")
        #expect(CustomSymbol.resolve("hammer") == "hammer")
        #expect(CustomSymbol.resolve(nil) == "sparkle")
    }

    @Test func customCardRenders() {
        let s = CustomActivitySnapshot(
            title: "Derleme", subtitle: "Lunula · Release", symbol: "hammer", progress: 0.4, endsAt: nil)
        #expect(ImageRenderer(content: CustomExpandedCard(snapshot: s, accent: nil).frame(width: 492)).cgImage != nil)
    }
}
