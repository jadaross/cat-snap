import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const body = await request.json();
  const { sighting_ids, note } = body as { sighting_ids: string[]; note?: string };

  if (!Array.isArray(sighting_ids) || sighting_ids.length < 2) {
    return NextResponse.json(
      { error: "At least 2 sighting IDs are required" },
      { status: 400 }
    );
  }

  const { data, error } = await supabase
    .from("merge_requests")
    .insert({
      submitted_by: user.id,
      sighting_ids,
      note: note ?? null,
      status: "pending",
    })
    .select()
    .single();

  if (error) return NextResponse.json({ error: "Failed to create merge request" }, { status: 500 });

  return NextResponse.json(data, { status: 201 });
}
