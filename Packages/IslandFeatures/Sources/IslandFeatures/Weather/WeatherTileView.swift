import IslandCore
import IslandDesign
import SwiftUI

struct WeatherTileView: View {
    let snapshot: WeatherSnapshot
    let units: UnitChoice

    init(snapshot: WeatherSnapshot, units: UnitChoice) {
        self.snapshot = snapshot
        self.units = units
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: WeatherSymbol.name(snapshot.condition, isDaylight: snapshot.isDaylight))
                    .symbolRenderingMode(.multicolor)
                    .font(TypeToken.title.font)
                Text(IslandFormat.temperature(celsius: snapshot.temperatureC, unit: units.temperature))
                    .font(TypeToken.title.font).monospacedDigit()
            }
            Text(
                "weather.highLow \(IslandFormat.temperature(celsius: snapshot.highC, unit: units.temperature)) \(IslandFormat.temperature(celsius: snapshot.lowC, unit: units.temperature))",
                bundle: .module
            )
            .font(TypeToken.caption.font).monospacedDigit().foregroundStyle(Palette.textSecondary)
            Text(LocalizedStringKey("weather.condition.\(snapshot.condition.rawValue)"), bundle: .module)
                .font(TypeToken.caption.font).foregroundStyle(Palette.textSecondary)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
            if let place = snapshot.placeName {
                Text(place).font(TypeToken.caption.font).foregroundStyle(Palette.textTertiary).lineLimit(1)
            }
        }
        .foregroundStyle(Palette.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .background(Palette.inkRaised, in: RoundedRectangle(cornerRadius: Radii.card, style: .continuous))
    }
}
