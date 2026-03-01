"use client";

import { useRef, useState } from "react";
import Image from "next/image";

interface PhotoUploadProps {
  onFile: (file: File) => void;
  preview?: string | null;
  error?: string;
}

export function PhotoUpload({ onFile, preview, error }: PhotoUploadProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [dragOver, setDragOver] = useState(false);

  function handleFile(file: File) {
    if (!file.type.startsWith("image/")) return;
    onFile(file);
  }

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) handleFile(file);
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault();
    setDragOver(false);
    const file = e.dataTransfer.files[0];
    if (file) handleFile(file);
  }

  return (
    <div className="space-y-1">
      <label className="text-sm font-medium text-stone-700">Photo</label>
      <div
        onClick={() => inputRef.current?.click()}
        onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
        onDragLeave={() => setDragOver(false)}
        onDrop={handleDrop}
        className={`relative flex cursor-pointer flex-col items-center justify-center rounded-2xl border-2 border-dashed transition-colors ${
          dragOver
            ? "border-amber-400 bg-amber-50"
            : error
            ? "border-red-300 bg-red-50"
            : preview
            ? "border-stone-200 bg-stone-100"
            : "border-stone-300 bg-stone-50 hover:border-amber-400 hover:bg-amber-50"
        }`}
        style={{ minHeight: 220 }}
      >
        {preview ? (
          <>
            <Image
              src={preview}
              alt="Preview"
              fill
              className="rounded-2xl object-cover"
              sizes="(max-width: 640px) 100vw, 480px"
            />
            <div className="absolute inset-0 flex items-center justify-center rounded-2xl bg-black/30 opacity-0 hover:opacity-100 transition-opacity">
              <span className="text-sm font-semibold text-white">Change photo</span>
            </div>
          </>
        ) : (
          <div className="flex flex-col items-center gap-2 py-10 text-stone-400">
            <span className="text-4xl">📷</span>
            <p className="text-sm font-medium">Tap to add a photo</p>
            <p className="text-xs">or drag and drop</p>
          </div>
        )}
      </div>
      {error && <p className="text-xs text-red-500">{error}</p>}
      <input
        ref={inputRef}
        type="file"
        accept="image/*"
        capture="environment"
        className="sr-only"
        onChange={handleChange}
      />
    </div>
  );
}
