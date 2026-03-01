import { notFound } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { Avatar } from "@/components/ui/Avatar";

interface Props {
  params: Promise<{ id: string }>;
}

function timeAgo(isoDate: string): string {
  const diff = Date.now() - new Date(isoDate).getTime();
  const mins = Math.floor(diff / 60_000);
  if (mins < 60) return `${mins} minutes ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs} hours ago`;
  return `${Math.floor(hrs / 24)} days ago`;
}

export default async function SightingPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: sighting } = await supabase
    .from("sightings")
    .select("*, cats(id, name, primary_photo_url), users(username, display_name, avatar_url)")
    .eq("id", id)
    .single();

  if (!sighting) notFound();

  const { data: comments } = await supabase
    .from("comments")
    .select("*, users(username, display_name, avatar_url)")
    .eq("sighting_id", id)
    .order("created_at", { ascending: true });

  const cat = (sighting as { cats?: { id: string; name: string | null; primary_photo_url: string | null } }).cats;
  const user = (sighting as { users?: { username: string; display_name: string | null; avatar_url: string | null } }).users;

  return (
    <main className="mx-auto max-w-xl px-4 py-8 space-y-6">
      {/* Photo */}
      <div className="relative aspect-square overflow-hidden rounded-2xl border border-stone-200 bg-stone-100">
        <Image
          src={sighting.photo_url}
          alt="Cat sighting"
          fill
          className="object-cover"
          sizes="(max-width: 640px) 100vw, 580px"
          priority
        />
      </div>

      {/* Meta */}
      <div className="flex items-start gap-3">
        <Avatar
          src={user?.avatar_url}
          name={user?.display_name ?? user?.username}
          size="md"
        />
        <div>
          <p className="font-semibold text-stone-900">
            <Link href={`/profile/${user?.username}`} className="hover:text-amber-700">
              {user?.display_name ?? user?.username ?? "Someone"}
            </Link>
            {" "}spotted{" "}
            {cat && (
              <Link href={`/cats/${cat.id}`} className="text-amber-700 hover:underline">
                {cat.name ?? "a cat"}
              </Link>
            )}
          </p>
          <p className="text-xs text-stone-400">{timeAgo(sighting.seen_at)}</p>
          {sighting.location_label && (
            <p className="text-xs text-stone-500 mt-0.5">📍 {sighting.location_label}</p>
          )}
        </div>
      </div>

      {sighting.notes && (
        <p className="text-stone-700">{sighting.notes}</p>
      )}

      {/* Comments */}
      <section className="space-y-4">
        <h2 className="font-semibold text-stone-900">
          {comments?.length ?? 0} comment{comments?.length !== 1 ? "s" : ""}
        </h2>
        {comments?.map((c) => {
          const cu = (c as { users?: { username: string; display_name: string | null; avatar_url: string | null } }).users;
          return (
            <div key={c.id} className="flex gap-3">
              <Avatar src={cu?.avatar_url} name={cu?.display_name ?? cu?.username} size="sm" />
              <div className="flex-1 rounded-xl bg-stone-50 px-4 py-2.5">
                <p className="text-xs font-semibold text-stone-700">
                  {cu?.display_name ?? cu?.username ?? "Someone"}
                </p>
                <p className="text-sm text-stone-700 mt-0.5">{c.body}</p>
              </div>
            </div>
          );
        })}
        {/* Comment form handled client-side — requires auth */}
        <CommentFormPlaceholder sightingId={id} />
      </section>
    </main>
  );
}

// Minimal placeholder — swap for a Client Component form
function CommentFormPlaceholder({ sightingId }: { sightingId: string }) {
  return (
    <form
      action={`/api/sightings/${sightingId}/comments`}
      method="POST"
      className="flex gap-2"
    >
      <input
        name="body"
        placeholder="Add a comment…"
        required
        className="flex-1 rounded-xl border border-stone-300 bg-white px-4 py-2 text-sm focus:border-amber-500 focus:outline-none"
      />
      <button
        type="submit"
        className="rounded-xl bg-amber-500 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-600"
      >
        Post
      </button>
    </form>
  );
}
