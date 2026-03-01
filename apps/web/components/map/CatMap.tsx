"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Map, { Marker, Popup, NavigationControl, GeolocateControl } from "react-map-gl";
import type { MapRef } from "react-map-gl";
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
}

export function CatMap({ sightings, userLat, userLng }: CatMapProps) {
  const mapRef = useRef<MapRef>(null);
  const [selected, setSelected] = useState<SightingWithRelations | null>(null);

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

  const handleMarkerClick = useCallback((sighting: SightingWithRelations) => {
    setSelected(sighting);
    const [lng, lat] = sighting.location.coordinates;
    mapRef.current?.flyTo({ center: [lng, lat], zoom: 15, duration: 500 });
  }, []);

  return (
    <div className="map-container relative">
      <Map
        ref={mapRef}
        initialViewState={initialView}
        mapStyle="mapbox://styles/mapbox/streets-v12"
        mapboxAccessToken={MAPBOX_TOKEN}
        style={{ width: "100%", height: "100%" }}
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
          return (
            <Marker
              key={s.id}
              longitude={lng}
              latitude={lat}
              anchor="bottom"
              onClick={() => handleMarkerClick(s)}
            >
              <SightingMarker photoUrl={s.photo_url} catName={s.cats?.name} />
            </Marker>
          );
        })}

        {selected && (
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

      {/* Snap button overlay */}
      <div className="absolute bottom-6 left-1/2 -translate-x-1/2">
        <Link
          href="/sightings/new"
          className="flex items-center gap-2 rounded-full bg-amber-500 px-6 py-3 text-sm font-semibold text-white shadow-lg hover:bg-amber-600 active:scale-95 transition-all"
        >
          📸 Snap a Cat
        </Link>
      </div>
    </div>
  );
}

// --- Sub-components ---

function SightingMarker({ photoUrl, catName }: { photoUrl: string; catName?: string | null }) {
  return (
    <div className="group flex flex-col items-center cursor-pointer">
      <div className="relative h-12 w-12 overflow-hidden rounded-full border-2 border-white shadow-md transition-transform group-hover:scale-110">
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
