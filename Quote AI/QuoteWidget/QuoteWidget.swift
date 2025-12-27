import WidgetKit
import SwiftUI
import AppIntents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), quote: "The best way to predict the future is to create it.")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), quote: getLatestQuote())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, quote: getLatestQuote())
        let timeline = Timeline(entries: [entry], policy: .after(currentDate.addingTimeInterval(60)))
        completion(timeline)
    }

    private func getLatestQuote() -> String {
        let sharedDefaults = UserDefaults(suiteName: SharedConstants.suiteName)
        return sharedDefaults?.string(forKey: SharedConstants.Keys.latestQuote) ?? "Tap to receive wisdom..."
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let quote: String
}

// MARK: - Main Widget Entry View
struct QuoteWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if family == .accessoryRectangular || family == .accessoryCircular || family == .accessoryInline {
            // Lock screen widgets - tappable
            Button(intent: QuoteWidgetIntent()) {
                lockScreenContent
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Home screen widgets - static
            homeScreenContent
        }
    }

    @ViewBuilder
    private var lockScreenContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 7, weight: .bold))
                Text("QUOTE AI")
                    .font(.system(size: 7, weight: .black))
                    .tracking(0.3)
            }
            .opacity(0.6)

            Text(entry.quote)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .italic()
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var homeScreenContent: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 8) {
            Image(systemName: "quote.opening")
                .foregroundColor(.primary)
                .font(family == .systemSmall ? .title3 : .title2)

            Text(entry.quote)
                .font(.system(family == .systemSmall ? .callout : (family == .systemMedium ? .title2 : .title), design: .serif))
                .fontWeight(family == .systemSmall ? .medium : .regular)
                .italic()
                .lineLimit(nil)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding()
    }
}

// MARK: - Widget Configuration
struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                QuoteWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color.clear
                    }
            } else {
                QuoteWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Daily Wisdom")
        .description("Tap to generate AI-powered quotes.")
        .supportedFamilies([
            .accessoryRectangular,
            .systemSmall,
            .systemMedium,
            .systemLarge
        ])
    }
}

// MARK: - Widget Intent
struct QuoteWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Fresh Wisdom"
    static var description = IntentDescription("Generates a new quote from the AI.")

    func perform() async throws -> some IntentResult {
        let sharedDefaults = UserDefaults(suiteName: SharedConstants.suiteName)

        do {
            // Using turbo model for fast response
            let newQuote = try await KimiService.shared.generateDailyCalibration()
            sharedDefaults?.set(newQuote, forKey: SharedConstants.Keys.latestQuote)
            sharedDefaults?.set(Date(), forKey: SharedConstants.Keys.lastRefreshDate)
            sharedDefaults?.synchronize()
            WidgetCenter.shared.reloadTimelines(ofKind: "QuoteWidget")
        } catch {
            // Keep existing quote on error
        }

        return .result()
    }
}
