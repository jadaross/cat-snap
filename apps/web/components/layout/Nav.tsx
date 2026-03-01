"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { clsx } from "clsx";
import { Avatar } from "@/components/ui/Avatar";
import { useAuth } from "@/lib/hooks/useAuth";
import { createClient } from "@/lib/supabase/client";

const NAV_LINKS = [
  { href: "/map", label: "Map", icon: MapIcon },
  { href: "/cats", label: "Cats", icon: CatIcon },
  { href: "/feed", label: "Feed", icon: FeedIcon },
];

export function Nav() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, loading } = useAuth();

  async function handleSignOut() {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  }

  return (
    <>
      {/* Desktop top nav */}
      <header className="fixed top-0 inset-x-0 z-40 border-b border-stone-200 bg-white/90 backdrop-blur-sm">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2 font-bold text-stone-900 text-lg">
            <span className="text-2xl">🐱</span>
            <span>Cat Snap</span>
          </Link>

          {/* Desktop links */}
          <nav className="hidden sm:flex items-center gap-1">
            {NAV_LINKS.map(({ href, label, icon: Icon }) => (
              <Link
                key={href}
                href={href}
                className={clsx(
                  "flex items-center gap-1.5 rounded-xl px-3 py-2 text-sm font-medium transition-colors",
                  pathname.startsWith(href)
                    ? "bg-amber-50 text-amber-700"
                    : "text-stone-600 hover:bg-stone-100 hover:text-stone-900"
                )}
              >
                <Icon className="h-4 w-4" />
                {label}
              </Link>
            ))}
          </nav>

          {/* Auth area */}
          <div className="flex items-center gap-3">
            {!loading && (
              <>
                {user ? (
                  <>
                    <Link
                      href="/sightings/new"
                      className="hidden sm:flex items-center gap-1.5 rounded-xl bg-amber-500 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-600 transition-colors"
                    >
                      <span>+</span> Snap a Cat
                    </Link>
                    <div className="relative group">
                      <button className="focus:outline-none">
                        <Avatar src={user.user_metadata?.avatar_url} name={user.user_metadata?.full_name ?? user.email} size="sm" />
                      </button>
                      <div className="absolute right-0 top-full mt-1 hidden group-focus-within:flex flex-col w-44 rounded-xl border border-stone-200 bg-white py-1 shadow-lg">
                        <Link href="/profile" className="px-4 py-2 text-sm text-stone-700 hover:bg-stone-50">Profile</Link>
                        <button onClick={handleSignOut} className="px-4 py-2 text-sm text-left text-stone-700 hover:bg-stone-50">Sign out</button>
                      </div>
                    </div>
                  </>
                ) : (
                  <>
                    <Link href="/login" className="text-sm font-medium text-stone-600 hover:text-stone-900">Log in</Link>
                    <Link href="/signup" className="rounded-xl bg-amber-500 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-600 transition-colors">Sign up</Link>
                  </>
                )}
              </>
            )}
          </div>
        </div>
      </header>

      {/* Mobile bottom nav */}
      <nav className="fixed bottom-0 inset-x-0 z-40 border-t border-stone-200 bg-white sm:hidden">
        <div className="flex">
          {NAV_LINKS.map(({ href, label, icon: Icon }) => (
            <Link
              key={href}
              href={href}
              className={clsx(
                "flex flex-1 flex-col items-center gap-0.5 py-3 text-xs font-medium transition-colors",
                pathname.startsWith(href) ? "text-amber-600" : "text-stone-500"
              )}
            >
              <Icon className="h-5 w-5" />
              {label}
            </Link>
          ))}
          {user && (
            <Link
              href="/sightings/new"
              className="flex flex-1 flex-col items-center gap-0.5 py-3 text-xs font-semibold text-amber-600"
            >
              <PlusIcon className="h-5 w-5" />
              Snap
            </Link>
          )}
        </div>
      </nav>
    </>
  );
}

// --- Inline SVG icons ---

function MapIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
    </svg>
  );
}

function CatIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.5c-1.5-2-4-2.5-5.5-1C5 7 5 9.5 6 11c-1 .5-2 1.5-2 3 0 2.5 2 4 4.5 4h7c2.5 0 4.5-1.5 4.5-4 0-1.5-1-2.5-2-3 1-1.5 1-4-.5-5.5C16 4 13.5 4.5 12 6.5z" />
    </svg>
  );
}

function FeedIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
    </svg>
  );
}

function PlusIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
    </svg>
  );
}
