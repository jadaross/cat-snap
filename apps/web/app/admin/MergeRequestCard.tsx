"use client";

import { useState } from "react";
import Image from "next/image";

interface Sighting {
  id: string;
  photo_url: string;
  cat_id: string;
  cats: { id: string; name: string | null } | null;
}

interface MergeRequest {
  id: string;
  submitted_by: string;
  sighting_ids: string[];
  note: string | null;
  status: string;
  created_at: string;
}

interface Props {
  mergeRequest: MergeRequest;
  sightings: Sighting[];
}

export function MergeRequestCard({ mergeRequest, sightings }: Props) {
  const cats = Array.from(
    new Map(sightings.map((s) => [s.cat_id, s.cats])).entries()
  ).map(([catId, cat]) => ({ catId, name: cat?.name ?? "Unnamed cat" }));

  const [targetCatId, setTargetCatId] = useState(cats[0]?.catId ?? "");
  const [status, setStatus] = useState<"idle" | "approving" | "rejecting" | "done">("idle");
  const [result, setResult] = useState<"approved" | "rejected" | null>(null);
  const [error, setError] = useState("");

  async function handleApprove() {
    if (!targetCatId) { setError("Select a target cat first."); return; }
    setStatus("approving");
    setError("");
    try {
      const res = await fetch(`/api/admin/merge-requests/${mergeRequest.id}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ target_cat_id: targetCatId }),
      });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      setResult("approved");
      setStatus("done");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error");
      setStatus("idle");
    }
  }

  async function handleReject() {
    setStatus("rejecting");
    setError("");
    try {
      const res = await fetch(`/api/admin/merge-requests/${mergeRequest.id}`, {
        method: "PATCH",
      });
      if (!res.ok) throw new Error((await res.json()).error ?? "Failed");
      setResult("rejected");
      setStatus("done");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error");
      setStatus("idle");
    }
  }

  if (status === "done") {
    return (
      <div className="rounded-2xl border border-stone-200 bg-stone-50 p-4 text-sm text-stone-500 italic">
        Request {result} ✓
      </div>
    );
  }

  return (
    <div className="rounded-2xl border border-stone-200 bg-white p-4 space-y-4 shadow-sm">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-xs text-stone-400">Submitted {new Date(mergeRequest.created_at).toLocaleDateString()}</p>
          {mergeRequest.note && (
            <p className="mt-1 text-sm text-stone-700 italic">"{mergeRequest.note}"</p>
          )}
        </div>
        <span className="shrink-0 rounded-full bg-amber-100 px-2 py-0.5 text-xs font-medium text-amber-800">
          {mergeRequest.sighting_ids.length} sightings
        </span>
      </div>

      {/* Sighting thumbnails */}
      <div className="flex flex-wrap gap-2">
        {sightings.map((s) => (
          <div key={s.id} className="text-center">
            <div className="relative h-16 w-16 overflow-hidden rounded-xl border border-stone-200 bg-stone-100">
              <Image src={s.photo_url} alt="Sighting" fill className="object-cover" sizes="64px" />
            </div>
            <p className="mt-0.5 text-xs text-stone-500 truncate w-16">
              {s.cats?.name ?? "?"}
            </p>
          </div>
        ))}
      </div>

      {/* Target cat selector */}
      {cats.length > 1 && (
        <div className="space-y-1">
          <label className="text-xs font-medium text-stone-600">Keep as which cat?</label>
          <select
            value={targetCatId}
            onChange={(e) => setTargetCatId(e.target.value)}
            className="w-full rounded-xl border border-stone-200 px-3 py-2 text-sm focus:border-amber-400 focus:outline-none"
          >
            {cats.map(({ catId, name }) => (
              <option key={catId} value={catId}>{name}</option>
            ))}
          </select>
        </div>
      )}

      {error && <p className="text-sm text-red-500">{error}</p>}

      <div className="flex gap-3">
        <button
          onClick={handleApprove}
          disabled={status !== "idle"}
          className="flex-1 rounded-xl bg-green-600 py-2 text-sm font-semibold text-white hover:bg-green-700 transition-colors disabled:opacity-50"
        >
          {status === "approving" ? "Approving…" : "Approve"}
        </button>
        <button
          onClick={handleReject}
          disabled={status !== "idle"}
          className="flex-1 rounded-xl border border-stone-200 py-2 text-sm font-medium text-stone-700 hover:bg-stone-50 transition-colors disabled:opacity-50"
        >
          {status === "rejecting" ? "Rejecting…" : "Reject"}
        </button>
      </div>
    </div>
  );
}
