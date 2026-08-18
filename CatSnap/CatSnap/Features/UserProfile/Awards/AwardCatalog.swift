import Foundation

// Single source of truth for the award list and its unlock predicates.
// The order here is the order awards render in the grid.
enum AwardCatalog {
    struct Inputs {
        let totalSightings: Int
        let catCount: Int
        let streak: Int
        let spottedToday: Bool
        let nightOwl: Bool
    }

    static func awards(from inputs: Inputs) -> [Award] {
        [
            Award(
                id: "first_snap",
                emoji: "🏅",
                label: "First Snap",
                description: "Your very first sighting on CatSnap.",
                criteria: "Log your first sighting.",
                rare: false,
                earned: inputs.totalSightings >= 1
            ),
            Award(
                id: "streak_10",
                emoji: "🔥",
                label: "10-day streak",
                description: "Spotted at least one cat per day, ten days in a row.",
                criteria: "Maintain a 10-day spotting streak.",
                rare: false,
                earned: inputs.streak >= 10
            ),
            Award(
                id: "legend",
                emoji: "★",
                label: "Legend",
                description: "Fifty sightings — you've put in the steps.",
                criteria: "Log 50 sightings.",
                rare: true,
                earned: inputs.totalSightings >= 50
            ),
            Award(
                id: "night_owl",
                emoji: "🌙",
                label: "Night owl",
                description: "Spotted a cat between 10pm and 6am.",
                criteria: "Log a sighting between 10pm and 6am.",
                rare: false,
                earned: inputs.nightOwl
            ),
            Award(
                id: "cats_20",
                emoji: "📚",
                label: "20 cats",
                description: "Twenty distinct cats in your guide.",
                criteria: "Spot 20 different cats.",
                rare: false,
                earned: inputs.catCount >= 20
            ),
            Award(
                id: "today_snap",
                emoji: "🎯",
                label: "Today's snap",
                description: "You've logged a sighting today — keep the streak going.",
                criteria: "Log at least one sighting today.",
                rare: false,
                earned: inputs.spottedToday
            ),
            Award(
                id: "cats_5",
                emoji: "🤝",
                label: "5 cats",
                description: "Five distinct cats — your guide is filling out.",
                criteria: "Spot 5 different cats.",
                rare: false,
                earned: inputs.catCount >= 5
            ),
            Award(
                id: "sightings_30",
                emoji: "🌧",
                label: "30 sightings",
                description: "Rain or shine — thirty sightings logged.",
                criteria: "Log 30 sightings.",
                rare: false,
                earned: inputs.totalSightings >= 30
            ),
            Award(
                id: "cats_50",
                emoji: "🏆",
                label: "50 cats",
                description: "Fifty distinct cats spotted. Serious dedication.",
                criteria: "Spot 50 different cats.",
                rare: false,
                earned: inputs.catCount >= 50
            ),
            Award(
                id: "streak_100",
                emoji: "💯",
                label: "100-day streak",
                description: "A hundred consecutive days of sightings.",
                criteria: "Maintain a 100-day spotting streak.",
                rare: true,
                earned: inputs.streak >= 100
            ),
            Award(
                id: "mystery",
                emoji: "❓",
                label: "Mystery",
                description: "An unrevealed achievement.",
                criteria: "Keep exploring — you'll know it when you find it.",
                rare: false,
                earned: false
            ),
            Award(
                id: "secret",
                emoji: "❓",
                label: "???",
                description: "A secret achievement.",
                criteria: "More to discover.",
                rare: false,
                earned: false
            ),
        ]
    }
}
