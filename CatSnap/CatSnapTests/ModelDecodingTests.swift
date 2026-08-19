import Foundation
import Testing
@testable import CatSnap

/// These tests exist because every model in `Core/Models` mirrors
/// `docs/new-schema.sql` **by hand**, and the seven RPCs are called by string
/// name. Rename a column server-side and nothing fails to compile — it fails
/// at runtime, in a user's hands.
///
/// Each fixture below is the wire shape PostgREST returns. When the schema
/// changes, update the fixture in the same commit as the model; a mismatch
/// then shows up here rather than in TestFlight.
@Suite("Model decoding")
struct ModelDecodingTests {

    // MARK: - cats

    @Test("Cat decodes a fully populated row")
    func catDecodesFullRow() throws {
        let cat = try PostgrestFixture.decode(Cat.self, from: """
        {
          "id": "3f1e4d6a-0c2b-4a7e-9f11-2b3c4d5e6f70",
          "created_by": "9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d",
          "name": "Marmalade",
          "description": "Sleeps on the wall outside the chippy.",
          "primary_photo_url": "https://example.test/cats/marmalade.jpg",
          "rarity": "rare",
          "created_at": "2026-08-18T14:32:58.123456+00:00",
          "updated_at": "2026-08-18T14:32:58.123456+00:00"
        }
        """)

        #expect(cat.name == "Marmalade")
        #expect(cat.rarity == .rare)
        #expect(cat.primaryPhotoUrl?.host == "example.test")
        #expect(cat.createdBy != nil)
    }

    @Test("Cat decodes an unnamed, photoless row")
    func catDecodesSparseRow() throws {
        // A cat created by find_or_create_cat before anyone names it.
        let cat = try PostgrestFixture.decode(Cat.self, from: """
        {
          "id": "3f1e4d6a-0c2b-4a7e-9f11-2b3c4d5e6f70",
          "created_by": null,
          "name": null,
          "description": null,
          "primary_photo_url": null,
          "rarity": "common",
          "created_at": "2026-08-18T14:32:58+00:00",
          "updated_at": "2026-08-18T14:32:58+00:00"
        }
        """)

        #expect(cat.name == nil)
        #expect(cat.primaryPhotoUrl == nil)
        #expect(cat.rarity == .common)
    }

