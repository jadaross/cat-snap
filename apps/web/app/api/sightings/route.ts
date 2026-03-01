import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

/**
 * GET /api/sightings
 * Query params: lat, lng, radius (meters, default 5000), limit (default 50)
 *
 * Returns recent public sightings near the given coordinates.
 */
/** Decode a PostGIS EWKB hex string for a Point and return [lng, lat]. */
function ewkbToCoords(hex: string): [number, number] | null {
  try {
    const buf = Buffer.from(hex, "hex");
    const le = buf[0] === 1;
    const geomType = le ? buf.readUInt32LE(1) : buf.readUInt32BE(1);
    const hasSRID = (geomType & 0x20000000) !== 0;
    const offset = 5 + (hasSRID ? 4 : 0);
    const x = le ? buf.readDoubleLE(offset) : buf.readDoubleBE(offset);
    const y = le ? buf.readDoubleLE(offset + 8) : buf.readDoubleBE(offset + 8);
    return [x, y];
  } catch {
    return null;
  }
}

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const lat = parseFloat(searchParams.get("lat") ?? "");
  const lng = parseFloat(searchParams.get("lng") ?? "");
  const radius = parseInt(searchParams.get("radius") ?? "5000", 10);
  const limit = Math.min(parseInt(searchParams.get("limit") ?? "50", 10), 100);

  const supabase = await createClient();

  // If coordinates are provided, use the PostGIS proximity RPC
  if (!isNaN(lat) && !isNaN(lng)) {
    const { data, error } = await supabase.rpc("sightings_near", {
      p_lat: lat,
      p_lng: lng,
      p_radius: radius,
      p_limit: limit,
    });

    if (error) {
      console.error("sightings_near error:", error);
      return NextResponse.json({ error: "Failed to fetch sightings" }, { status: 500 });
    }

    // Normalize flat RPC columns into the SightingWithRelations shape
    const normalized = (data as any[]).map((row) => ({
      id: row.id,
      cat_id: row.cat_id,
      user_id: row.user_id,
      photo_url: row.photo_url,
      location: { type: "Point", coordinates: [row.lng, row.lat] },
      location_label: row.location_label,
      notes: row.notes,
      visibility: row.visibility,
      seen_at: row.seen_at,
      created_at: row.seen_at,
      cats: { id: row.cat_id, name: row.cat_name, primary_photo_url: row.cat_photo_url },
      users: row.username
        ? { id: row.user_id, username: row.username, display_name: row.display_name, avatar_url: row.avatar_url }
        : null,
      distance_m: row.distance_m,
    }));

    return NextResponse.json(normalized);
  }

  // No coordinates — return recent public sightings
  const { data, error } = await supabase
    .from("sightings")
    .select("*, cats(id, name, primary_photo_url), users(id, username, display_name, avatar_url)")
    .eq("visibility", "public")
    .order("seen_at", { ascending: false })
    .limit(limit);

  if (error) {
    console.error("sightings fetch error:", error);
    return NextResponse.json({ error: "Failed to fetch sightings" }, { status: 500 });
  }

  // Supabase returns PostGIS geography as EWKB hex — decode to GeoJSON
  const normalized = (data ?? []).map((row: any) => {
    if (typeof row.location === "string") {
      const coords = ewkbToCoords(row.location);
      return { ...row, location: coords ? { type: "Point", coordinates: coords } : null };
    }
    return row;
  }).filter((row: any) => row.location?.coordinates);

  return NextResponse.json(normalized);
}

/**
 * POST /api/sightings
 * Body: { cat_id, photo_url, lat, lng, location_label?, notes?, seen_at?, visibility? }
 *
 * Creates a new sighting. Requires auth.
 */
export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const { cat_id, photo_url, lat, lng, location_label, notes, seen_at, visibility } = body;

  if (!cat_id || !photo_url || lat == null || lng == null) {
    return NextResponse.json(
      { error: "cat_id, photo_url, lat, and lng are required" },
      { status: 400 }
    );
  }

  const { data, error } = await supabase
    .from("sightings")
    .insert({
      cat_id,
      user_id: user.id,
      photo_url,
      // PostGIS accepts WKT or GeoJSON via the Supabase JS client
      location: `POINT(${lng} ${lat})`,
      location_label: location_label ?? null,
      notes: notes ?? null,
      seen_at: seen_at ?? new Date().toISOString(),
      visibility: visibility ?? "public",
    })
    .select()
    .single();

  if (error) {
    console.error("insert sighting error:", error);
    return NextResponse.json({ error: "Failed to create sighting" }, { status: 500 });
  }

  return NextResponse.json(data, { status: 201 });
}
