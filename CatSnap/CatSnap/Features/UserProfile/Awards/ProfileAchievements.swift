import Foundation

// Pure derivation of streak + heatmap + awards from a user's sightings.
// `now` and `calendar` are injectable so this is testable without leaning
// on wall-clock time.
enum ProfileAchievements {
    struct Result {
        let awards: [Award]
        let streakDays: Int
        // Last 17 days, oldest → newest; true = at least one sighting that day.
        let heatmap: [Bool]
    }

    static func evaluate(
        sightings: [Sighting],
        catCount: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Result {
        let activeDays = Set(sightings.map { calendar.startOfDay(for: $0.seenAt) })
        let today = calendar.startOfDay(for: now)

        let streakDays = computeStreak(activeDays: activeDays, today: today, calendar: calendar)
        let heatmap = computeHeatmap(activeDays: activeDays, today: today, calendar: calendar)
        let spottedToday = activeDays.contains(today)
        let nightOwl = sightings.contains { sighting in
            let h = calendar.component(.hour, from: sighting.seenAt)
            return h < 6 || h >= 22
        }

        let awards = AwardCatalog.awards(from: AwardCatalog.Inputs(
            totalSightings: sightings.count,
            catCount: catCount,
            streak: streakDays,
            spottedToday: spottedToday,
            nightOwl: nightOwl
        ))

        return Result(awards: awards, streakDays: streakDays, heatmap: heatmap)
    }

    // Anchor on the most recent active day in {today, yesterday} so the
    // streak doesn't reset to zero the moment the calendar flips before
    // the user has logged a sighting today.
    private static func computeStreak(
        activeDays: Set<Date>,
        today: Date,
        calendar: Calendar
    ) -> Int {
        var endDay = today
        if !activeDays.contains(endDay) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  activeDays.contains(yesterday) else { return 0 }
            endDay = yesterday
        }

        var streak = 0
        var day = endDay
        while activeDays.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    private static func computeHeatmap(
        activeDays: Set<Date>,
        today: Date,
        calendar: Calendar
    ) -> [Bool] {
        (0..<17).map { offset in
            guard let day = calendar.date(byAdding: .day, value: -(16 - offset), to: today) else { return false }
            return activeDays.contains(day)
        }
    }
}
