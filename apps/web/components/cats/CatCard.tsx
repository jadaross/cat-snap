import Image from "next/image";
import Link from "next/link";
import type { CatRow } from "@/lib/supabase/types";

interface CatCardProps {
  cat: Pick<CatRow, "id" | "name" | "description" | "primary_photo_url">;
  lastSeen?: string; // ISO timestamp
}

export function CatCard({ cat, lastSeen }: CatCardProps) {
  return (
    <Link
      href={`/cats/${cat.id}`}
      className="group flex flex-col overflow-hidden rounded-2xl border border-stone-200 bg-white card-lift"
    >
      <div className="relative aspect-square overflow-hidden bg-stone-100">
        {cat.primary_photo_url ? (
          <Image
            src={cat.primary_photo_url}
            alt={cat.name ?? "A cat"}
            fill
            className="object-cover transition-transform duration-300 group-hover:scale-105"
            sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
          />
        ) : (
          <div className="flex h-full items-center justify-center text-4xl text-stone-300">
            🐱
          </div>
        )}
      </div>
      <div className="p-3">
        <p className="font-semibold text-stone-900 truncate">
          {cat.name ?? "Unknown cat"}
        </p>
        {cat.description && (
          <p className="mt-0.5 text-sm text-stone-500 line-clamp-2">
            {cat.description}
          </p>
        )}
        {lastSeen && (
          <p className="mt-1 text-xs text-stone-400">
            Last seen {new Date(lastSeen).toLocaleDateString()}
          </p>
        )}
      </div>
    </Link>
  );
}
