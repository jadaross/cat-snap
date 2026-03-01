import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { SightingForm } from "@/components/sightings/SightingForm";

type Props = { searchParams: Promise<{ lat?: string; lng?: string; cat?: string }> };

export default async function NewSightingPage({ searchParams }: Props) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login?next=/sightings/new");
  }

  const sp = await searchParams;
  const initialLat = sp.lat ? parseFloat(sp.lat) : undefined;
  const initialLng = sp.lng ? parseFloat(sp.lng) : undefined;

  return (
    <main className="mx-auto max-w-lg px-4 py-8">
      <h1 className="text-2xl font-bold text-stone-900 mb-1">Log a Sighting</h1>
      <p className="text-sm text-stone-500 mb-6">
        Spotted a cat? Add a photo, name them, and share the moment.
      </p>
      <SightingForm initialLat={initialLat} initialLng={initialLng} />
    </main>
  );
}
