import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

/**
 * GET /api/cats
 * Query params: q (search by name), limit (default 20)
 */
export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const q = searchParams.get("q") ?? "";
  const limit = Math.min(parseInt(searchParams.get("limit") ?? "20", 10), 100);

  const supabase = await createClient();

  let query = supabase
    .from("cats")
    .select("id, name, description, primary_photo_url, created_at")
    .order("created_at", { ascending: false })
    .limit(limit);

  if (q) {
    query = query.ilike("name", `%${q}%`);
  }

  const { data, error } = await query;

  if (error) {
    return NextResponse.json({ error: "Failed to fetch cats" }, { status: 500 });
  }

  return NextResponse.json(data);
}

/**
 * POST /api/cats
 * Body: { name, description?, primary_photo_url? }
 *
 * Creates a new cat profile. Requires auth.
 */
export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const { name, description, primary_photo_url } = body;

  const { data, error } = await supabase
    .from("cats")
    .insert({
      created_by: user.id,
      name: name ?? null,
      description: description ?? null,
      primary_photo_url: primary_photo_url ?? null,
    })
    .select()
    .single();

  if (error) {
    return NextResponse.json({ error: "Failed to create cat" }, { status: 500 });
  }

  return NextResponse.json(data, { status: 201 });
}
