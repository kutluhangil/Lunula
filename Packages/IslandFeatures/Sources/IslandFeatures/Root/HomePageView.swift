import IslandCore
import SwiftUI

/// G — Expanded Home: vertical stack with the unpadded hero row on top and a 2-column 56 pt tile grid below.
struct HomePageView: View {
    let inputs: HomeInputs

    var body: some View {
        let composed = HomeComposer.compose(inputs)
        VStack(spacing: 12) {
            if let hero = composed.hero {
                HomeCardView(card: hero).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if !composed.tiles.isEmpty {
                HStack(spacing: 8) {
                    ForEach(composed.tiles, id: \.self) { tile in
                        HomeCardView(card: tile)
                            .frame(maxWidth: .infinity)
                            .frame(height: composed.hero == nil ? nil : 56)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
