"use client";

import { useEffect, useRef, useState } from "react";
import type { SightingRow, CatRow, UserRow } from "@/lib/supabase/types";

export type SightingWithRelations = SightingRow & {
  cats: Pick<CatRow, "id" | "name" | "primary_photo_url">;
  users: Pick<UserRow, "id" | "username" | "display_name" | "avatar_url"> | null;
};

interface UseSightingsOptions {
  lat?: number;
  lng?: number;
  radius?: number;
  limit?: number;
}

interface SightingsState {
  sightings: SightingWithRelations[];
  loading: boolean;
  error: string | null;
  refresh: () => void;
}

export function useSightings({
  lat,
  lng,
  radius = 5000,
  limit = 50,
}: UseSightingsOptions = {}): SightingsState {
  const [sightings, setSightings] = useState<SightingWithRelations[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [tick, setTick] = useState(0);
  const hasGeoData = useRef(false);

  useEffect(() => {
    const hasCoords = lat != null && lng != null;

    // Once we have location-aware data, ignore subsequent fallback fetches
    if (!hasCoords && hasGeoData.current) return;

    setLoading(true);
    const params = new URLSearchParams({ limit: String(limit) });
    if (hasCoords) {
      params.set("lat", String(lat));
      params.set("lng", String(lng));
      params.set("radius", String(radius));
    }

    fetch(`/api/sightings?${params}`)
      .then((r) => r.json())
      .then((data) => {
        if (hasCoords) hasGeoData.current = true;
        setSightings(Array.isArray(data) ? data : []);
        setError(null);
      })
      .catch(() => setError("Failed to load sightings"))
      .finally(() => setLoading(false));
  }, [lat, lng, radius, limit, tick]);

  return { sightings, loading, error, refresh: () => setTick((t) => t + 1) };
}
