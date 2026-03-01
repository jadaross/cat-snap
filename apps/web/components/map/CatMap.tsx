"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Map, { Marker, Popup, NavigationControl, GeolocateControl } from "react-map-gl";
import type { MapRef, MapMouseEvent } from "react-map-gl";
import "mapbox-gl/dist/mapbox-gl.css";
import Image from "next/image";
import Link from "next/link";
import type { SightingWithRelations } from "@/lib/hooks/useSightings";
import { formatDistance } from "@/lib/utils/geo";

const MAPBOX_TOKEN = process.env.NEXT_PUBLIC_MAPBOX_TOKEN!;

const DEFAULT_VIEW = {
  longitude: -74.006,
  latitude: 40.7128,
  zoom: 13,
};

interface CatMapProps {
  sightings: SightingWithRelations[];
  userLat?: number;
  userLng?: number;
  pinLat?: number | null;
  pinLng?: number | null;
  onMapClick?: (lat: number, lng: number) => void;
  groupMode?: boolean;
  selectedSightingIds?: Set<string>;
  onSightingSelect?: (id: string) => void;
  onMergeRequest?: (sightingIds: string[], note: string) => Promise<void>;
  onClearPin?: () => void;
}

export function CatMap({
  sightings,
  userLat,
  userLng,
  pinLat,
  pinLng,
  onMapClick,
  groupMode = false,
  selectedSightingIds = new Set(),
  onSightingSelect,
  onMergeRequest,
  onClearPin,
}: CatMapProps) {
  const mapRef = useRef<MapRef>(null);
  const [selected, setSelected] = useState<SightingWithRelations | null>(null);
  const [mergeNote, setMergeNote] = useState("");
  const [merging, setMerging] = useState(false);
  const [mergeSuccess, setMergeSuccess] = useState(false);

  const initialView = userLat && userLng
    ? { longitude: userLng, latitude: userLat, zoom: 14 }
    : DEFAULT_VIEW;

  // Fly to user's location the first time it resolves
  const hasFlewToUser = useRef(false);
  useEffect(() => {
    if (userLat != null && userLng != null && !hasFlewToUser.current) {
      hasFlewToUser.current = true;
      mapRef.current?.flyTo({ center: [userLng, userLat], zoom: 14, duration: 1200 });
    }
  }, [userLat, userLng]);

  // Close popup when entering group mode
  useEffect(() => {
    if (groupMode) setSelected(null);
  }, [groupMode]);

  const handleMapClick = useCallback((e: MapMouseEvent) => {
    if (!groupMode && onMapClick) {
      onMapClick(e.lngLat.lat, e.lngLat.lng);
    }
  }, [groupMode, onMapClick]);

  const handleMarkerClick = useCallback((e: { originalEvent: MouseEvent }, sighting: SightingWithRelations) => {
    e.originalEvent.stopPropagation();
    if (groupMode) {
      onSightingSelect?.(sighting.id);
    } else {
      setSelected(sighting);
      const [lng, lat] = sighting.location.coordinates;
      mapRef.current?.flyTo({ center: [lng, lat], zoom: 15, duration: 500 });
    }
  }, [groupMode, onSightingSelect]);

  async function handleMergeSubmit() {
    if (!onMergeRequest) return;
    setMerging(true);
    try {
      await onMergeRequest(Array.from(selectedSightingIds), mergeNote);
      setMergeSuccess(true);
      setMergeNote("");
    } finally {
      setMerging(false);
    }
  }

  const selectedSightings = sightings.filter((s) => selectedSightingIds.has(s.id));

  const hasPinLocation = pinLat != null && pinLng != null;

  return (
    <div className="map-container relative">
      <Map
        ref={mapRef}
        initialViewState={initialView}
        mapStyle="mapbox://styles/mapbox/streets-v12"
        mapboxAccessToken={MAPBOX_TOKEN}
        style={{ width: "100%", height: "100%" }}
        onClick={!groupMode ? handleMapClick : undefined}
      >
        <NavigationControl position="top-right" />
        <GeolocateControl
          position="top-right"
          trackUserLocation
          showUserHeading
          onGeolocate={(e) => {
            mapRef.current?.flyTo({
              center: [e.coords.longitude, e.coords.latitude],
              zoom: 14,
              duration: 800,
            });
          }}
        />

        {sightings.filter((s) => s.location?.coordinates).map((s) => {
          const [lng, lat] = s.location.coordinates;
          const isChosen = selectedSightingIds.has(s.id);
          return (
            <Marker
              key={s.id}
              longitude={lng}
              latitude={lat}
              anchor="bottom"
              onClick={(e) => handleMarkerClick(e, s)}
            >
              <SightingMarker
                photoUrl={s.photo_url}
                catName={s.cats?.name}
                selected={isChosen}
              />
            </Marker>
          );
        })}

        {/* Drop-pin marker */}
        {hasPinLocation && (
          <Marker longitude={pinLng!} latitude={pinLat!} anchor="bottom">
            <div className="flex flex-col items-center">
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-amber-500 text-white text-xl shadow-lg border-2 border-white">
                +
              </div>
              <div className="h-2 w-0.5 bg-amber-500" />
              <div className="h-1.5 w-1.5 rounded-full bg-amber-500" />
            </div>
          </Marker>
        )}

        {selected && !groupMode && (
          <Popup
            longitude={selected.location.coordinates[0]}
            latitude={selected.location.coordinates[1]}
            anchor="top"
            onClose={() => setSelected(null)}
            closeButton={false}
            className="cat-popup"
            maxWidth="240px"
          >
            <PopupCard sighting={selected} userLat={userLat} userLng={userLng} onClose={() => setSelected(null)} />
          </Popup>
        )}
      </Map>

      {/* Bottom overlay */}
      <div className="absolute bottom-6 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2">
        {hasPinLocation ? (
          <div className="flex items-center gap-2">
            <Link
              href={`/sightings/new?lat=${pinLat}&lng=${pinLng}`}
              className="flex items-center gap-2 rounded-full bg-amber-500 px-6 py-3 text-sm font-semibold text-white shadow-lg hover:bg-amber-600 active:scale-95 transition-all"
            >
              📍 Snap here
            </Link>
            <button
              onClick={onClearPin}
              className="flex h-11 w-11 items-center justify-center rounded-full bg-white text-stone-600 shadow-lg hover:bg-stone-100 active:scale-95 transition-all text-lg font-bold"
              aria-label="Clear pin"
            >
              ×
            </button>
          </div>
        ) : (
          !groupMode && (
            <Link
              href="/sightings/new"
              className="flex items-center gap-2 rounded-full bg-amber-500 px-6 py-3 text-sm font-semibold text-white shadow-lg hover:bg-amber-600 active:scale-95 transition-all"
            >
              📸 Snap a Cat
            </Link>
          )
        )}
      </div>

      {/* Group mode merge panel */}
      {groupMode && selectedSightings.length > 0 && (
        <div className="absolute bottom-0 inset-x-0 rounded-t-2xl bg-white shadow-2xl border-t border-stone-200 p-4 space-y-3 max-h-72 overflow-y-auto">
          {mergeSuccess ? (
            <div className="py-6 text-center space-y-2">
              <p className="text-2xl">✅</p>
              <p className="font-semibold text-stone-900">Merge request submitted!</p>
              <p className="text-sm text-stone-500">An admin will review and confirm whether these are the same cat.</p>
            </div>
          ) : (
            <>
              <p className="text-sm font-semibold text-stone-700">
                {selectedSightings.length} sighting{selectedSightings.length !== 1 ? "s" : ""} selected — same cat?
              </p>
              <div className="flex gap-2 overflow-x-auto pb-1">
                {selectedSightings.map((s) => (
                  <div key={s.id} className="shrink-0 text-center">
                    <div className="relative h-14 w-14 overflow-hidden rounded-xl border border-stone-200 bg-stone-100">
                      <Image src={s.photo_url} alt="Sighting" fill className="object-cover" sizes="56px" />
                    </div>
                    <p className="mt-0.5 text-xs text-stone-500 truncate w-14">{s.cats?.name ?? "?"}</p>
                  </div>
                ))}
              </div>
              <input
                type="text"
                placeholder="Add a note (optional)"
                value={mergeNote}
                onChange={(e) => setMergeNote(e.target.value)}
                className="w-full rounded-xl border border-stone-200 px-3 py-2 text-sm focus:border-amber-400 focus:outline-none"
              />
              <button
                onClick={handleMergeSubmit}
                disabled={merging || selectedSightings.length < 2}
                className="w-full rounded-xl bg-amber-500 py-2.5 text-sm font-semibold text-white hover:bg-amber-600 transition-colors disabled:opacity-50"
              >
                {merging ? "Submitting…" : "Submit grouping request"}
              </button>
            </>
          )}
        </div>
      )}
    </div>
  );
}

