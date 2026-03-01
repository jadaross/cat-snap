import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { Nav } from "@/components/layout/Nav";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

export const metadata: Metadata = {
  title: "Cat Snap — Find Your Neighborhood Cats",
  description:
    "Discover and track street cats in your city. Snap a photo, tag the location, and follow your neighborhood felines.",
  openGraph: {
    title: "Cat Snap",
    description: "A community map for your neighborhood cats.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={inter.variable}>
      <body className="bg-stone-50 text-stone-900 antialiased">
        <Nav />
        {/* pt-16 to clear fixed top nav; pb-16 for mobile bottom nav */}
        <div className="pt-16 pb-16 sm:pb-0">{children}</div>
      </body>
    </html>
  );
}
