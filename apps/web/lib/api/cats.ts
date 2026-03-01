import type { CatRow } from "@/lib/supabase/types";

export type CatSummary = Pick<CatRow, "id" | "name" | "description" | "primary_photo_url" | "created_at">;

export async function fetchCats(query?: string): Promise<CatSummary[]> {
  const params = new URLSearchParams();
  if (query) params.set("q", query);
  const res = await fetch(`/api/cats?${params}`);
  if (!res.ok) throw new Error("Failed to fetch cats");
  return res.json();
}

export async function fetchCat(id: string): Promise<CatRow> {
  const res = await fetch(`/api/cats/${id}`);
  if (!res.ok) throw new Error("Cat not found");
  return res.json();
}

export async function createCat(data: {
  name?: string;
  description?: string;
  primary_photo_url?: string;
}): Promise<CatRow> {
  const res = await fetch("/api/cats", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error("Failed to create cat");
  return res.json();
}
