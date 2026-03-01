import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

interface Params {
  params: Promise<{ id: string }>;
}

export async function GET(_request: NextRequest, { params }: Params) {
  const { id } = await params;
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("sightings")
    .select("*, cats(id, name, primary_photo_url), users(username, display_name, avatar_url)")
    .eq("id", id)
    .single();

  if (error || !data) {
    return NextResponse.json({ error: "Sighting not found" }, { status: 404 });
  }

  return NextResponse.json(data);
}

export async function PATCH(request: NextRequest, { params }: Params) {
  const { id } = await params;
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const body = await request.json();

  // Only owner can patch
  const { data: existing } = await supabase
    .from("sightings")
    .select("user_id")
    .eq("id", id)
    .single();

  if (!existing || existing.user_id !== user.id) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const db = supabase as any;
  const { data, error } = await db
    .from("sightings")
    .update({ notes: body.notes, visibility: body.visibility })
    .eq("id", id)
    .select()
    .single();

  if (error) return NextResponse.json({ error: "Update failed" }, { status: 500 });
  return NextResponse.json(data);
}

export async function DELETE(_request: NextRequest, { params }: Params) {
  const { id } = await params;
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { data: existing } = await supabase
    .from("sightings")
    .select("user_id")
    .eq("id", id)
    .single();

  if (!existing || existing.user_id !== user.id) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  await supabase.from("sightings").delete().eq("id", id);
  return new NextResponse(null, { status: 204 });
}

// POST /api/sightings/[id]/comments handled via this route for simplicity
export async function POST(request: NextRequest, { params }: Params) {
  const { id } = await params;
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const body = await request.json();
  if (!body.body?.trim()) {
    return NextResponse.json({ error: "Comment body required" }, { status: 400 });
  }

  const { data, error } = await supabase
    .from("comments")
    .insert({ sighting_id: id, user_id: user.id, body: body.body.trim() })
    .select()
    .single();

  if (error) return NextResponse.json({ error: "Failed to post comment" }, { status: 500 });
  return NextResponse.json(data, { status: 201 });
}
