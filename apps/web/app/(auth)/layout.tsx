import type { ReactNode } from "react";
import Link from "next/link";

export default function AuthLayout({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center px-4 py-12 bg-stone-50">
      <Link href="/" className="mb-8 flex items-center gap-2 text-2xl font-bold text-stone-900">
        <span>🐱</span> Cat Snap
      </Link>
      <div className="w-full max-w-sm rounded-2xl border border-stone-200 bg-white p-8 shadow-sm">
        {children}
      </div>
    </div>
  );
}
