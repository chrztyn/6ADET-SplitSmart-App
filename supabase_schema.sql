-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- PROFILES
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text not null,
  email       text not null,
  avatar_url  text,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- Auto-create profile row when a user registers
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- GROUPS 
create table if not exists public.groups (
  id           uuid primary key default uuid_generate_v4(),
  name         text not null,
  description  text default '',
  created_by   uuid not null references public.profiles(id) on delete cascade,
  created_at   timestamptz default now()
);

-- GROUP MEMBERS
create table if not exists public.group_members (
  id        uuid primary key default uuid_generate_v4(),
  group_id  uuid not null references public.groups(id) on delete cascade,
  user_id   uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz default now(),
  unique(group_id, user_id)
);

-- EXPENSE CATEGORY TYPE 
do $$ begin
  create type expense_category as enum (
    'food', 'rent', 'transport', 'utilities', 'entertainment', 'other'
  );
exception when duplicate_object then null;
end $$;

-- EXPENSES 
create table if not exists public.expenses (
  id               uuid primary key default uuid_generate_v4(),
  group_id         uuid not null references public.groups(id) on delete cascade,
  description      text not null,
  amount           numeric(12,2) not null check (amount > 0),
  paid_by_user_id  uuid not null references public.profiles(id),
  category         expense_category default 'other',
  date             date not null default current_date,
  receipt_url      text,
  created_at       timestamptz default now(),
  updated_at       timestamptz default now()
);

-- EXPENSE SPLITS
create table if not exists public.expense_splits (
  id          uuid primary key default uuid_generate_v4(),
  expense_id  uuid not null references public.expenses(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  unique(expense_id, user_id)
);

-- DEBT STATUS TYPE 
do $$ begin
  create type debt_status as enum ('pending', 'settled');
exception when duplicate_object then null;
end $$;

-- DEBTS 
create table if not exists public.debts (
  id              uuid primary key default uuid_generate_v4(),
  expense_id      uuid not null references public.expenses(id) on delete cascade,
  group_id        uuid not null references public.groups(id) on delete cascade,
  from_user_id    uuid not null references public.profiles(id),
  to_user_id      uuid not null references public.profiles(id),
  amount          numeric(12,2) not null check (amount > 0),
  paid_amount     numeric default 0,
  status          debt_status default 'pending',
  payment_method  text,
  proof_url       text,
  settled_at      timestamptz,
  created_at      timestamptz default now()
);

-- DEBT PAYMENTS
create table if not exists public.debt_payments (
  id              uuid primary key default gen_random_uuid(),
  debt_id         uuid not null references public.debts(id) on delete cascade,
  paid_by         uuid not null references public.profiles(id) on delete cascade,
  amount          numeric not null,
  payment_method  text not null,
  proof_url       text,
  created_at      timestamptz default now()
);

-- NOTIFICATION TYPE 
do $$ begin
  create type notification_type as enum ('new_expense', 'debt_settled');
exception when duplicate_object then null;
end $$;

-- NOTIFICATIONS 
create table if not exists public.notifications (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  type        notification_type not null,
  message     text not null,
  is_read     boolean default false,
  created_at  timestamptz default now()
);

-- INDEXES 
create index if not exists idx_gm_user        on public.group_members(user_id);
create index if not exists idx_gm_group       on public.group_members(group_id);
create index if not exists idx_exp_group      on public.expenses(group_id);
create index if not exists idx_exp_date       on public.expenses(date desc);
create index if not exists idx_splits_exp     on public.expense_splits(expense_id);
create index if not exists idx_debts_from     on public.debts(from_user_id);
create index if not exists idx_debts_to       on public.debts(to_user_id);
create index if not exists idx_debts_group    on public.debts(group_id, status);
create index if not exists idx_dp_debt        on public.debt_payments(debt_id);
create index if not exists idx_notif_user     on public.notifications(user_id, is_read);

-- ROW LEVEL SECURITY 
alter table public.profiles       enable row level security;
alter table public.groups         enable row level security;
alter table public.group_members  enable row level security;
alter table public.expenses       enable row level security;
alter table public.expense_splits enable row level security;
alter table public.debts          enable row level security;
alter table public.debt_payments  enable row level security;
alter table public.notifications  enable row level security;

-- Profiles
create policy "profiles_own"  on public.profiles for all    using (auth.uid() = id);
create policy "profiles_view" on public.profiles for select using (true);

-- Groups
create policy "groups_select" on public.groups for select
  using (exists (select 1 from public.group_members where group_id = groups.id and user_id = auth.uid()));
create policy "groups_insert" on public.groups for insert with check (auth.uid() = created_by);
create policy "groups_delete" on public.groups for delete using (auth.uid() = created_by);

-- Group members
create policy "gm_select" on public.group_members for select
  using (exists (select 1 from public.group_members gm2 where gm2.group_id = group_members.group_id and gm2.user_id = auth.uid()));
create policy "gm_insert" on public.group_members for insert with check (true);

-- Expenses
create policy "exp_select" on public.expenses for select
  using (exists (select 1 from public.group_members where group_id = expenses.group_id and user_id = auth.uid()));
create policy "exp_insert" on public.expenses for insert
  with check (exists (select 1 from public.group_members where group_id = expenses.group_id and user_id = auth.uid()));
create policy "exp_update" on public.expenses for update using (paid_by_user_id = auth.uid());
create policy "exp_delete" on public.expenses for delete using (paid_by_user_id = auth.uid());

-- Expense splits
create policy "splits_select" on public.expense_splits for select using (true);
create policy "splits_insert" on public.expense_splits for insert with check (true);

-- Debts
create policy "debts_select" on public.debts for select
  using (from_user_id = auth.uid() or to_user_id = auth.uid());
create policy "debts_insert" on public.debts for insert with check (true);
create policy "debts_update" on public.debts for update using (from_user_id = auth.uid());

-- Debt payments
create policy "dp_select" on public.debt_payments for select
  using (exists (select 1 from public.debts where id = debt_payments.debt_id and (from_user_id = auth.uid() or to_user_id = auth.uid())));
create policy "dp_insert" on public.debt_payments for insert with check (paid_by = auth.uid());

-- Notifications
create policy "notif_select" on public.notifications for select using (user_id = auth.uid());
create policy "notif_insert" on public.notifications for insert with check (true);
create policy "notif_update" on public.notifications for update using (user_id = auth.uid());

-- REALTIME ─
begin;
  drop publication if exists supabase_realtime;
  create publication supabase_realtime for table
    public.debts,
    public.expenses,
    public.notifications,
    public.group_members;
commit;

-- STORAGE BUCKETS 
insert into storage.buckets (id, name, public) values ('receipts', 'receipts', true) on conflict do nothing;
insert into storage.buckets (id, name, public) values ('avatars',  'avatars',  true) on conflict do nothing;

create policy "receipts_upload" on storage.objects for insert with check (bucket_id = 'receipts' and auth.role() = 'authenticated');
create policy "receipts_view"   on storage.objects for select using (bucket_id = 'receipts');
create policy "avatars_upload"  on storage.objects for insert with check (bucket_id = 'avatars' and auth.role() = 'authenticated');
create policy "avatars_view"    on storage.objects for select using (bucket_id = 'avatars');
