// Landing page — redirects authenticated users to /map, shows marketing to guests
import Link from "next/link";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center px-6 text-center">
      <div className="max-w-xl">
        <h1 className="text-5xl font-bold tracking-tight text-stone-900">
          Cat Snap
        </h1>
        <p className="mt-4 text-xl text-stone-600">
          Spot a street cat? Snap a photo, drop a pin, and share it with your
          neighborhood.
        </p>
        <div className="mt-8 flex gap-4 justify-center">
          <Link
            href="/map"
            className="rounded-xl bg-amber-500 px-6 py-3 font-semibold text-white hover:bg-amber-600 transition-colors"
          >
            Explore the Map
          </Link>
          <Link
            href="/signup"
            className="rounded-xl border border-stone-300 bg-white px-6 py-3 font-semibold text-stone-800 hover:bg-stone-50 transition-colors"
          >
            Sign Up Free
          </Link>
        </div>
      </div>
    </main>
  );
}
