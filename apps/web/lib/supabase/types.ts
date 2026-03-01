// Auto-generate this file with: npx supabase gen types typescript --project-id <project-id>
// For now, hand-authored types that mirror the database schema.

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          username: string;
          display_name: string | null;
          avatar_url: string | null;
          bio: string | null;
          city: string | null;
          created_at: string;
        };
        Insert: Omit<Database["public"]["Tables"]["users"]["Row"], "created_at">;
        Update: Partial<Database["public"]["Tables"]["users"]["Insert"]>;
      };
      cats: {
        Row: {
          id: string;
          created_by: string | null;
          name: string | null;
          description: string | null;
          primary_photo_url: string | null;
          is_tnr: boolean;
          has_caretaker: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<
          Database["public"]["Tables"]["cats"]["Row"],
          "id" | "created_at" | "updated_at"
        >;
        Update: Partial<Database["public"]["Tables"]["cats"]["Insert"]>;
      };
      sightings: {
        Row: {
          id: string;
          cat_id: string;
          user_id: string | null;
          photo_url: string;
          // PostGIS geography stored as GeoJSON in JS
          location: { type: "Point"; coordinates: [number, number] };
          location_label: string | null;
          notes: string | null;
          visibility: "public" | "friends" | "private";
          seen_at: string;
          created_at: string;
        };
        Insert: Omit<
          Database["public"]["Tables"]["sightings"]["Row"],
          "id" | "created_at"
        >;
        Update: Partial<Database["public"]["Tables"]["sightings"]["Insert"]>;
      };
      friendships: {
        Row: {
          id: string;
          requester_id: string;
          addressee_id: string;
          status: "pending" | "accepted" | "blocked";
          created_at: string;
        };
        Insert: Omit<
          Database["public"]["Tables"]["friendships"]["Row"],
          "id" | "created_at"
        >;
        Update: Partial<Database["public"]["Tables"]["friendships"]["Insert"]>;
      };
      cat_follows: {
        Row: {
          user_id: string;
          cat_id: string;
          created_at: string;
        };
        Insert: Omit<
          Database["public"]["Tables"]["cat_follows"]["Row"],
          "created_at"
        >;
        Update: never;
      };
      reactions: {
        Row: {
          id: string;
          sighting_id: string;
          user_id: string;
          emoji: string;
          created_at: string;
        };
        Insert: Omit<
          Database["public"]["Tables"]["reactions"]["Row"],
          "id" | "created_at"
        >;
        Update: never;
      };
      comments: {
        Row: {
          id: string;
          sighting_id: string;
          user_id: string | null;
          body: string;
          created_at: string;
        };
        Insert: Omit<
          Database["public"]["Tables"]["comments"]["Row"],
          "id" | "created_at"
        >;
        Update: Partial<Pick<Database["public"]["Tables"]["comments"]["Row"], "body">>;
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
  };
}

// Convenience row types
export type UserRow = Database["public"]["Tables"]["users"]["Row"];
export type CatRow = Database["public"]["Tables"]["cats"]["Row"];
export type SightingRow = Database["public"]["Tables"]["sightings"]["Row"];
export type FriendshipRow = Database["public"]["Tables"]["friendships"]["Row"];
export type ReactionRow = Database["public"]["Tables"]["reactions"]["Row"];
export type CommentRow = Database["public"]["Tables"]["comments"]["Row"];
