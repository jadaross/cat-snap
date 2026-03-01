import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

interface Params {
  params: Promise<{ id: string }>;
}

async function getAdminUser() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { supabase, user: null, isAdmin: false };

  const { data: profile } = await supabase
    .from("users")
    .select("is_admin")
    .eq("id", user.id)
    .single();

  return { supabase, user, isAdmin: profile?.is_admin === true };
}

// POST /api/admin/merge-requests/[id] — approve (body: { target_cat_id })
export async function POST(request: NextRequest, { params }: Params) {
  const { id } = await params;
  const { supabase, user, isAdmin } = await getAdminUser();

  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  if (!isAdmin) return NextResponse.json({ error: "Forbidden" }, { status: 403 });

  const { target_cat_id } = await request.json() as { target_cat_id: string };
  if (!target_cat_id) {
    return NextResponse.json({ error: "target_cat_id is required" }, { status: 400 });
  }

  // Fetch merge request
  const { data: mr } = await supabase
    .from("merge_requests")
    .select("sighting_ids")
    .eq("id", id)
    .single();

  if (!mr) return NextResponse.json({ error: "Not found" }, { status: 404 });

  // Fetch current cat IDs for sightings (to find losers)
  const { data: sightingRows } = await supabase
    .from("sightings")
    .select("id, cat_id")
    .in("id", mr.sighting_ids);

  const loserCatIds = Array.from(
    new Set((sightingRows ?? []).map((s) => s.cat_id).filter((cid) => cid !== target_cat_id))
  );

  // Re-assign sightings to target cat
  const { error: updateErr } = await supabase
    .from("sightings")
    .update({ cat_id: target_cat_id })
    .in("id", mr.sighting_ids);

  if (updateErr) return NextResponse.json({ error: "Failed to update sightings" }, { status: 500 });

  // Delete orphaned loser cats (those with no remaining sightings)
  for (const loserId of loserCatIds) {
    const { count } = await supabase
      .from("sightings")
      .select("id", { count: "exact", head: true })
      .eq("cat_id", loserId);

    if ((count ?? 0) === 0) {
      await supabase.from("cats").delete().eq("id", loserId);
    }
  }

  // Mark merge request approved
  await supabase
    .from("merge_requests")
    .update({ status: "approved", reviewed_by: user.id, target_cat_id })
    .eq("id", id);

  return NextResponse.json({ success: true });
}

// PATCH /api/admin/merge-requests/[id] — reject
export async function PATCH(_request: NextRequest, { params }: Params) {
  const { id } = await params;
  const { supabase, user, isAdmin } = await getAdminUser();

  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  if (!isAdmin) return NextResponse.json({ error: "Forbidden" }, { status: 403 });

  const { error } = await supabase
    .from("merge_requests")
    .update({ status: "rejected", reviewed_by: user.id })
    .eq("id", id);

  if (error) return NextResponse.json({ error: "Failed to reject" }, { status: 500 });

  return NextResponse.json({ success: true });
}
