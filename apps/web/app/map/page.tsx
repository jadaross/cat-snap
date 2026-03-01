"use client";

import { useState, useCallback } from "react";
import { CatMap } from "@/components/map/CatMap";
import { useSightings } from "@/lib/hooks/useSightings";
import { useLocation } from "@/lib/hooks/useLocation";

export default function MapPage() {
  const { lat, lng } = useLocation();
  const { sightings, loading } = useSightings({ lat: lat ?? undefined, lng: lng ?? undefined });

  const [pinLat, setPinLat] = useState<number | null>(null);
  const [pinLng, setPinLng] = useState<number | null>(null);

  const [groupMode, setGroupMode] = useState(false);
  const [selectedSightingIds, setSelectedSightingIds] = useState<Set<string>>(new Set());

  const handleMapClick = useCallback((clickLat: number, clickLng: number) => {
    setPinLat(clickLat);
    setPinLng(clickLng);
  }, []);

  const handleSightingSelect = useCallback((id: string) => {
    setSelectedSightingIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }, []);

  function handleClearPin() {
    setPinLat(null);
    setPinLng(null);
  }

  function toggleGroupMode() {
    if (groupMode) {
      setGroupMode(false);
      setSelectedSightingIds(new Set());
    } else {
      setPinLat(null);
      setPinLng(null);
      setGroupMode(true);
    }
  }

  async function handleMergeRequest(sightingIds: string[], note: string) {
    const res = await fetch("/api/merge-requests", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sighting_ids: sightingIds, note }),
    });
    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      throw new Error(data.error ?? "Failed to submit merge request");
    }
    // Reset after success (panel shows success state)
    setSelectedSightingIds(new Set());
    setGroupMode(false);
  }

  return (
    <div className="map-container relative">
      {/* Group mode toggle */}
      <div className="absolute top-20 right-4 z-10">
        <button
          onClick={toggleGroupMode}
          className={`rounded-xl px-3 py-2 text-xs font-semibold shadow-md transition-colors ${
            groupMode
              ? "bg-green-600 text-white hover:bg-green-700"
              : "bg-white text-stone-700 hover:bg-stone-100 border border-stone-200"
          }`}
        >
          {groupMode ? "Exit group mode" : "Group sightings"}
        </button>
      </div>

      <CatMap
        sightings={sightings}
        userLat={lat ?? undefined}
        userLng={lng ?? undefined}
        pinLat={pinLat}
        pinLng={pinLng}
        onMapClick={handleMapClick}
        onClearPin={handleClearPin}
        groupMode={groupMode}
        selectedSightingIds={selectedSightingIds}
        onSightingSelect={handleSightingSelect}
        onMergeRequest={handleMergeRequest}
      />
      {loading && (
        <div className="pointer-events-none absolute top-20 left-1/2 -translate-x-1/2 rounded-full bg-white px-4 py-2 text-sm text-stone-600 shadow-md">
          Loading nearby cats…
        </div>
      )}
    </div>
  );
}
