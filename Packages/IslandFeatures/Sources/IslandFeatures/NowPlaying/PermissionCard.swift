import IslandCore
import IslandDesign
import SwiftUI

/// Home hero while a player needs Automation consent: one sentence and an Allow button (the only path to the
/// system prompt, so it never surprises the user).
struct PermissionCard: View {
    let source: MediaSourceID
    let onAllow: @MainActor () -> Void

    init(source: MediaSourceID, onAllow: @escaping @MainActor () -> Void) {
        self.source = source
        self.onAllow = onAllow
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill").font(TypeToken.title.font).foregroundStyle(Palette.textSecondary)
            Text(source == .music ? "permission.music" : "permission.spotify", bundle: .module)
                .font(TypeToken.body.font)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button(action: onAllow) {
                Text("permission.allow", bundle: .module)
                    .font(TypeToken.body.font)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Palette.inkPressed, in: Capsule())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.textPrimary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .islandCard()
    }
}
