// delete-account
//
// Apple App Store Review Guideline 5.1.1(v) requires in-app account
// deletion. This edge function:
//   1. Authenticates the caller via their JWT
//   2. Deletes every storage object under sighting-photos/<uid>/ and avatars/<uid>/
//   3. Calls auth.admin.deleteUser, which cascades through profiles → sightings →
//      sighting_tags, follows, blocks, reports (cats.created_by goes SET NULL)
//
// Invocation from the iOS client uses supabase.functions.invoke("delete-account"),
// which passes the user's access token in Authorization automatically.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type DeletionResult = {
  user_id: string;
  storage_objects_deleted: number;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonError(500, "server_misconfigured");
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.toLowerCase().startsWith("bearer ")) {
    return jsonError(401, "missing_bearer_token");
  }
  const accessToken = authHeader.slice("Bearer ".length).trim();

  // Admin client — does the deletion + storage listing.
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userData, error: userError } = await admin.auth.getUser(
    accessToken,
  );
  if (userError || !userData?.user) {
    return jsonError(401, "invalid_token");
  }
  const userId = userData.user.id;

  let storageDeleted = 0;
  for (const bucket of ["sighting-photos", "avatars"] as const) {
    storageDeleted += await deleteBucketFolder(admin, bucket, userId);
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
  if (deleteError && !isAlreadyDeleted(deleteError)) {
    return jsonError(500, `auth_delete_failed: ${deleteError.message}`);
  }

  const result: DeletionResult = {
    user_id: userId,
    storage_objects_deleted: storageDeleted,
  };
  return new Response(JSON.stringify(result), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});

// Recursively list + delete every object under <bucket>/<userId>/.
// Storage list is paginated (default 100); upload paths are <uid>/<uuid>.jpg
// so one page suffices for small users, but loop until empty for safety.
async function deleteBucketFolder(
  admin: ReturnType<typeof createClient>,
  bucket: string,
  userId: string,
): Promise<number> {
  let total = 0;
  // Listing limit per Supabase Storage API
  const pageSize = 1000;

  while (true) {
    const { data, error } = await admin.storage
      .from(bucket)
      .list(userId, { limit: pageSize });
    if (error || !data || data.length === 0) break;

    const paths = data
      .filter((entry) => entry.name && !entry.name.endsWith("/"))
      .map((entry) => `${userId}/${entry.name}`);
    if (paths.length === 0) break;

    const { error: removeError } = await admin.storage
      .from(bucket)
      .remove(paths);
    if (removeError) break;

    total += paths.length;
    if (data.length < pageSize) break;
  }
  return total;
}

function isAlreadyDeleted(err: { message: string; status?: number }): boolean {
  return err.status === 404 || /not.?found/i.test(err.message ?? "");
}

function jsonError(status: number, code: string) {
  return new Response(JSON.stringify({ error: code }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
