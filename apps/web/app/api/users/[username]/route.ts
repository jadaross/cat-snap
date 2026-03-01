import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

interface Params {
  params: Promise<{ username: string }>;
}

export async function GET(_request: NextRequest, { params }: Params) {
  const { username } = await params;
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("users")
    .select("id, username, display_name, avatar_url, bio, city, created_at")
    .eq("username", username)
    .single();

  if (error || !data) {
    return NextResponse.json({ error: "User not found" }, { status: 404 });
  }

  return NextResponse.json(data);
}

export async function PATCH(request: NextRequest, { params }: Params) {
  const { username } = await params;
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  // Verify ownership
  const { data: existing } = await supabase
    .from("users")
    .select("id")
    .eq("username", username)
    .single();

  if (!existing || existing.id !== user.id) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const body = await request.json();
  const db = supabase as any;
  const { data, error } = await db
    .from("users")
    .update({
      display_name: body.display_name,
      bio: body.bio,
      city: body.city,
      avatar_url: body.avatar_url,
    })
    .eq("id", user.id)
    .select()
    .single();

  if (error) return NextResponse.json({ error: "Update failed" }, { status: 500 });
  return NextResponse.json(data);
}
