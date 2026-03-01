"use client";

import { CatMap } from "@/components/map/CatMap";
import { useSightings } from "@/lib/hooks/useSightings";
import { useLocation } from "@/lib/hooks/useLocation";

export default function MapPage() {
  const { lat, lng } = useLocation();
  const { sightings, loading } = useSightings({ lat: lat ?? undefined, lng: lng ?? undefined });

  return (
    <div className="map-container">
      <CatMap
        sightings={sightings}
        userLat={lat ?? undefined}
        userLng={lng ?? undefined}
      />
      {loading && (
        <div className="pointer-events-none absolute top-20 left-1/2 -translate-x-1/2 rounded-full bg-white px-4 py-2 text-sm text-stone-600 shadow-md">
          Loading nearby cats…
        </div>
      )}
    </div>
  );
}
