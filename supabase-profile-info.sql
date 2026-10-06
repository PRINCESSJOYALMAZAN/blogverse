-- Run once in Supabase SQL Editor for the editable About Me fields.
alter table public.profiles add column if not exists bio text;
alter table public.profiles add column if not exists course text;
alter table public.profiles add column if not exists location text;
alter table public.profiles add column if not exists joined_year integer;

update public.profiles
set
  bio = coalesce(bio, 'I love coding, building systems, and exploring new technologies.'),
  course = coalesce(course, 'IT Student'),
  location = coalesce(location, 'Philippines'),
  joined_year = coalesce(joined_year, extract(year from created_at)::integer);
