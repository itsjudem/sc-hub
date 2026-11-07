-- Salon Cadence Hub: already run once in Supabase → SQL Editor → New query → Run
-- Uses the same Supabase project as Jude's Task Board. It does not touch the task board's tables.

-- 1) Team list: only these emails can see or change anything in the hub
create table if not exists public.sc_members (
  email text primary key,
  name  text
);
insert into public.sc_members (email, name) values
  ('malasadojude@gmail.com', 'Jude'),
  ('judelyn@mysalonbooks.com', 'Jude')
on conflict (email) do nothing;

create or replace function public.is_sc_member()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.sc_members where lower(email) = lower(auth.jwt() ->> 'email'));
$$;

alter table public.sc_members enable row level security;
drop policy if exists "members see team list" on public.sc_members;
create policy "members see team list" on public.sc_members
  for select to authenticated using (public.is_sc_member());

-- 2) Everything in the hub: meetings, scripts, documents, updates
create table if not exists public.sc_items (
  id         text primary key,
  col        text not null check (col in ('meetings','scripts','docs','updates','briefs')),
  data       jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text default (auth.jwt() ->> 'email')
);
alter table public.sc_items enable row level security;
drop policy if exists "team reads and writes" on public.sc_items;
create policy "team reads and writes" on public.sc_items
  for all to authenticated using (public.is_sc_member()) with check (public.is_sc_member());

-- Live updates when someone else changes something
do $$ begin
  alter publication supabase_realtime add table public.sc_items;
exception when duplicate_object then null; end $$;

-- 3) Private file storage for uploads (PDFs, Word, Excel, WhatsApp exports…)
insert into storage.buckets (id, name, public) values ('sc-files', 'sc-files', false)
on conflict (id) do nothing;

drop policy if exists "sc files read"   on storage.objects;
drop policy if exists "sc files add"    on storage.objects;
drop policy if exists "sc files change" on storage.objects;
drop policy if exists "sc files remove" on storage.objects;
create policy "sc files read"   on storage.objects for select to authenticated using (bucket_id = 'sc-files' and public.is_sc_member());
create policy "sc files add"    on storage.objects for insert to authenticated with check (bucket_id = 'sc-files' and public.is_sc_member());
create policy "sc files change" on storage.objects for update to authenticated using (bucket_id = 'sc-files' and public.is_sc_member());
create policy "sc files remove" on storage.objects for delete to authenticated using (bucket_id = 'sc-files' and public.is_sc_member());

-- 4) Starter content (skipped if it's already there)
insert into public.sc_items (id, col, data, updated_by) values
('weekly-projections-template', 'scripts', jsonb_build_object(
  'title','Weekly projections & expenses template','category','Agenda template',
  'body', E'Review last week''s action items\nIncome projection: actuals vs projected for the month\nExpenses: new or unexpected charges\nUpdates to Income_Projection_Monthly (Google Sheets version)\nCash on hand and upcoming payments\nQuestions or decisions needed\nAction items and owners for next week',
  'createdAt', now()), 'malasadojude@gmail.com'),
('profit-first-review-template', 'scripts', jsonb_build_object(
  'title','Profit First review template','category','Agenda template',
  'body', E'Walk through Income_Projection_Monthly (Profit First Calculator)\nMonth-to-date income vs projection\nAllocations: profit, owner''s pay, tax, operating expenses\nContractor and vendor charges to review\nChanges to the projection for the coming months\nDecisions and next steps',
  'createdAt', now()), 'malasadojude@gmail.com'),
('which-projection-workbook', 'docs', jsonb_build_object(
  'title','Which projection workbook is the current one','kind','note','category','Finance & projections',
  'version','Oct–Dec 2026','status','current','description','Answers which sheet the team should update for income projections.',
  'body', E'Use the Google Sheets version of Income_Projection_Monthly (Profit First Calculator) for October to December projections. Nicole''s updates go there too.\n\nThe older Excel copy is no longer the one to update.\n\nSC Relay Balances is a newer sheet, but Income_Projection_Monthly stays the main workbook for reviews with Ronit because it''s easier to read together.',
  'createdAt', now()), 'malasadojude@gmail.com'),
('hub-launched', 'updates', jsonb_build_object(
  'title','Salon Cadence Hub is live','date','2026-11-07',
  'body','Meeting agendas, scripts and source-of-truth documents for Salon Cadence now live here. Check Source of truth before using a document so you have the current version.',
  'docId','', 'createdAt', now()), 'malasadojude@gmail.com')
on conflict (id) do nothing;

-- To add a teammate later, run (with their email):
--   insert into public.sc_members (email, name) values ('their@email.com', 'Their name');
