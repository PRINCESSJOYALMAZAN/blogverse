# BLOGVERSE

## GitHub Repository

[https://github.com/PRINCESSJOYALMAZAN/blogverse](https://github.com/PRINCESSJOYALMAZAN/blogverse)

## Live Demo

Replace this link with the Vercel URL after deployment:

[https://your-blogverse.vercel.app/](https://your-blogverse-live.vercel.app/)

## Concept

BLOGVERSE is a Flutter blog and community forum application connected to Supabase. Users can create accounts, publish posts, upload images, interact with the community, and manage their profiles in one responsive web experience.

## How to Run

Requirements: Flutter SDK, Dart SDK, Chrome, and a Supabase project.

From the project root, install dependencies and start the web app:

```powershell
cd "C:\Users\Administrator\Downloads\BLOG (2)\app"
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3001 `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Open `http://127.0.0.1:3001` in a browser.

To create a production build:

```powershell
flutter build web --release `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

## Main Features

- Responsive BLOGVERSE home feed with public posts and pagination.
- Supabase email/password sign up, sign in, session persistence, and sign out.
- Create, read, update, and delete blog posts.
- Multiple image uploads for posts, comments, and profile pictures.
- Post reactions, comment reactions, and share-link tracking.
- Comment creation, editing, deletion, and image attachments.
- Editable About Me information, profile statistics, skills, and gallery.
- Profile picture updates through Supabase Storage.
- Vercel-ready Flutter Web deployment configuration.

## Benefits

BLOGVERSE gives users one place to share ideas, projects, questions, and updates. The Home feed makes community activity easy to browse, while the Write page keeps publishing simple. Profile pages show each user's posts, About Me information, statistics, and uploaded images.

## Why This Design

The application uses a clean violet-and-navy visual identity to make the community experience feel modern and focused. The layout separates discovery, publishing, interaction, and profile management so the main workflows remain easy to understand during a demo.

## Feature Status

| Assignment item | Status | Notes |
| --- | --- | --- |
| Supabase authentication | Implemented | Email/password registration, login, session persistence, and sign out. |
| Home feed | Implemented | Public paginated posts with author profiles and filters. |
| Write and publish posts | Implemented | Supports title, body, tags, and multiple images. |
| Post management | Implemented | Post owners can edit and delete their posts. |
| Comments | Implemented | Create, edit, delete, image upload, and post detail view. |
| Post reactions | Implemented | Reaction records are stored in `post_reactions`. |
| Comment reactions | Implemented | Reaction records are stored in `comment_reactions`. |
| Share posts | Implemented | Copies the post URL and records shares in `post_shares`. |
| Profile management | Implemented | Editable About Me fields and profile picture upload. |
| Profile statistics | Implemented | Shows post, like, and share counts from Supabase. |
| Responsive design | Implemented | Desktop and mobile layouts are supported. |

## Demo Notes and Assumptions

- BLOGVERSE uses Supabase for authentication, database records, and image storage.
- Run `supabase.sql`, `supabase-reactions.sql`, and `supabase-profile-info.sql` in the Supabase SQL Editor before testing all features.
- Run `supabase-storage-fix.sql` if image upload policies need to be repaired.
- For a classroom demo, disable email confirmation in Supabase Auth or confirm the registration email.
- The share action copies a browser URL such as `/posts/{postId}`. If the browser blocks clipboard access, a selectable share dialog is shown.
- The Vercel project uses the repository root, `bash build.sh`, and `build/web` as its output directory.

## Completed So Far

- Built the responsive Home, Write, Post Detail, Login, Sign Up, and Profile screens.
- Connected authentication, posts, comments, reactions, profiles, and image storage to Supabase.
- Added profile editing for display name, bio, course or occupation, location, and joined year.
- Added post and comment image upload support.
- Added post sharing and profile statistics.
- Added Vercel deployment configuration and a complete demo script.

## Tech Stack

### Frontend

- Flutter
- Dart
- Provider state management
- go_router navigation
- Material 3 UI

### Backend Services

- Supabase Authentication
- Supabase PostgreSQL Database
- Supabase Row Level Security policies
- Supabase Storage

## Folder Structure

```text
lib/
  main.dart                     # App entry point and Supabase initialization
  router.dart                   # Application routes
  models/                       # Post, comment, and profile models
  providers/                    # Authentication, post, and profile state
  screens/                      # Home, auth, write, detail, and profile screens
  services/                     # Supabase service helpers
  widgets/                      # Sidebar, post cards, shell, and reusable UI
assets/                         # App assets
web/                            # Flutter Web entry files and icons
supabase.sql                   # Main database schema and RLS policies
supabase-reactions.sql         # Reactions and share-count migration
supabase-profile-info.sql      # Editable profile information migration
supabase-storage-fix.sql       # Storage bucket and image policies
build.sh                       # Vercel Flutter Web build script
vercel.json                    # Vercel deployment settings
DEMO_SCRIPT.md                 # Step-by-step presentation script
```
