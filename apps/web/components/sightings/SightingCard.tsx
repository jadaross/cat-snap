"use client";

import Image from "next/image";
import Link from "next/link";
import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Avatar } from "@/components/ui/Avatar";
import type { SightingWithRelations } from "@/lib/hooks/useSightings";

const REACTION_EMOJIS = ["❤️", "😮", "😂", "🙌"];

function timeAgo(isoDate: string): string {
  const diff = Date.now() - new Date(isoDate).getTime();
  const mins = Math.floor(diff / 60_000);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  return `${Math.floor(hrs / 24)}d ago`;
}

interface SightingCardProps {
  sighting: SightingWithRelations;
  currentUserId?: string;
}

export function SightingCard({ sighting, currentUserId }: SightingCardProps) {
  const [reactions, setReactions] = useState<Record<string, number>>({});
  const [userReaction, setUserReaction] = useState<string | null>(null);

  async function toggleReaction(emoji: string) {
    if (!currentUserId) return;
    const supabase = createClient();

    if (userReaction === emoji) {
      await supabase.from("reactions").delete().match({ sighting_id: sighting.id, user_id: currentUserId, emoji });
      setUserReaction(null);
      setReactions((r) => ({ ...r, [emoji]: Math.max(0, (r[emoji] ?? 1) - 1) }));
    } else {
      if (userReaction) {
        await supabase.from("reactions").delete().match({ sighting_id: sighting.id, user_id: currentUserId, emoji: userReaction });
        setReactions((r) => ({ ...r, [userReaction]: Math.max(0, (r[userReaction] ?? 1) - 1) }));
      }
      await supabase.from("reactions").insert({ sighting_id: sighting.id, user_id: currentUserId, emoji });
      setUserReaction(emoji);
      setReactions((r) => ({ ...r, [emoji]: (r[emoji] ?? 0) + 1 }));
    }
  }

  return (
    <article className="overflow-hidden rounded-2xl border border-stone-200 bg-white">
      {/* Header */}
      <div className="flex items-center gap-3 px-4 py-3">
        <Avatar
          src={sighting.users?.avatar_url}
          name={sighting.users?.display_name ?? sighting.users?.username}
          size="sm"
        />
        <div className="flex-1 min-w-0">
          <Link
            href={`/profile/${sighting.users?.username}`}
            className="text-sm font-semibold text-stone-900 hover:text-amber-700"
          >
            {sighting.users?.display_name ?? sighting.users?.username ?? "Someone"}
          </Link>
          <p className="text-xs text-stone-400">
            spotted{" "}
            <Link href={`/cats/${sighting.cat_id}`} className="font-medium text-stone-600 hover:text-amber-700">
              {sighting.cats?.name ?? "a cat"}
            </Link>{" "}
            · {timeAgo(sighting.seen_at)}
          </p>
        </div>
        {sighting.location_label && (
          <span className="text-xs text-stone-400 shrink-0">📍 {sighting.location_label}</span>
        )}
      </div>

      {/* Photo */}
      <Link href={`/sightings/${sighting.id}`} className="block relative aspect-[4/3] bg-stone-100">
        <Image
          src={sighting.photo_url}
          alt={sighting.cats?.name ?? "Cat sighting"}
          fill
          className="object-cover"
          sizes="(max-width: 640px) 100vw, 640px"
        />
      </Link>

      {/* Notes */}
      {sighting.notes && (
        <p className="px-4 pt-3 text-sm text-stone-700">{sighting.notes}</p>
      )}

      {/* Reactions */}
      <div className="flex items-center gap-1 px-4 py-3">
        {REACTION_EMOJIS.map((emoji) => (
          <button
            key={emoji}
            onClick={() => toggleReaction(emoji)}
            className={`flex items-center gap-1 rounded-full px-2.5 py-1 text-sm transition-colors ${
              userReaction === emoji
                ? "bg-amber-100 text-amber-700"
                : "bg-stone-100 text-stone-600 hover:bg-stone-200"
            }`}
          >
            {emoji}
            {reactions[emoji] ? (
              <span className="text-xs font-medium">{reactions[emoji]}</span>
            ) : null}
          </button>
        ))}
        <Link
          href={`/sightings/${sighting.id}`}
          className="ml-auto text-xs text-stone-400 hover:text-stone-700"
        >
          Comments →
        </Link>
      </div>
    </article>
  );
}
