import { createClient } from "@/lib/supabase/server";
import { CatCard } from "@/components/cats/CatCard";
import Link from "next/link";

export const revalidate = 60; // revalidate every minute

export default async function CatsPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q } = await searchParams;
  const supabase = await createClient();

  let query = supabase
    .from("cats")
    .select(
      "id, name, description, primary_photo_url, created_at, sightings(seen_at)"
    )
    .order("created_at", { ascending: false })
    .limit(48);

  if (q) {
    query = query.ilike("name", `%${q}%`);
  }

  const { data: cats } = await query;

  return (
    <main className="mx-auto max-w-6xl px-4 py-8">
      <div className="flex items-center justify-between mb-6 gap-4 flex-wrap">
        <h1 className="text-2xl font-bold text-stone-900">
          {q ? `Cats matching "${q}"` : "All Cats"}
        </h1>
        <form className="flex gap-2">
          <input
            name="q"
            defaultValue={q}
            placeholder="Search by name…"
            className="rounded-xl border border-stone-300 bg-white px-4 py-2 text-sm focus:border-amber-500 focus:outline-none focus:ring-2 focus:ring-amber-500/20"
          />
          <button
            type="submit"
            className="rounded-xl bg-stone-800 px-4 py-2 text-sm font-medium text-white hover:bg-stone-900"
          >
            Search
          </button>
        </form>
      </div>

      {cats && cats.length > 0 ? (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
          {cats.map((cat) => {
            const lastSeen = (cat as { sightings?: { seen_at: string }[] }).sightings?.[0]?.seen_at;
            return (
              <CatCard
                key={cat.id}
                cat={cat}
                lastSeen={lastSeen}
              />
            );
          })}
        </div>
      ) : (
        <div className="flex flex-col items-center gap-4 py-20 text-center text-stone-400">
          <span className="text-5xl">🐱</span>
          <p className="text-lg font-medium">No cats found</p>
          {q && (
            <Link href="/cats" className="text-sm text-amber-600 hover:text-amber-700">
              Clear search
            </Link>
          )}
          <Link
            href="/sightings/new"
            className="mt-2 rounded-xl bg-amber-500 px-5 py-2.5 text-sm font-semibold text-white hover:bg-amber-600"
          >
            Add the first one!
          </Link>
        </div>
      )}
    </main>
  );
}
