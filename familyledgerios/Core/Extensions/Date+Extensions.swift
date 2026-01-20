import Foundation

extension Date {
    // MARK: - Formatters

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let displayTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static let displayDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let apiTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    // MARK: - Display Formatting

    var displayDate: String {
        Self.displayDateFormatter.string(from: self)
    }

    var displayTime: String {
        Self.displayTimeFormatter.string(from: self)
    }

    var displayDateTime: String {
        Self.displayDateTimeFormatter.string(from: self)
    }

    var shortDate: String {
        Self.shortDateFormatter.string(from: self)
    }

    var fullDate: String {
        Self.fullDateFormatter.string(from: self)
    }

    var apiDateString: String {
        Self.apiDateFormatter.string(from: self)
    }

    var apiTimeString: String {
        Self.apiTimeFormatter.string(from: self)
    }

    // MARK: - Relative Formatting

    var relativeString: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(self) {
            return "Tomorrow"
        } else {
            let components = calendar.dateComponents([.day], from: now, to: self)
            if let days = components.day {
                if days > 0 && days <= 7 {
                    return "In \(days) days"
                } else if days < 0 && days >= -7 {
                    return "\(abs(days)) days ago"
                }
            }
            return displayDate
        }
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    // MARK: - Parsing

    static func fromAPIDateString(_ string: String?) -> Date? {
        guard let string = string else { return nil }
        return apiDateFormatter.date(from: string)
    }

    static func fromISO8601String(_ string: String?) -> Date? {
        guard let string = string else { return nil }
        return iso8601Formatter.date(from: string)
    }

    // MARK: - Calculations

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    func adding(years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: self, to: Date()).year ?? 0
    }

    var isOverdue: Bool {
        self < Date()
    }

    var isDueToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isDueSoon: Bool {
        let sevenDaysFromNow = Date().adding(days: 7)
        return self <= sevenDaysFromNow && self >= Date()
    }
}
