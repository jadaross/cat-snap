import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import Image from "next/image";
import Link from "next/link";
import { Avatar } from "@/components/ui/Avatar";

export default async function ProfilePage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) redirect("/login?next=/profile");

  const { data: profile } = await supabase
    .from("users")
    .select("*")
    .eq("id", user.id)
    .single();

  const { data: sightings } = await supabase
    .from("sightings")
    .select("id, photo_url, seen_at, cat_id, cats(name)")
    .eq("user_id", user.id)
    .order("seen_at", { ascending: false })
    .limit(24);

  const displayName = profile?.display_name ?? profile?.username ?? user.email;

  return (
    <main className="mx-auto max-w-2xl px-4 py-8 space-y-8">
      {/* Profile header */}
      <div className="flex items-center gap-5">
        <Avatar
          src={profile?.avatar_url ?? user.user_metadata?.avatar_url}
          name={displayName}
          size="xl"
        />
        <div>
          <h1 className="text-2xl font-bold text-stone-900">{displayName}</h1>
          {profile?.username && (
            <p className="text-stone-500 text-sm">@{profile.username}</p>
          )}
          {profile?.bio && (
            <p className="mt-2 text-sm text-stone-600 max-w-xs">{profile.bio}</p>
          )}
          {profile?.city && (
            <p className="text-xs text-stone-400 mt-1">📍 {profile.city}</p>
          )}
        </div>
      </div>

      {/* Stats */}
      <div className="flex gap-6 text-sm">
        <div className="text-center">
          <p className="text-xl font-bold text-stone-900">{sightings?.length ?? 0}</p>
          <p className="text-stone-500">Sightings</p>
        </div>
      </div>

      {/* My sightings grid */}
      <section>
        <h2 className="text-lg font-bold text-stone-900 mb-4">My Sightings</h2>
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
                  className="object-cover transition-transform duration-300 group-hover:scale-105"
                  sizes="(max-width: 640px) 33vw, 200px"
                />
              </Link>
            ))}
          </div>
        ) : (
          <div className="flex flex-col items-center gap-3 py-16 text-stone-400 text-center">
            <span className="text-4xl">📷</span>
            <p>You haven't logged any sightings yet.</p>
            <Link
              href="/sightings/new"
              className="rounded-xl bg-amber-500 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-600"
            >
              Snap your first cat
            </Link>
          </div>
        )}
      </section>
    </main>
  );
}
