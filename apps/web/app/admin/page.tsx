import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { MergeRequestCard } from "./MergeRequestCard";

export const metadata = { title: "Admin — Cat Snap" };

export default async function AdminPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) redirect("/login?next=/admin");

  const { data: profile } = await supabase
    .from("users")
    .select("is_admin")
    .eq("id", user.id)
    .single();

  if (!profile?.is_admin) redirect("/");

  // Fetch pending merge requests
  const { data: mergeRequests } = await supabase
    .from("merge_requests")
    .select("*")
    .eq("status", "pending")
    .order("created_at", { ascending: true });

  // For each merge request, fetch the sightings involved
  const allSightingIds = (mergeRequests ?? []).flatMap((mr) => mr.sighting_ids);
  const { data: sightings } = allSightingIds.length > 0
    ? await supabase
        .from("sightings")
        .select("id, photo_url, cat_id, cats(id, name)")
        .in("id", allSightingIds)
    : { data: [] };

  const sightingMap = Object.fromEntries(
    (sightings ?? []).map((s) => [s.id, s])
  );

  return (
    <main className="mx-auto max-w-3xl px-4 py-8 space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-stone-900">Admin Dashboard</h1>
        <p className="text-sm text-stone-500 mt-1">Review pending merge requests.</p>
      </div>

      <section>
        <h2 className="text-lg font-semibold text-stone-900 mb-4">
          Pending Merge Requests ({(mergeRequests ?? []).length})
        </h2>
        {(mergeRequests ?? []).length === 0 ? (
          <p className="text-stone-400 text-sm">No pending requests.</p>
        ) : (
          <div className="space-y-4">
            {(mergeRequests ?? []).map((mr) => {
              const mrSightings = mr.sighting_ids
                .map((sid: string) => sightingMap[sid])
                .filter(Boolean);
              return (
                <MergeRequestCard
                  key={mr.id}
                  mergeRequest={mr}
                  sightings={mrSightings}
                />
              );
            })}
          </div>
        )}
      </section>
    </main>
  );
}
