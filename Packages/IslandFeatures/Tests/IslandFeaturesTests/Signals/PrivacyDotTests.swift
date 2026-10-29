import IslandCore
import IslandDesign
import Testing

@testable import IslandFeatures

@Suite struct PrivacyDotTests {
    @Test func dotColorsMatchSystemConvention() {
        #expect(
            PrivacyDotColors.colors(for: .init(cameraInUse: true, microphoneInUse: true)) == [
                Palette.signalGreen, Palette.signalOrange,
            ])
        #expect(PrivacyDotColors.colors(for: .none).isEmpty)
    }
}
