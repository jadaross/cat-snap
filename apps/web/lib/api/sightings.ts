import type { SightingRow } from "@/lib/supabase/types";

export interface CreateSightingPayload {
  cat_id: string;
  photo_url: string;
  lat: number;
  lng: number;
  location_label?: string;
  notes?: string;
  seen_at?: string;
  visibility?: "public" | "friends" | "private";
}

export async function createSighting(payload: CreateSightingPayload): Promise<SightingRow> {
  const res = await fetch("/api/sightings", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error ?? "Failed to create sighting");
  }
  return res.json();
}

export async function fetchSighting(id: string): Promise<SightingRow> {
  const res = await fetch(`/api/sightings/${id}`);
  if (!res.ok) throw new Error("Sighting not found");
  return res.json();
}