// --- Sub-components ---

function SightingMarker({
  photoUrl,
  catName,
  selected,
}: {
  photoUrl: string;
  catName?: string | null;
  selected?: boolean;
}) {
  return (
    <div className="group flex flex-col items-center cursor-pointer">
      <div
        className={`relative h-12 w-12 overflow-hidden rounded-full border-2 shadow-md transition-transform group-hover:scale-110 ${
          selected ? "border-green-400 ring-2 ring-green-400 ring-offset-1" : "border-white"
        }`}
      >
        <Image src={photoUrl} alt={catName ?? "Cat"} fill className="object-cover" sizes="48px" />
      </div>
      {/* Pin tail */}
      <div className="h-2 w-0.5 bg-white shadow" />
      <div className="h-1.5 w-1.5 rounded-full bg-white shadow" />
    </div>
  );
}

function PopupCard({
  sighting,
  userLat,
  userLng,
  onClose,
}: {
  sighting: SightingWithRelations;
  userLat?: number;
  userLng?: number;
  onClose: () => void;
}) {
  const [lng, lat] = sighting.location.coordinates;
  const dist = userLat != null && userLng != null
    ? formatDistance(
        Math.sqrt((lat - userLat) ** 2 + (lng - userLng) ** 2) * 111
      )
    : null;

  const timeAgo = getTimeAgo(sighting.seen_at);

  return (
    <div className="w-56 overflow-hidden rounded-2xl bg-white shadow-xl">
      <button
        onClick={onClose}
        className="absolute right-2 top-2 z-10 rounded-full bg-white/80 p-1 text-stone-500 hover:text-stone-900"
        aria-label="Close"
      >
        ×
      </button>
      <div className="relative h-32 w-full bg-stone-100">
        <Image src={sighting.photo_url} alt="Cat sighting" fill className="object-cover" sizes="224px" />
      </div>
      <div className="p-3">
        <p className="font-semibold text-stone-900">{sighting.cats?.name ?? "Unknown cat"}</p>
        <p className="text-xs text-stone-500 mt-0.5">
          {timeAgo}{dist ? ` · ${dist} away` : ""}
        </p>
        {sighting.notes && (
          <p className="mt-1.5 text-xs text-stone-600 line-clamp-2">{sighting.notes}</p>
        )}
        <Link
          href={`/cats/${sighting.cat_id}`}
          className="mt-3 block w-full rounded-lg bg-amber-500 py-1.5 text-center text-xs font-semibold text-white hover:bg-amber-600"
        >
          View cat profile →
        </Link>
      </div>
    </div>
  );
}

function getTimeAgo(isoDate: string): string {
  const diff = Date.now() - new Date(isoDate).getTime();
  const minutes = Math.floor(diff / 60_000);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}
