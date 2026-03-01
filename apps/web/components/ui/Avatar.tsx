import Image from "next/image";
import { clsx } from "clsx";

type Size = "xs" | "sm" | "md" | "lg" | "xl";

const sizeClasses: Record<Size, string> = {
  xs: "h-6 w-6 text-xs",
  sm: "h-8 w-8 text-sm",
  md: "h-10 w-10 text-base",
  lg: "h-12 w-12 text-lg",
  xl: "h-16 w-16 text-2xl",
};

const sizePx: Record<Size, number> = {
  xs: 24,
  sm: 32,
  md: 40,
  lg: 48,
  xl: 64,
};

interface AvatarProps {
  src?: string | null;
  name?: string | null;
  size?: Size;
  className?: string;
}

function initials(name: string) {
  return name
    .split(" ")
    .map((n) => n[0])
    .slice(0, 2)
    .join("")
    .toUpperCase();
}

export function Avatar({ src, name, size = "md", className }: AvatarProps) {
  return (
    <div
      className={clsx(
        "relative inline-flex shrink-0 items-center justify-center overflow-hidden rounded-full bg-amber-100 font-semibold text-amber-700",
        sizeClasses[size],
        className
      )}
    >
      {src ? (
        <Image
          src={src}
          alt={name ?? "User avatar"}
          fill
          className="object-cover"
          sizes={`${sizePx[size]}px`}
        />
      ) : (
        <span>{name ? initials(name) : "?"}</span>
      )}
    </div>
  );
}
