-- Run this once in Supabase SQL Editor if Follow/Follow back reports
-- "Could not find the table public.follows in the schema cache".

create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint follows_no_self_follow check (follower_id <> following_id)
);

alter table public.follows enable row level security;

drop policy if exists "Follows are public readable" on public.follows;
create policy "Follows are public readable"
on public.follows for select
using (true);

drop policy if exists "Users can follow as themselves" on public.follows;
create policy "Users can follow as themselves"
on public.follows for insert
with check (auth.uid() = follower_id and follower_id <> following_id);

drop policy if exists "Users can unfollow as themselves" on public.follows;
create policy "Users can unfollow as themselves"
on public.follows for delete
using (auth.uid() = follower_id);

notify pgrst, 'reload schema';
