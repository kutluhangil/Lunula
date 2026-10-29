import IslandDesign
import SwiftUI

struct ShelfEmptyView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "tray").font(TypeToken.title.font)
            Text("shelf.empty", bundle: .module).font(TypeToken.body.font)
        }
        .foregroundStyle(Palette.textTertiary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
