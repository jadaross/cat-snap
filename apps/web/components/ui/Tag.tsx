import { clsx } from "clsx";

interface TagProps {
  label: string;
  onRemove?: () => void;
  variant?: "default" | "amber";
  className?: string;
}

export function Tag({ label, onRemove, variant = "default", className }: TagProps) {
  return (
    <span
      className={clsx(
        "inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium",
        variant === "amber"
          ? "bg-amber-100 text-amber-800"
          : "bg-stone-100 text-stone-700",
        className
      )}
    >
      {label}
      {onRemove && (
        <button
          type="button"
          onClick={onRemove}
          className="ml-0.5 rounded-full hover:text-stone-900 focus:outline-none"
          aria-label={`Remove ${label}`}
        >
          ×
        </button>
      )}
    </span>
  );
}

interface TagInputProps {
  tags: string[];
  onAdd: (tag: string) => void;
  onRemove: (tag: string) => void;
  placeholder?: string;
  suggestions?: string[];
}

export function TagInput({ tags, onAdd, onRemove, placeholder = "Add tag…", suggestions = [] }: TagInputProps) {
  function handleKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === "Enter" || e.key === ",") {
      e.preventDefault();
      const value = (e.target as HTMLInputElement).value.trim().toLowerCase();
      if (value && !tags.includes(value)) {
        onAdd(value);
        (e.target as HTMLInputElement).value = "";
      }
    }
  }

  const unusedSuggestions = suggestions.filter((s) => !tags.includes(s));

  return (
    <div className="space-y-2">
      <div className="flex flex-wrap gap-1.5 rounded-xl border border-stone-300 bg-white p-2 focus-within:border-amber-500 focus-within:ring-2 focus-within:ring-amber-500/20 min-h-[44px]">
        {tags.map((tag) => (
          <Tag key={tag} label={tag} onRemove={() => onRemove(tag)} />
        ))}
        <input
          type="text"
          onKeyDown={handleKeyDown}
          placeholder={tags.length === 0 ? placeholder : ""}
          className="flex-1 min-w-[120px] text-sm outline-none placeholder:text-stone-400"
        />
      </div>
      {unusedSuggestions.length > 0 && (
        <div className="flex flex-wrap gap-1.5">
          {unusedSuggestions.map((s) => (
            <button
              key={s}
              type="button"
              onClick={() => onAdd(s)}
              className="text-xs text-stone-500 hover:text-amber-700 hover:bg-amber-50 rounded-full border border-stone-200 px-2.5 py-0.5 transition-colors"
            >
              + {s}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
