-- Run this once in Supabase SQL Editor to enable profile, cover, post,
-- and comment image uploads for signed-in users.

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
to authenticated
with check (
  bucket_id = 'forum-images'
  and (
    name like ('posts/' || (select auth.uid())::text || '_%')
    or name like ('avatars/' || (select auth.uid())::text || '_%')
    or name like ('covers/' || (select auth.uid())::text || '_%')
    or name like ('comments/' || (select auth.uid())::text || '_%')
  )
);

drop policy if exists "Authenticated users can update own images" on storage.objects;
create policy "Authenticated users can update own images"
on storage.objects for update
to authenticated
using (
  bucket_id = 'forum-images'
  and (
    name like ('posts/' || (select auth.uid())::text || '_%')
    or name like ('avatars/' || (select auth.uid())::text || '_%')
    or name like ('covers/' || (select auth.uid())::text || '_%')
    or name like ('comments/' || (select auth.uid())::text || '_%')
  )
)
with check (
  bucket_id = 'forum-images'
  and (
    name like ('posts/' || (select auth.uid())::text || '_%')
    or name like ('avatars/' || (select auth.uid())::text || '_%')
    or name like ('covers/' || (select auth.uid())::text || '_%')
    or name like ('comments/' || (select auth.uid())::text || '_%')
  )
);

drop policy if exists "Authenticated users can delete own images" on storage.objects;
create policy "Authenticated users can delete own images"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'forum-images'
  and (
    name like ('posts/' || (select auth.uid())::text || '_%')
    or name like ('avatars/' || (select auth.uid())::text || '_%')
    or name like ('covers/' || (select auth.uid())::text || '_%')
    or name like ('comments/' || (select auth.uid())::text || '_%')
  )
);

notify pgrst, 'reload schema';
