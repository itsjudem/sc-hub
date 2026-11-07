# Salon Cadence Hub

The Salon Cadence team hub: meeting agendas and notes, scripts and templates, the source-of-truth documents, and an updates log.

- **Website:** https://itsjudem.github.io/sc-hub
- **Data and files:** Supabase (same project as the task board). Only emails on the team list (`sc_members`) can sign in and see anything.
- **Setup:** `sc-schema.sql` (already run once) in Supabase → SQL Editor.

## Adding a teammate
1. Supabase → SQL Editor, run:
   `insert into public.sc_members (email, name) values ('their@email.com', 'Their name');`
2. Send them the website link. They type their email and tap **Email me a sign-in link**, then set a password from the menu.

## Ask your mini me
The assistant answers only from current Source of truth documents and the Updates log, with numbered sources.
- Server code: `supabase/functions/sc-assistant/index.ts` (deployed as the `sc-assistant` Edge Function).
- Needs the secret `ANTHROPIC_API_KEY` in Supabase → Edge Functions → Secrets (a key from console.anthropic.com).
- Reads notes, links (description only), .txt/.md/.csv/.json files and PDFs with selectable text. Word and Excel files: save as PDF to make them readable.
