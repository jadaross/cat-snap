import { notFound } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { Avatar } from "@/components/ui/Avatar";

interface Props {
  params: Promise<{ username: string }>;
}

export async function generateMetadata({ params }: Props) {
  const { username } = await params;
  return { title: `@${username} — Cat Snap` };
}

export default async function PublicProfilePage({ params }: Props) {
  const { username } = await params;
  const supabase = await createClient();

  const { data: profile } = await supabase
    .from("users")
    .select("*")
    .eq("username", username)
    .single();

  if (!profile) notFound();

  const { data: sightings } = await supabase
    .from("sightings")
    .select("id, photo_url, seen_at, cat_id")
    .eq("user_id", profile.id)
    .eq("visibility", "public")
    .order("seen_at", { ascending: false })
    .limit(24);

  return (
    <main className="mx-auto max-w-2xl px-4 py-8 space-y-8">
      <div className="flex items-center gap-5">
        <Avatar src={profile.avatar_url} name={profile.display_name ?? profile.username} size="xl" />
        <div>
          <h1 className="text-2xl font-bold text-stone-900">
            {profile.display_name ?? profile.username}
          </h1>
          <p className="text-stone-500 text-sm">@{profile.username}</p>
          {profile.bio && (
            <p className="mt-2 text-sm text-stone-600 max-w-xs">{profile.bio}</p>
          )}
          {profile.city && (
            <p className="text-xs text-stone-400 mt-1">📍 {profile.city}</p>
          )}
        </div>
      </div>

      <div className="text-sm text-stone-500">
        <strong className="text-stone-900">{sightings?.length ?? 0}</strong> public sightings
      </div>

      {sightings && sightings.length > 0 ? (
        <div className="grid grid-cols-3 gap-2">
          {sightings.map((s) => (
            <Link
              key={s.id}
              href={`/sightings/${s.id}`}
              className="group relative aspect-square overflow-hidden rounded-xl bg-stone-100"
            >
              <Image
                src={s.photo_url}
                alt="Cat sighting"
                fill
                className="object-cover group-hover:scale-105 transition-transform duration-300"
                sizes="(max-width: 640px) 33vw, 200px"
              />
            </Link>
          ))}
        </div>
      ) : (
        <p className="text-stone-400 text-center py-16">No public sightings yet.</p>
      )}
    </main>
  );
}
