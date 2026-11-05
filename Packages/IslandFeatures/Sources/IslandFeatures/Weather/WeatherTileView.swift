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
        HStack(spacing: 12) {
            Image(systemName: WeatherSymbol.name(snapshot.condition, isDaylight: snapshot.isDaylight))
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.textPrimary)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if let place = snapshot.placeName, !place.isEmpty {
                        Text(place)
                            .font(TypeToken.body.font)
                            .foregroundStyle(Palette.textPrimary)
                            .lineLimit(1)
                    }
                    Text(IslandFormat.temperature(celsius: snapshot.temperatureC, unit: units.temperature))
                        .font(TypeToken.numeralCompact.font)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Text(LocalizedStringKey("weather.condition." + snapshot.condition.rawValue), bundle: .module)
                    Text(verbatim: "·")
                    Text(
                        "weather.highLow \(IslandFormat.temperature(celsius: snapshot.highC, unit: units.temperature)) \(IslandFormat.temperature(celsius: snapshot.lowC, unit: units.temperature))",
                        bundle: .module
                    )
                    .monospacedDigit()
                }
                .font(TypeToken.caption.font)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .islandCard()
    }
}
