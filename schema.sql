-- Supabase -> SQL Editor-la idha paste panni RUN pannunga.

create table if not exists public.clients (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name        text not null,
  phone       text,
  amount      numeric not null check (amount > 0),
  plan        text not null check (plan in ('weekly','monthly')),
  term        int  not null check (term >= 1),
  start_date  date not null,
  status      text not null default 'Active' check (status in ('Active','Closed','Defaulted')),
  note        text,
  created_at  timestamptz not null default now()
);

create table if not exists public.payments (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  client_id   uuid not null references public.clients(id) on delete cascade,
  amount      numeric not null check (amount > 0),
  pay_date    date not null,
  note        text,
  created_at  timestamptz not null default now()
);

create index if not exists clients_user_idx  on public.clients(user_id);
create index if not exists payments_user_idx on public.payments(user_id);
create index if not exists payments_client_idx on public.payments(client_id);

-- ROW LEVEL SECURITY (must)
alter table public.clients  enable row level security;
alter table public.payments enable row level security;

-- clients
drop policy if exists "clients_select_own" on public.clients;
drop policy if exists "clients_insert_own" on public.clients;
drop policy if exists "clients_update_own" on public.clients;
drop policy if exists "clients_delete_own" on public.clients;

create policy "clients_select_own" on public.clients
  for select to authenticated using (user_id = (select auth.uid()));
create policy "clients_insert_own" on public.clients
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy "clients_update_own" on public.clients
  for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "clients_delete_own" on public.clients
  for delete to authenticated using (user_id = (select auth.uid()));

-- payments (client-um same user-oda dhaan irukkanum)
drop policy if exists "payments_select_own" on public.payments;
drop policy if exists "payments_insert_own" on public.payments;
drop policy if exists "payments_update_own" on public.payments;
drop policy if exists "payments_delete_own" on public.payments;

create policy "payments_select_own" on public.payments
  for select to authenticated using (user_id = (select auth.uid()));
create policy "payments_insert_own" on public.payments
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (select 1 from public.clients c
                where c.id = client_id and c.user_id = (select auth.uid()))
  );
create policy "payments_update_own" on public.payments
  for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "payments_delete_own" on public.payments
  for delete to authenticated using (user_id = (select auth.uid()));

-- anon (login pannaadhavanga) access illa
revoke all on public.clients  from anon;
revoke all on public.payments from anon;
