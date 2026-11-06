# Hadīs-i Nasab · حدیث نسب

*The Tale of Genealogy*: the shared stories and journey of a family, kept in their own voices.

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
- **Photos & videos page:** a gallery where every photo and video is woven into a rug mosaic. Each rug holds up to 16 items, with the newest in the gold medallion at the centre. You can filter by photos or videos, by who shared them and by decade, and tapping a tile opens it full size.
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

## Accounts and family archives (Supabase)

The site uses [Supabase](https://supabase.com) (free tier) for accounts, the database and private file storage. It works for many families at once, and each family's archive is private to its members.

- **Accounts:** anyone can make an account by signing in with their email. They get an emailed link, so there's no account password.
- **Starting a family:** a signed-in person can start a family archive by choosing a **family name** and a **family password**. They become its **keeper**.
- **Joining:** relatives can come in two ways:
  - **Family password (no email):** type the family name, the family password and their name. The invite link from Family settings fills in the family name, so they only type the password.
  - **My email:** sign in with their email, choose **Join my family**, and type the family name and password. Once in, every member can listen, upload, edit and delete. Uploads and edits carry the person's name.
- **Keepers:** they can change the family password, make others keepers, and remove members, all from **Family settings**. Settings also has a ready-made invite message.
- **More than one family:** people can belong to several families and switch between them at the top of the page.
- **Privacy:** each family only ever sees its own recordings and photos, which sit in a private storage bucket. Each file can be up to 50 MB.

### How the family password is protected

- Family passwords are stored only as bcrypt hashes, in a table no one can read directly.
- Supabase checks the password inside the database, so it can't be got around by reading the page's code.
- After 8 wrong guesses in 15 minutes, joining is paused for that account.
- Changing the password doesn't remove people who already joined. To lock someone out, remove them in Family settings, then change the password.

### One-time setup (about 10 minutes)

1. **Create a project.** Sign up at supabase.com and create a project.
2. **Run the setup script.** Open **SQL Editor → New query**, paste in everything from [`supabase/setup.sql`](supabase/setup.sql), and click **Run**. It creates the tables, the password checks, the private `media` bucket and all the security rules. You can run it again safely.
3. **Set the sign-in addresses.** Go to **Authentication → URL Configuration**, set **Site URL** to `https://ninialbanini.github.io/familyArchive/`, and add the same address under **Redirect URLs**.
4. **Turn on password-only entry.** Go to **Authentication → Sign In / Providers** and switch on **Allow anonymous sign-ins**. This lets relatives come in with just the family password. People who come in this way stay signed in on that device; if they clear their browser, they type the password again. Only email accounts can start a new family.
5. **Copy your keys.** In the project's **Connect** panel, copy the Project URL and the publishable (or `anon`) key into [`config.js`](config.js), then commit. Both are safe to publish.
6. **Start your archive.** Open the site, sign in with your email and choose **Start a new one**.

If you ran the earlier single-family setup, [`supabase/cleanup-old.sql`](supabase/cleanup-old.sql) removes its old tables. That's optional.

Supabase's built-in email service only sends a few sign-in emails per hour. That's fine for a family. If it becomes a problem, connect your own email sender under **Authentication → Emails → SMTP Settings**.

## Privacy

This is family material. Don't commit chat exports, voice notes or photos to this repository, especially while it's public.
