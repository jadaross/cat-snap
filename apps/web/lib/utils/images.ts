/**
 * Compress an image file client-side before uploading.
 * Targets < 1 MB and max 1600px on the long edge.
 */
export async function compressImage(
  file: File,
  maxSizeMb = 1,
  maxWidthOrHeight = 1600
): Promise<File> {
  // Dynamic import so this only loads on client
  const imageCompression = (await import("browser-image-compression")).default;
  return imageCompression(file, {
    maxSizeMB: maxSizeMb,
    maxWidthOrHeight,
    useWebWorker: true,
    fileType: "image/jpeg",
  });
}

/**
 * Upload a file to Supabase Storage and return the public URL.
 */
export async function uploadCatPhoto(
  supabase: import("@supabase/supabase-js").SupabaseClient,
  file: File,
  userId: string
): Promise<string> {
  const compressed = await compressImage(file);
  const ext = "jpg";
  const path = `${userId}/${Date.now()}.${ext}`;

  const { error } = await supabase.storage
    .from("sighting-photos")
    .upload(path, compressed, { contentType: "image/jpeg", upsert: false });

  if (error) throw new Error(`Upload failed: ${error.message}`);

  const { data } = supabase.storage.from("sighting-photos").getPublicUrl(path);
  return data.publicUrl;
}

/**
 * Upload a user avatar and return the public URL.
 */
export async function uploadAvatar(
  supabase: import("@supabase/supabase-js").SupabaseClient,
  file: File,
  userId: string
): Promise<string> {
  const compressed = await compressImage(file, 0.3, 400);
  const path = `${userId}/avatar.jpg`;

  const { error } = await supabase.storage
    .from("avatars")
    .upload(path, compressed, { contentType: "image/jpeg", upsert: true });

  if (error) throw new Error(`Avatar upload failed: ${error.message}`);

  const { data } = supabase.storage.from("avatars").getPublicUrl(path);
  // Bust cache with timestamp
  return `${data.publicUrl}?t=${Date.now()}`;
}
