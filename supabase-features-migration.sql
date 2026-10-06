-- Run this once in Supabase SQL Editor for an existing BLOGVERSE database.
create table if not exists public.comment_reactions (
  comment_id uuid not null references public.comments(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

create table if not exists public.post_reactions (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reaction text not null check (reaction in ('like', 'love', 'sad', 'angry')),
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

alter table public.comment_reactions enable row level security;
alter table public.post_reactions enable row level security;

drop policy if exists "Comment reactions are public readable" on public.comment_reactions;
create policy "Comment reactions are public readable"
on public.comment_reactions for select using (true);

drop policy if exists "Users can react to comments" on public.comment_reactions;
create policy "Users can react to comments"
on public.comment_reactions for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can remove their comment reactions" on public.comment_reactions;
create policy "Users can remove their comment reactions"
on public.comment_reactions for delete
using (auth.uid() = user_id);

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
on public.post_reactions for delete
using (auth.uid() = user_id);

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;
