create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  name text,
  avatar_url text,
  cover_url text,
  created_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists cover_url text;

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  image_urls text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  image_urls text[] not null default '{}',
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(nullif(new.raw_user_meta_data->>'name', ''), 'New member')
  )
  on conflict (id) do update
    set email = excluded.email,
        name = coalesce(public.profiles.name, excluded.name);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

insert into public.profiles (id, email, name)
select
  users.id,
  coalesce(users.email, ''),
  coalesce(nullif(users.raw_user_meta_data->>'name', ''), 'New member')
from auth.users
on conflict (id) do nothing;

alter table public.posts
  drop constraint if exists posts_user_id_fkey,
  add constraint posts_user_id_fkey
    foreign key (user_id) references public.profiles(id) on delete cascade;

alter table public.comments
  drop constraint if exists comments_user_id_fkey,
  add constraint comments_user_id_fkey
    foreign key (user_id) references public.profiles(id) on delete cascade;

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;

drop policy if exists "Profiles are public readable" on public.profiles;
create policy "Profiles are public readable"
on public.profiles for select
using (true);

drop policy if exists "Users can insert their profile" on public.profiles;
create policy "Users can insert their profile"
on public.profiles for insert
with check (auth.uid() = id);

drop policy if exists "Users can update their profile" on public.profiles;
create policy "Users can update their profile"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Posts are public readable" on public.posts;
create policy "Posts are public readable"
on public.posts for select
using (true);

drop policy if exists "Authenticated users can create posts" on public.posts;
create policy "Authenticated users can create posts"
on public.posts for insert
with check (auth.uid() = user_id);

drop policy if exists "Post owners can update posts" on public.posts;
create policy "Post owners can update posts"
on public.posts for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Post owners can delete posts" on public.posts;
create policy "Post owners can delete posts"
on public.posts for delete
using (auth.uid() = user_id);

drop policy if exists "Comments are public readable" on public.comments;
create policy "Comments are public readable"
on public.comments for select
using (true);

drop policy if exists "Authenticated users can create comments" on public.comments;
create policy "Authenticated users can create comments"
on public.comments for insert
with check (auth.uid() = user_id);

drop policy if exists "Comment owners can update comments" on public.comments;
create policy "Comment owners can update comments"
on public.comments for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Comment owners can delete comments" on public.comments;
create policy "Comment owners can delete comments"
on public.comments for delete
using (auth.uid() = user_id);

insert into storage.buckets (id, name, public)
values ('forum-images', 'forum-images', true)
on conflict (id) do update set public = true;

drop policy if exists "Images are public readable" on storage.objects;
create policy "Images are public readable"
on storage.objects for select
using (bucket_id = 'forum-images');

drop policy if exists "Authenticated users can upload images" on storage.objects;
create policy "Authenticated users can upload images"
on storage.objects for insert
with check (
  bucket_id = 'forum-images'
  and auth.role() = 'authenticated'
  and (
    name like ('posts/' || auth.uid()::text || '_%')
    or name like ('avatars/' || auth.uid()::text || '_%')
    or name like ('comments/' || auth.uid()::text || '_%')
  )
);

drop policy if exists "Authenticated users can update own images" on storage.objects;
create policy "Authenticated users can update own images"
on storage.objects for update
using (
  bucket_id = 'forum-images'
  and (
    name like ('posts/' || auth.uid()::text || '_%')
    or name like ('avatars/' || auth.uid()::text || '_%')
    or name like ('comments/' || auth.uid()::text || '_%')
  )
)
with check (
  bucket_id = 'forum-images'
  and (
    name like ('posts/' || auth.uid()::text || '_%')
    or name like ('avatars/' || auth.uid()::text || '_%')
    or name like ('comments/' || auth.uid()::text || '_%')
  )
);

drop policy if exists "Authenticated users can delete own images" on storage.objects;
create policy "Authenticated users can delete own images"
on storage.objects for delete
using (
  bucket_id = 'forum-images'
  and (
    name like ('posts/' || auth.uid()::text || '_%')
    or name like ('avatars/' || auth.uid()::text || '_%')
    or name like ('comments/' || auth.uid()::text || '_%')
  )
);
