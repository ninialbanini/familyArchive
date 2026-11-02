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

## Demo for presentations

Opened on its own (for example on GitHub Pages), the app runs as a **demo copy** that doesn't save. The Add page has a **Try it with a sample chat** button. It imports `demo/sample-chat.zip`, a small sample WhatsApp export, in front of the audience, so you don't need a real file on hand.

The sample has 4 voice notes and 3 photos from senders marked "(sample)". The voice notes are short plucked melodies, not real family recordings, and the photos are drawn illustrations. To use real ones, replace `demo/sample-chat.zip` with an export your family is happy to have public. The repo is public, so anything in `demo/` can be seen by anyone.

## Privacy

This is family material. Don't commit chat exports, voice notes or photos to this repository, especially while it's public.
