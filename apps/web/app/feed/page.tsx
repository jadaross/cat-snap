import { redirect } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { SightingCard } from "@/components/sightings/SightingCard";
import type { SightingWithRelations } from "@/lib/hooks/useSightings";

export default async function FeedPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login?next=/feed");
  }

  // Get accepted friend IDs
  const { data: friendships } = await supabase
    .from("friendships")
    .select("requester_id, addressee_id")
    .or(`requester_id.eq.${user.id},addressee_id.eq.${user.id}`)
    .eq("status", "accepted");

  const friendIds = (friendships ?? []).map((f) =>
    f.requester_id === user.id ? f.addressee_id : f.requester_id
  );

  let sightings: SightingWithRelations[] = [];

  if (friendIds.length > 0) {
    const { data } = await supabase
      .from("sightings")
      .select("*, cats(id, name, primary_photo_url), users(id, username, display_name, avatar_url)")
      .in("user_id", friendIds)
      .in("visibility", ["public", "friends"])
      .order("seen_at", { ascending: false })
      .limit(50);

    sightings = (data ?? []) as SightingWithRelations[];
  }

  return (
    <main className="mx-auto max-w-xl px-4 py-8 space-y-6">
      <h1 className="text-2xl font-bold text-stone-900">Friend Feed</h1>

      {sightings.length === 0 ? (
        <div className="flex flex-col items-center gap-4 py-20 text-center text-stone-400">
          <span className="text-5xl">🐾</span>
          <p className="text-lg font-medium">Nothing here yet</p>
          <p className="text-sm max-w-xs">
            {friendIds.length === 0
              ? "Add some friends to see their cat sightings here."
              : "Your friends haven't posted any sightings recently."}
          </p>
          <Link
            href="/map"
            className="mt-2 rounded-xl bg-amber-500 px-5 py-2.5 text-sm font-semibold text-white hover:bg-amber-600"
          >
            Explore the map
          </Link>
        </div>
      ) : (
        sightings.map((s) => (
          <SightingCard key={s.id} sighting={s} currentUserId={user.id} />
        ))
      )}
    </main>
  );
}
