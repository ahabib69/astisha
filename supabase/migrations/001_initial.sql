-- ASTISHA schema: run in Supabase SQL editor or with Supabase CLI.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default 'New member' check (char_length(display_name) between 1 and 80),
 avatar_url text,
 bio text not null default '' check (char_length(bio) <= 280),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.conversations (
 id uuid primary key default gen_random_uuid(), is_group boolean not null default false,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.conversation_participants (
 conversation_id uuid not null references public.conversations(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 joined_at timestamptz not null default now(), last_read_at timestamptz,
 primary key(conversation_id,user_id)
);
create table if not exists public.messages (
 id uuid primary key default gen_random_uuid(), conversation_id uuid not null references public.conversations(id) on delete cascade,
 sender_id uuid not null references public.profiles(id) on delete cascade,
 body text not null check(char_length(body) between 1 and 10000), created_at timestamptz not null default now(), edited_at timestamptz,
 constraint no_blank_message check (length(trim(body)) > 0)
);
create index if not exists participants_by_user on public.conversation_participants(user_id,conversation_id);
create index if not exists messages_by_conversation on public.messages(conversation_id,created_at desc,id);
create index if not exists profiles_name_search on public.profiles using gin(to_tsvector('simple',display_name));
create or replace function public.is_conversation_member(cid uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.conversation_participants where conversation_id=cid and user_id=auth.uid()) $$;
revoke all on function public.is_conversation_member(uuid) from public;
grant execute on function public.is_conversation_member(uuid) to authenticated;
alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;
create policy "authenticated users can view profile directory" on public.profiles for select to authenticated using (true);
create policy "users insert own profile" on public.profiles for insert to authenticated with check(id=auth.uid());
create policy "users update own profile" on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
create policy "participants can view conversations" on public.conversations for select to authenticated using(public.is_conversation_member(id));
create policy "authenticated users create conversation" on public.conversations for insert to authenticated with check(true);
create policy "participants view participant records" on public.conversation_participants for select to authenticated using(public.is_conversation_member(conversation_id));
-- Secure membership creation is intentionally reserved for a trusted server-side RPC/Edge Function.
-- Do not add client INSERT policy: the browser must not self-join arbitrary conversations.
create policy "members read messages" on public.messages for select to authenticated using(public.is_conversation_member(conversation_id));
create policy "members send as themselves" on public.messages for insert to authenticated with check(sender_id=auth.uid() and public.is_conversation_member(conversation_id));
create policy "sender edits own messages" on public.messages for update to authenticated using(sender_id=auth.uid() and public.is_conversation_member(conversation_id)) with check(sender_id=auth.uid() and public.is_conversation_member(conversation_id));
create policy "sender deletes own messages" on public.messages for delete to authenticated using(sender_id=auth.uid() and public.is_conversation_member(conversation_id));
-- Turn on Realtime for messages in Supabase Dashboard (Database > Publications), if not already enabled.
