-- Run this once in Supabase SQL Editor if post_reactions and
-- comment_reactions are not visible in Table Editor.

create table if not exists public.post_reactions (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reaction text not null check (reaction in ('like', 'love', 'sad', 'angry')),
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.comment_reactions (
  comment_id uuid not null references public.comments(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

create table if not exists public.post_shares (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.post_reactions enable row level security;
alter table public.comment_reactions enable row level security;
alter table public.post_shares enable row level security;

drop policy if exists "Post reactions are public readable" on public.post_reactions;
create policy "Post reactions are public readable"
on public.post_reactions for select using (true);

drop policy if exists "Users can react to posts" on public.post_reactions;
create policy "Users can react to posts"
on public.post_reactions for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update their post reaction" on public.post_reactions;
create policy "Users can update their post reaction"
on public.post_reactions for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can remove their post reactions" on public.post_reactions;
create policy "Users can remove their post reactions"
on public.post_reactions for delete using (auth.uid() = user_id);

drop policy if exists "Comment reactions are public readable" on public.comment_reactions;
create policy "Comment reactions are public readable"
on public.comment_reactions for select using (true);

drop policy if exists "Users can react to comments" on public.comment_reactions;
create policy "Users can react to comments"
on public.comment_reactions for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can remove their comment reactions" on public.comment_reactions;
create policy "Users can remove their comment reactions"
on public.comment_reactions for delete using (auth.uid() = user_id);

drop policy if exists "Post shares are public readable" on public.post_shares;
create policy "Post shares are public readable"
on public.post_shares for select using (true);

drop policy if exists "Users can record post shares" on public.post_shares;
create policy "Users can record post shares"
on public.post_shares for insert
with check (auth.uid() = user_id);
