import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { SightingForm } from "@/components/sightings/SightingForm";

export default async function NewSightingPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login?next=/sightings/new");
  }

  return (
    <main className="mx-auto max-w-lg px-4 py-8">
      <h1 className="text-2xl font-bold text-stone-900 mb-1">Log a Sighting</h1>
      <p className="text-sm text-stone-500 mb-6">
        Spotted a cat? Add a photo, name them, and share the moment.
      </p>
      <SightingForm />
    </main>
  );
}
