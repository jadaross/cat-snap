"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { uploadCatPhoto } from "@/lib/utils/images";
import { createSighting } from "@/lib/api/sightings";
import { createCat, fetchCats } from "@/lib/api/cats";
import { useLocation } from "@/lib/hooks/useLocation";
import { PhotoUpload } from "./PhotoUpload";
import { Button } from "@/components/ui/Button";
import { Input, Textarea } from "@/components/ui/Input";
import { TagInput } from "@/components/ui/Tag";

const CAT_TAG_SUGGESTIONS = [
  "friendly", "shy", "fluffy", "tabby", "orange", "black", "white",
  "calico", "kitten", "senior", "well-fed", "tnr'd",
];

type Step = "photo" | "cat" | "details" | "submitting";

export function SightingForm() {
  const router = useRouter();
  const { lat, lng } = useLocation();

  // Step state
  const [step, setStep] = useState<Step>("photo");

  // Photo
  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);

  // Cat
  const [catMode, setCatMode] = useState<"new" | "existing">("new");
  const [catName, setCatName] = useState("");
  const [catSearch, setCatSearch] = useState("");
  const [catResults, setCatResults] = useState<{ id: string; name: string | null }[]>([]);
  const [selectedCatId, setSelectedCatId] = useState<string | null>(null);
  const [tags, setTags] = useState<string[]>([]);

  // Details
  const [notes, setNotes] = useState("");
  const [locationLabel, setLocationLabel] = useState("");
  const [visibility, setVisibility] = useState<"public" | "friends" | "private">("public");

  // Error
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitError, setSubmitError] = useState("");

  function handlePhotoFile(file: File) {
    setPhotoFile(file);
    setPhotoPreview(URL.createObjectURL(file));
  }

  async function handleCatSearch(q: string) {
    setCatSearch(q);
    if (q.length < 2) { setCatResults([]); return; }
    const results = await fetchCats(q);
    setCatResults(results);
  }

  async function handleSubmit() {
    if (lat == null || lng == null) {
      setSubmitError("GPS location is required. Please allow location access and try again.");
      return;
    }
    setStep("submitting");
    setSubmitError("");

    try {
      const supabase = createClient();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error("Not signed in");

      // 1. Upload photo
      if (!photoFile) throw new Error("Photo required");
      const photoUrl = await uploadCatPhoto(supabase, photoFile, user.id);

      // 2. Get or create cat
      let catId = selectedCatId;
      if (!catId) {
        const cat = await createCat({ name: catName || undefined, primary_photo_url: photoUrl });
        catId = cat.id;
      }

      // 3. Create sighting
      await createSighting({
        cat_id: catId,
        photo_url: photoUrl,
        lat: lat ?? 0,
        lng: lng ?? 0,
        location_label: locationLabel || undefined,
        notes: notes || undefined,
        visibility,
      });

      router.push(`/cats/${catId}`);
    } catch (err) {
      setSubmitError(err instanceof Error ? err.message : "Something went wrong");
      setStep("details");
    }
  }

  if (step === "submitting") {
    return (
      <div className="flex flex-col items-center gap-4 py-20 text-stone-500">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-amber-500 border-t-transparent" />
        <p className="text-sm">Uploading your sighting…</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Step: Photo */}
      {step === "photo" && (
        <div className="space-y-4">
          <PhotoUpload onFile={handlePhotoFile} preview={photoPreview} error={errors.photo} />
          <Button
            disabled={!photoFile}
            onClick={() => setStep("cat")}
            size="lg"
            className="w-full"
          >
            Next: Name the cat →
          </Button>
        </div>
      )}

      {/* Step: Cat identity */}
      {step === "cat" && (
        <div className="space-y-4">
          <div className="flex rounded-xl border border-stone-200 overflow-hidden text-sm font-medium">
            <button
              onClick={() => setCatMode("new")}
              className={`flex-1 py-2 transition-colors ${catMode === "new" ? "bg-amber-500 text-white" : "bg-white text-stone-600 hover:bg-stone-50"}`}
            >
              New cat
            </button>
            <button
              onClick={() => setCatMode("existing")}
              className={`flex-1 py-2 transition-colors ${catMode === "existing" ? "bg-amber-500 text-white" : "bg-white text-stone-600 hover:bg-stone-50"}`}
            >
              Existing cat
            </button>
          </div>

          {catMode === "new" ? (
            <Input
              label="Cat nickname (optional)"
              placeholder="e.g. Whiskers, Orange Tabby, Mr. Fluffington…"
              value={catName}
              onChange={(e) => setCatName(e.target.value)}
              hint="You can leave this blank and name them later"
            />
          ) : (
            <div className="space-y-2">
              <Input
                label="Search for a cat"
                placeholder="Search by name…"
                value={catSearch}
                onChange={(e) => handleCatSearch(e.target.value)}
              />
              {catResults.length > 0 && (
                <ul className="rounded-xl border border-stone-200 bg-white divide-y divide-stone-100 overflow-hidden">
                  {catResults.map((c) => (
                    <li key={c.id}>
                      <button
                        onClick={() => { setSelectedCatId(c.id); setCatSearch(c.name ?? ""); setCatResults([]); }}
                        className={`w-full px-4 py-2.5 text-left text-sm hover:bg-amber-50 ${selectedCatId === c.id ? "bg-amber-50 text-amber-700 font-medium" : "text-stone-700"}`}
                      >
                        {c.name ?? "Unnamed cat"}
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          )}

          <div className="space-y-1">
            <label className="text-sm font-medium text-stone-700">Tags</label>
            <TagInput
              tags={tags}
              onAdd={(t) => setTags((prev) => [...prev, t])}
              onRemove={(t) => setTags((prev) => prev.filter((x) => x !== t))}
              suggestions={CAT_TAG_SUGGESTIONS}
              placeholder="friendly, fluffy, tabby…"
            />
          </div>

          <div className="flex gap-3">
            <Button variant="secondary" onClick={() => setStep("photo")} className="flex-1">← Back</Button>
            <Button onClick={() => setStep("details")} className="flex-1">Next: Details →</Button>
          </div>
        </div>
      )}

      {/* Step: Details */}
      {step === "details" && (
        <div className="space-y-4">
          <Textarea
            label="Notes (optional)"
            placeholder="This cat was very friendly and let me pet it!"
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
          />
          <Input
            label="Location description (optional)"
            placeholder="e.g. Near the coffee shop on Main St"
            value={locationLabel}
            onChange={(e) => setLocationLabel(e.target.value)}
            hint={lat != null ? `GPS location captured (${lat.toFixed(4)}, ${lng?.toFixed(4)})` : "GPS unavailable — consider adding a description"}
          />
          <div className="space-y-1">
            <label className="text-sm font-medium text-stone-700">Who can see this?</label>
            <div className="flex gap-2">
              {(["public", "friends", "private"] as const).map((v) => (
                <button
                  key={v}
                  onClick={() => setVisibility(v)}
                  className={`flex-1 rounded-xl border py-2 text-xs font-medium capitalize transition-colors ${
                    visibility === v
                      ? "border-amber-500 bg-amber-50 text-amber-700"
                      : "border-stone-200 bg-white text-stone-600 hover:bg-stone-50"
                  }`}
                >
                  {v}
                </button>
              ))}
            </div>
          </div>

          {submitError && <p className="text-sm text-red-500">{submitError}</p>}

          <div className="flex gap-3">
            <Button variant="secondary" onClick={() => setStep("cat")} className="flex-1">← Back</Button>
            <Button onClick={handleSubmit} className="flex-1">Post sighting 🐱</Button>
          </div>
        </div>
      )}
    </div>
  );
}
