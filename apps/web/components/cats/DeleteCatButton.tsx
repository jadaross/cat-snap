"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export function DeleteCatButton({ catId, catName }: { catId: string; catName: string | null }) {
  const router = useRouter();
  const [showModal, setShowModal] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState("");

  async function handleDelete() {
    setDeleting(true);
    setError("");
    try {
      const res = await fetch(`/api/cats/${catId}`, { method: "DELETE" });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.error ?? "Delete failed");
      }
      router.push("/cats");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong");
      setDeleting(false);
    }
  }

  return (
    <>
      <button
        onClick={() => setShowModal(true)}
        className="rounded-xl border border-red-300 bg-red-50 px-4 py-2 text-sm font-semibold text-red-700 hover:bg-red-100 transition-colors"
      >
        Delete cat
      </button>

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-stone-900">Delete {catName ?? "this cat"}?</h2>
            <p className="mt-2 text-sm text-stone-600">
              This will permanently delete the cat profile and all associated sightings. This action cannot be undone.
            </p>
            {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
            <div className="mt-5 flex gap-3">
              <button
                onClick={() => setShowModal(false)}
                disabled={deleting}
                className="flex-1 rounded-xl border border-stone-200 py-2 text-sm font-medium text-stone-700 hover:bg-stone-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleDelete}
                disabled={deleting}
                className="flex-1 rounded-xl bg-red-600 py-2 text-sm font-semibold text-white hover:bg-red-700 transition-colors disabled:opacity-60"
              >
                {deleting ? "Deleting…" : "Yes, delete"}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
