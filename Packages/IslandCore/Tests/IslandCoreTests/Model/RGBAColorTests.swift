import Testing

@testable import IslandCore

@Suite struct RGBAColorTests {
    @Test func parsesHexWithAndWithoutHash() {
        let orange = RGBAColor(red: 1, green: 128.0 / 255, blue: 0)
        #expect(RGBAColor(hex: "#FF8000") == orange)
        #expect(RGBAColor(hex: "ff8000") == orange)
        #expect(RGBAColor(hex: "XYZ") == nil)
        #expect(RGBAColor(hex: "+FF800") == nil)
        #expect(orange.hexString == "#FF8000")
    }
}
