import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { CatProfile } from "@/components/cats/CatProfile";

interface Props {
  params: Promise<{ id: string }>;
}

export async function generateMetadata({ params }: Props) {
  const { id } = await params;
  const supabase = await createClient();
  const { data: cat } = await supabase.from("cats").select("name, description").eq("id", id).single();
  return {
    title: cat?.name ? `${cat.name} — Cat Snap` : "Cat Profile — Cat Snap",
    description: cat?.description ?? "View this cat's sighting history on Cat Snap.",
  };
}

export default async function CatPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createClient();

  const [{ data: cat }, { data: sightings }, { data: follows }, { data: authData }] =
    await Promise.all([
      supabase.from("cats").select("*").eq("id", id).single(),
      supabase
        .from("sightings")
        .select("*, users(username, display_name, avatar_url)")
        .eq("cat_id", id)
        .eq("visibility", "public")
        .order("seen_at", { ascending: false }),
      supabase.from("cat_follows").select("user_id", { count: "exact" }).eq("cat_id", id),
      supabase.auth.getUser(),
    ]);

  if (!cat) notFound();

  return (
    <CatProfile
      cat={cat}
      sightings={(sightings ?? []) as Parameters<typeof CatProfile>[0]["sightings"]}
      followerCount={follows?.length ?? 0}
      currentUserId={authData?.user?.id}
    />
  );
}
