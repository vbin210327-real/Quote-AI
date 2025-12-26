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
        // Refresh every minute to pick up changes
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
        Button(intent: QuoteWidgetIntent()) {
            content
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        if family == .accessoryRectangular {
            // Lock Screen widget
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 10, weight: .bold))
                    Text("QUOTE AI")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1)
                    Spacer()
                }
                .opacity(0.8)

                Text(entry.quote)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .italic()
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else if family == .accessoryCircular {
            // Circular widget
            VStack {
                Image(systemName: "quote.opening")
                    .font(.title3)
            }
        } else if family == .accessoryInline {
            // Inline widget
            Text("Tap for wisdom")
        } else {
            // Home Screen Widgets
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "quote.opening")
                        .foregroundColor(.yellow)
                        .font(.subheadline)
                    Text("DAILY WISDOM")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 2)

                Text(entry.quote)
                    .font(.system(family == .systemSmall ? .subheadline : .title3, design: .serif))
                    .italic()
                    .minimumScaleFactor(0.4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if family != .systemSmall {
                    Spacer()
                }
            }
            .padding()
        }
    }
}

// MARK: - Widget Configuration
struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuoteWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Wisdom")
        .description("Tap to generate AI-powered quotes.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline,
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