    @Test("Cat.Rarity covers exactly the values the CHECK constraint allows")
    func rarityMatchesSchemaConstraint() {
        // docs/new-schema.sql constrains cats.rarity to these four. If the
        // constraint gains a value, this fails until the enum catches up.
        #expect(Set(Cat.Rarity.allCases.map(\.rawValue))
                == ["common", "uncommon", "rare", "legendary"])
    }

    @Test("Cat rejects a rarity outside the constraint")
    func rarityRejectsUnknownValue() {
        #expect(throws: DecodingError.self) {
            try PostgrestFixture.decode(Cat.self, from: """
            {
              "id": "3f1e4d6a-0c2b-4a7e-9f11-2b3c4d5e6f70",
              "created_by": null, "name": null, "description": null,
              "primary_photo_url": null,
              "rarity": "mythical",
              "created_at": "2026-08-18T14:32:58+00:00",
              "updated_at": "2026-08-18T14:32:58+00:00"
            }
            """)
        }
    }

    // MARK: - sightings

    @Test("Sighting decodes a photo-backed row")
    func sightingDecodes() throws {
        let sighting = try PostgrestFixture.decode(Sighting.self, from: """
        {
          "id": "11111111-2222-4333-8444-555555555555",
          "user_id": "9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d",
          "cat_id": "3f1e4d6a-0c2b-4a7e-9f11-2b3c4d5e6f70",
          "photo_url": "https://example.test/sightings/1.jpg",
          "location_label": "Brick Lane",
          "notes": "Asleep in a doorway.",
          "seen_at": "2026-08-18T14:00:00+00:00",
          "created_at": "2026-08-18T14:32:58.123456+00:00"
        }
        """)

        #expect(sighting.locationLabel == "Brick Lane")
        #expect(sighting.photoUrl != nil)
    }

    @Test("Sighting decodes the no-photo check-in written by record_spot")
    func sightingDecodesWithoutPhoto() throws {
        // Migration 0003 relaxed sightings.photo_url to nullable so the
        // "I spotted them" path can write a row with no upload. If photoUrl
        // ever goes back to non-optional, this is what catches it.
        let sighting = try PostgrestFixture.decode(Sighting.self, from: """
        {
          "id": "11111111-2222-4333-8444-555555555555",
          "user_id": "9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d",
          "cat_id": "3f1e4d6a-0c2b-4a7e-9f11-2b3c4d5e6f70",
          "photo_url": null,
          "location_label": null,
          "notes": null,
          "seen_at": "2026-08-18T14:00:00+00:00",
          "created_at": "2026-08-18T14:32:58.123456+00:00"
        }
        """)

        #expect(sighting.photoUrl == nil)
        #expect(sighting.catId != nil)
    }

    @Test("NearbySighting decodes the full sightings_near column list")
    func nearbySightingDecodes() throws {
        // The widest drift surface in the app: 17 columns, all string-matched.
        let row = try PostgrestFixture.decode(NearbySighting.self, from: """
        {
          "id": "11111111-2222-4333-8444-555555555555",
          "user_id": "9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d",
          "cat_id": "3f1e4d6a-0c2b-4a7e-9f11-2b3c4d5e6f70",
          "photo_url": "https://example.test/sightings/1.jpg",
          "location_label": "Brick Lane",
          "notes": null,
          "seen_at": "2026-08-18T14:00:00+00:00",
          "lat": 51.5219,
          "lng": -0.0715,
          "cat_name": "Marmalade",
          "cat_photo_url": "https://example.test/cats/marmalade.jpg",
          "cat_rarity": "rare",
          "username": "jada",
          "display_name": "Jada",
          "avatar_url": null,
          "distance_m": 142.5,
          "is_favorite": true
        }
        """)

        #expect(row.username == "jada")
        #expect(row.catRarity == .rare)
        #expect(row.isFavorite)
        #expect(row.distanceM == 142.5)
        #expect(abs(row.lat - 51.5219) < 0.0001)
    }

    // MARK: - profiles and the friends graph

    @Test("Profile decodes")
    func profileDecodes() throws {
        let profile = try PostgrestFixture.decode(Profile.self, from: """
        {
          "id": "9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d",
          "username": "jada",
          "display_name": "Jada",
          "avatar_url": null,
          "bio": null,
          "is_admin": false,
          "created_at": "2026-08-18T14:32:58.123456+00:00"
        }
        """)

        #expect(profile.username == "jada")
        #expect(profile.isAdmin == false)
    }

    @Test("Friend decodes the my_friends row shape")
    func friendDecodes() throws {
        let friend = try PostgrestFixture.decode(Friend.self, from: """
        {
          "user_id": "9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d",
          "username": "sam",
          "display_name": null,
          "avatar_url": null,
          "followed_at": "2026-08-18T14:32:58.123456+00:00"
        }
        """)

        #expect(friend.username == "sam")
        #expect(friend.id == friend.userId)
    }

    @Test("ProfileSearchResult decodes the search_profiles row shape")
    func profileSearchResultDecodes() throws {
        let result = try PostgrestFixture.decode(ProfileSearchResult.self, from: """
        {
          "user_id": "9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d",
          "username": "sam",
          "display_name": "Sam",
          "avatar_url": null,
          "is_following": true
        }
        """)

        #expect(result.isFollowing)
    }

    @Test("Block decodes")
    func blockDecodes() throws {
        let block = try PostgrestFixture.decode(Block.self, from: """
        {
          "blocker_id": "9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d",
          "blocked_id": "3f1e4d6a-0c2b-4a7e-9f11-2b3c4d5e6f70",
          "created_at": "2026-08-18T14:32:58.123456+00:00"
        }
        """)

        #expect(block.blockerId != block.blockedId)
    }

    // MARK: - guide

    @Test("GuideRow decodes an unspotted cat")
    func guideRowDecodesUnspotted() throws {
        // last_seen_at, recent_photo_url and distance_m are all null for a cat
        // the user has never seen — the default state of most of the guide.
        let row = try PostgrestFixture.decode(GuideRow.self, from: """
        {
          "cat_id": "3f1e4d6a-0c2b-4a7e-9f11-2b3c4d5e6f70",
          "cat_name": "Marmalade",
          "primary_photo_url": null,
          "rarity": "legendary",
          "is_spotted": false,
          "is_favorite": false,
          "last_seen_at": null,
          "recent_photo_url": null,
          "distance_m": null
        }
        """)

        #expect(row.isSpotted == false)
        #expect(row.lastSeenAt == nil)
        #expect(row.distanceM == nil)
        #expect(row.rarity == .legendary)
    }
}

/// The `guide_list` RPC takes its arguments by name. These are encoded, not
/// decoded, so a rename breaks the call silently — Postgres just applies the
/// default for the parameter it never received, and the filter quietly does
/// nothing.
@Suite("RPC argument encoding")
struct RPCArgumentEncodingTests {

    @Test("GuideFilterCriteria encodes to the p_ parameter names guide_list expects")
    func guideFilterEncodesParameterNames() throws {
        var criteria = GuideFilterCriteria()
        criteria.favoritesOnly = true
        criteria.status = .notSpotted
        criteria.rarities = [.rare, .legendary]
        criteria.tags = ["ginger"]
        criteria.nearLat = 51.5219
        criteria.nearLng = -0.0715
        criteria.nearRadiusM = 500

        let data = try JSONEncoder().encode(criteria)
        let json = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        #expect(json["p_favorites_only"] as? Bool == true)
        #expect(json["p_status"] as? String == "not_spotted")
        #expect(json["p_rarities"] as? [String] == ["rare", "legendary"])
        #expect(json["p_tags"] as? [String] == ["ginger"])
        #expect(json["p_near_radius_m"] as? Int == 500)
    }

    @Test("An unfiltered GuideFilterCriteria omits every optional axis")
    func unfilteredCriteriaOmitsOptionals() throws {
        let data = try JSONEncoder().encode(GuideFilterCriteria())
        let json = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        // Only the two non-optional axes should travel; anything else would
        // override a Postgres default and silently narrow the guide.
        #expect(Set(json.keys) == ["p_favorites_only", "p_status"])
        #expect(json["p_status"] as? String == "all")
    }

    @Test("hasActiveFilters is false only for a pristine filter")
    func hasActiveFiltersReflectsState() {
        #expect(GuideFilterCriteria().hasActiveFilters == false)

        var withStatus = GuideFilterCriteria()
        withStatus.status = .spotted
        #expect(withStatus.hasActiveFilters)

        var withTags = GuideFilterCriteria()
        withTags.tags = ["ginger"]
        #expect(withTags.hasActiveFilters)

        var withEmptyTags = GuideFilterCriteria()
        withEmptyTags.tags = []
        #expect(withEmptyTags.hasActiveFilters == false)
    }
}
