import IslandCore
import SwiftUI

struct HomePageView: View {
    let inputs: HomeInputs

    var body: some View {
        let composed = HomeComposer.compose(inputs)
        HStack(spacing: 8) {
            if let hero = composed.hero { HomeCardView(card: hero).frame(maxWidth: .infinity) }
            // The quick-start tile needs room for three preset chips on one line.
            ForEach(composed.tiles, id: \.self) {
                HomeCardView(card: $0).frame(maxWidth: $0 == .timerQuickStart ? 200 : 140)
            }
        }
    }
}
