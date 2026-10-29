import IslandCore
import Testing

@testable import Lunula

@MainActor @Suite struct PermissionRowTests {
    @Test func deniedShowsOpenSettingsButton() { #expect(PermissionRow.action(for: .denied) == .openSettings) }

    @Test func grantedShowsNoAction() { #expect(PermissionRow.action(for: .granted) == nil) }

    @Test func everyFeatureHasToggle() {
        #expect(ActivitiesSettingsView.features.count == IslandFeature.allCases.count)
        #expect(Set(ActivitiesSettingsView.features) == Set(IslandFeature.allCases))
    }
}
