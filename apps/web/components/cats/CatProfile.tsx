import Image from "next/image";
import Link from "next/link";
import type { CatRow, SightingRow, UserRow } from "@/lib/supabase/types";
import { DeleteCatButton } from "./DeleteCatButton";

type SightingWithUser = SightingRow & {
  users: Pick<UserRow, "username" | "display_name" | "avatar_url"> | null;
};

interface CatProfileProps {
  cat: CatRow;
  sightings: SightingWithUser[];
  followerCount?: number;
  currentUserId?: string;
  isAdmin?: boolean;
}

function timeAgo(isoDate: string): string {
  const diff = Date.now() - new Date(isoDate).getTime();
  const days = Math.floor(diff / 86_400_000);
  if (days === 0) return "today";
  if (days === 1) return "yesterday";
  if (days < 30) return `${days} days ago`;
  if (days < 365) return `${Math.floor(days / 30)} months ago`;
  return `${Math.floor(days / 365)} years ago`;
}

export function CatProfile({ cat, sightings, followerCount = 0, isAdmin }: CatProfileProps) {
  const lastSighting = sightings[0];
  const uniqueSpotters = new Set(sightings.map((s) => s.user_id)).size;

  return (
    <div className="mx-auto max-w-2xl px-4 py-8 space-y-8">
      {/* Hero */}
      <div className="flex gap-6 items-start">
        <div className="relative h-28 w-28 shrink-0 overflow-hidden rounded-2xl border border-stone-200 bg-stone-100 shadow-sm">
          {cat.primary_photo_url ? (
            <Image
              src={cat.primary_photo_url}
              alt={cat.name ?? "Cat"}
              fill
              className="object-cover"
              sizes="112px"
            />
          ) : (
            <div className="flex h-full items-center justify-center text-4xl">🐱</div>
          )}
        </div>
        <div className="flex-1 min-w-0">
          <h1 className="text-2xl font-bold text-stone-900">{cat.name ?? "Unnamed cat"}</h1>
          {cat.description && (
            <p className="mt-1 text-stone-600 text-sm">{cat.description}</p>
          )}
          <div className="mt-3 flex flex-wrap gap-3 text-sm text-stone-500">
            <span className="flex items-center gap-1">
              👁 <strong>{sightings.length}</strong> sightings
            </span>
            <span className="flex items-center gap-1">
              🧑 <strong>{uniqueSpotters}</strong> spotters
            </span>
            <span className="flex items-center gap-1">
              ❤️ <strong>{followerCount}</strong> followers
            </span>
          </div>
          <div className="mt-3 flex gap-2 flex-wrap">
            {cat.is_tnr && (
              <span className="rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-800">✂️ TNR'd</span>
            )}
            {cat.has_caretaker && (
              <span className="rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800">🏠 Has caretaker</span>
            )}
            {lastSighting && (
              <span className="rounded-full bg-stone-100 px-2.5 py-0.5 text-xs text-stone-600">
                Last seen {timeAgo(lastSighting.seen_at)}
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Admin delete */}
      {isAdmin && (
        <div className="flex justify-end">
          <DeleteCatButton catId={cat.id} catName={cat.name} />
        </div>
      )}

      {/* Check-in CTA */}
      <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4 flex items-center justify-between gap-4">
        <div>
          <p className="font-semibold text-amber-900 text-sm">Just saw this cat?</p>
          <p className="text-xs text-amber-700 mt-0.5">Log a check-in to let the community know they're still around.</p>
        </div>
        <Link
          href={`/sightings/new?cat=${cat.id}`}
          className="shrink-0 rounded-xl bg-amber-500 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-600 transition-colors"
        >
          I saw this cat!
        </Link>
      </div>

      {/* Sighting history */}
      <section>
        <h2 className="text-lg font-bold text-stone-900 mb-4">Sighting history</h2>
        {sightings.length === 0 ? (
          <p className="text-stone-400 text-sm">No sightings yet. Be the first to spot this cat!</p>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
            {sightings.map((s) => (
              <Link
                key={s.id}
                href={`/sightings/${s.id}`}
                className="group relative aspect-square overflow-hidden rounded-2xl border border-stone-200 bg-stone-100"
              >
                <Image
                  src={s.photo_url}
                  alt="Cat sighting"
                  fill
                  className="object-cover transition-transform duration-300 group-hover:scale-105"
                  sizes="(max-width: 640px) 50vw, 33vw"
                />
                <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/60 to-transparent px-2 py-1.5">
                  <p className="text-xs text-white">{timeAgo(s.seen_at)}</p>
                  {s.users && (
                    <p className="text-xs text-white/70">by {s.users.display_name ?? s.users.username}</p>
                  )}
                </div>
              </Link>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
