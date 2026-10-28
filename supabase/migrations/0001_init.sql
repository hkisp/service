-- IDCX AI Chat — initial schema
-- Apply in Supabase SQL editor or via `supabase db push` after linking a project.
-- IMPORTANT, honest notes:
--  * profiles.id must match auth.users.id (Supabase Auth).
--  * model_configs stores NON-SENSITIVE config only. API keys must stay in
--    server env / a proper secret manager, NOT in this table.
--  * The admin check below uses a placeholder: it assumes a boolean column
--    or a claim you add yourself. Until you add that admin flag, treat the
--    "admins only" policy as a documented TODO, not as enforced admin access.
--    A common approach: add `profiles.is_admin boolean default false` and
--    update the policy to check it (see the commented example at the end).
--  * Enable RLS on every table; policies below give each user access only
--    to their own rows.

create extension if not exists pgcrypto;

-- profiles
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
create policy "users can read own profile" on public.profiles
  for select using (auth.uid() = id);
create policy "users can update own profile" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
create policy "users can insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

-- conversations
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'New conversation',
  selected_model text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_conversations_user_updated on public.conversations(user_id, updated_at desc);
alter table public.conversations enable row level security;
create policy "users can manage own conversations" on public.conversations
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- messages
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('system', 'user', 'assistant')),
  content text not null,
  model_id text,
  status text not null default 'done' check (status in ('streaming', 'done', 'error', 'aborted')),
  created_at timestamptz not null default now()
);
create index if not exists idx_messages_conversation_created on public.messages(conversation_id, created_at asc);
alter table public.messages enable row level security;
-- Ownership is enforced through the conversation's user_id as well as the
-- message's own user_id, so a user cannot read another user's conversation
-- even if they guess a message id.
create policy "users can manage own messages" on public.messages
  for all using (
    auth.uid() = user_id
    and exists (select 1 from public.conversations c where c.id = conversation_id and c.user_id = auth.uid())
  ) with check (auth.uid() = user_id);

-- model_configs (non-sensitive only)
create table if not exists public.model_configs (
  id uuid primary key default gen_random_uuid(),
  display_name text not null,
  provider_id text not null,
  provider_model_id text not null,
  enabled boolean not null default true,
  capabilities jsonb not null default '{}'::jsonb,
  default_parameters jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.model_configs enable row level security;
create policy "authenticated users can read model configs" on public.model_configs
  for select using (auth.role() = 'authenticated');
-- Writes are intentionally NOT granted to ordinary users here.
-- TODO (admin): add profiles.is_admin and replace this with a policy that
-- checks it, e.g.:
--   create policy "admins can manage model configs" on public.model_configs
--     for all using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true))
--     with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true));

-- usage_logs
create table if not exists public.usage_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  conversation_id uuid references public.conversations(id) on delete set null,
  model_id text,
  provider_id text,
  input_tokens integer,
  output_tokens integer,
  status text not null default 'success',
  latency_ms integer,
  created_at timestamptz not null default now()
);
create index if not exists idx_usage_user_created on public.usage_logs(user_id, created_at desc);
alter table public.usage_logs enable row level security;
create policy "users can read own usage logs" on public.usage_logs
  for select using (auth.uid() = user_id);
-- Inserts must come from a trusted server role (service key) after it has
-- verified the user's identity and conversation ownership; do not grant
-- direct insert to the anon/authenticated client role in production.
