# Salon Cadence Hub

The Salon Cadence team hub: meeting agendas and notes, scripts and templates, the source-of-truth documents, and an updates log.

- **Website:** https://itsjudem.github.io/sc-hub
- **Data and files:** Supabase (same project as the task board). Only emails on the team list (`sc_members`) can sign in and see anything.
- **Setup:** `sc-schema.sql` (already run once) in Supabase → SQL Editor.

## Adding a teammate
1. Supabase → SQL Editor, run:
   `insert into public.sc_members (email, name) values ('their@email.com', 'Their name');`
2. Send them the website link. They type their email and tap **Email me a sign-in link**, then set a password from the menu.
