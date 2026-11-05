import Foundation
import Testing

@testable import IslandCore

@Suite struct CompetingAppsTests {
    @Test func detectsKnownCompetitorOnce() {
        let boringNotch = "theboringteam.boringnotch"
        #expect(CompetingApps.detect(running: [boringNotch], alreadyNotified: []) == boringNotch)
        #expect(CompetingApps.detect(running: [boringNotch], alreadyNotified: [boringNotch]) == nil)
    }

    @Test func callActivityDetectorFindsActiveCallApp() {
        let micActive = PrivacySnapshot(cameraInUse: false, microphoneInUse: true)
        #expect(CallActivityDetector.activeCallApp(privacy: micActive, runningBundleIDs: ["us.zoom.xos"]) == "Zoom")
        #expect(CallActivityDetector.activeCallApp(privacy: .none, runningBundleIDs: ["us.zoom.xos"]) == nil)
    }

    @Test func modifierDoubleTapDetectorFiresOnCleanDoubleTapAndResetsOnContamination() {
        var detector = ModifierDoubleTapDetector(minimumInterval: 0.04, maximumInterval: 0.36)
        let t0 = Date(timeIntervalSince1970: 100)
        // First tap
        let r1 = detector.registerFlagsChange(targetPressed: true, otherModifiersPressed: false, at: t0)
        let r2 = detector.registerFlagsChange(
            targetPressed: false, otherModifiersPressed: false, at: t0.addingTimeInterval(0.08))
        #expect(!r1 && !r2)
        // Second tap within 0.2s
        let r3 = detector.registerFlagsChange(
            targetPressed: true, otherModifiersPressed: false, at: t0.addingTimeInterval(0.20))
        let r4 = detector.registerFlagsChange(
            targetPressed: false, otherModifiersPressed: false, at: t0.addingTimeInterval(0.26))
        #expect(!r3 && r4)

        // Contaminated tap with another modifier should not fire
        _ = detector.registerFlagsChange(
            targetPressed: true, otherModifiersPressed: false, at: t0.addingTimeInterval(1.0))
        _ = detector.registerFlagsChange(
            targetPressed: false, otherModifiersPressed: false, at: t0.addingTimeInterval(1.06))
        _ = detector.registerFlagsChange(
            targetPressed: true, otherModifiersPressed: true, at: t0.addingTimeInterval(1.15))
        let r5 = detector.registerFlagsChange(
            targetPressed: false, otherModifiersPressed: false, at: t0.addingTimeInterval(1.20))
        #expect(!r5)
    }
}
