# Family Voice Archive · آرشیف آوازهای خانواده

A private archive for our family's Hazara oral tradition: dobaiti, songs, stories, lullabies (لالایی) and proverbs (متل), plus family photos. Everything comes from the family WhatsApp chats.

The design follows a handmade collage idea. It has Persian rugs in the background, wavy rug runners for each month, and torn paper, tape and ballpoint notes. Voice notes are added from a "Pour some tea" page.

## What it does

- **Imports WhatsApp chat exports.** Drop in a `.zip` made with "Export chat → Attach/Include media". The app unzips it, reads the chat text and pulls out every voice note, photo and (optionally) video. For each one it records who sent it, when, and any caption.
- **Imports single files too.** These can be voice notes or photos downloaded one at a time, for example from WhatsApp Web. A "Shared by" field records who sent them.
- **Gives every item a card** in a month-by-month feed, and you can fill in:
  - title
  - type (Dobaiti, Song, Story, Lullaby, Proverb, Prayer/dua, Memory, Other)
  - the words as spoken in Hazaragi/Dari (right to left)
  - an English translation
  - the story behind it
  - place, sender and date
- **Finding things:** search, filters by sender and type, newest/oldest sort, light and dark themes, and a phone-friendly layout.
- **Duplicates:** re-importing the same chat only adds new items.

## How to export a chat

Export only works in the WhatsApp phone app, not WhatsApp Web or Desktop.

- **iPhone:** open the chat → tap the group or contact name → Export Chat → Attach Media → save to Files.
- **Android:** open the chat → ⋮ → More → Export chat → Include media → save to Drive.

Then drop the `.zip` into the app's **Add** page.

## How it's built

It's a single file, `index.html`, with no build step.

- **Unzipping:** [JSZip](https://stuk.github.io/jszip/) (from cdnjs) opens the export.
- **Chat parsing:**
  - Handles iPhone (`[12/31/23, 9:15:04 PM] Name: <attached: …>`) and Android (`12/31/23, 9:15 PM - Name: … (file attached)`) lines.
  - Strips invisible characters.
  - Detects M/D/Y, D/M/Y or Y-M-D date order from the whole chat, and checks dates against WhatsApp's media filenames.
- **Voice notes:** WhatsApp `.opus` files are Ogg Opus. They're repackaged into WebM in the browser without re-encoding, because the storage doesn't accept Ogg. MP3, WAV and AAC are re-encoded to Opus with WebCodecs, and `.m4a` is stored as MP4.
- **Skipped files:** stickers, unsupported types and files over 20 MB are skipped, with the reason shown.

## Where the data lives

This page was made as a Claude artifact. **Saving and sharing use Claude's artifact storage** (`claude.use("db")` for the details, `claude.use("assets")` for the audio and photos). Only people with edit access can import, edit or delete; people it's shared with can browse and listen.

The live archive is the Claude artifact, not this repo. **No recordings or photos are stored here**: this repo holds only the code.

If you open `index.html` anywhere else, such as GitHub Pages or a local file, there's no storage. The app runs in **Preview mode**: imports work so you can try them, but nothing is saved. Hosting it on its own would need its own storage backend, for example Firebase or Supabase.

## Family sign-in (Supabase)

The standalone site can have real family accounts. It uses [Supabase](https://supabase.com) (free tier) for sign-in, the database and private file storage.

- **Signing in:** family sign in with an emailed link, so there's no password.
- **Access:** only emails on the family list can open anything.
  - **Viewers** can browse and listen.
  - **Editors** can also import, edit, delete, and manage the list from **Family access**.
- **Storage:** recordings and photos go in a private storage bucket. Each file is up to 50 MB.

### One-time setup (about 10 minutes)

1. **Create a project.** Sign up at supabase.com and create a new project (any name, e.g. `family-voice-archive`). Pick a region near you and save the database password somewhere safe.
2. **Run the setup script.** Open **SQL Editor → New query** and paste in everything from [`supabase/setup.sql`](supabase/setup.sql). Change `YOUR_EMAIL@example.com` on the last line to the email you'll sign in with, then click **Run**. This creates the family list (with you as the first editor), the items table, the private `media` storage bucket, and the security rules.
3. **Set the sign-in addresses.** Go to **Authentication → URL Configuration** and set **Site URL** to `https://ninialbanini.github.io/familyArchive/`. Add the same address under **Redirect URLs**.
4. **Copy your keys.** Under **Project Settings → API**, copy the **Project URL** and the **anon public** key into [`config.js`](config.js), then commit. Both are safe to publish, because the security rules in the setup script decide who can read or write.
5. **Sign in.** Open the site and sign in with your email. Then use **Family access** to add relatives as viewers or editors. Each of them signs in with the email you added.

### Family password (optional)

Besides individual email sign-in, the login page offers a **Family password** that everyone in the family shares. It can listen, upload and edit, but it can't manage the family list. After signing in, people type their name, and uploads and edits are labelled with it.

1. In Supabase, go to **Authentication → Users → Add user → Create new user**. Use the email `family.archive@example.com` (the `familyLoginEmail` in `config.js`) and choose the family password. Tick **Auto Confirm User**.
2. In **SQL Editor**, run [`supabase/family-login.sql`](supabase/family-login.sql). This adds the "family" role and puts that login on the family list. New projects get this from `setup.sql` already.
3. To change the family password later, open that user under **Authentication → Users** and set a new password. Everyone already signed in stays signed in, so to lock someone out, also sign out all sessions for that user.

The password is checked by Supabase, not by the page, so it can't be got around by reading the code. Anyone who knows it can upload and delete, though, so share it only with family.

Supabase's built-in email service only sends a few sign-in emails per hour. That's fine for a family. If it becomes a problem, connect your own email sender under **Authentication → Emails → SMTP Settings**.

With `config.js` left empty, the login page says sign-in isn't set up yet.

## Privacy

This is family material. Don't commit chat exports, voice notes or photos to this repository, especially while it's public.
