/** Convert degrees to radians */
function toRad(deg: number) {
  return (deg * Math.PI) / 180;
}

/**
 * Haversine distance between two lat/lng points, in kilometers.
 */
export function distanceKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 6371; // Earth radius in km
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Format distance for display (e.g. "0.3 km" or "1.2 km").
 */
export function formatDistance(km: number): string {
  if (km < 1) return `${Math.round(km * 1000)} m`;
  return `${km.toFixed(1)} km`;
}

/**
 * Build a PostGIS-compatible GeoJSON point object from lng/lat.
 * Note: GeoJSON uses [longitude, latitude] order.
 */
export function makePoint(lng: number, lat: number) {
  return { type: "Point" as const, coordinates: [lng, lat] as [number, number] };
}
