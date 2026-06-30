-- RMUTSB Receipt App - Supabase central database
-- Run this file in Supabase SQL Editor.
-- Static HTML/CSS/JavaScript app stores shared app_state and uses RPC functions
-- for atomic receipt numbering when many computers issue receipts at the same time.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  role text not null check (role in ('admin', 'user')),
  username text,
  staff_code text,
  display_name text not null,
  password_hash text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists username text;
alter table public.profiles add column if not exists staff_code text;
alter table public.profiles add column if not exists display_name text;
alter table public.profiles add column if not exists password_hash text;
alter table public.profiles add column if not exists active boolean not null default true;
alter table public.profiles add column if not exists created_at timestamptz not null default now();
alter table public.profiles add column if not exists updated_at timestamptz not null default now();

create table if not exists public.app_state (
  id text primary key default 'main',
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.cancel_receipt_log (
  id uuid primary key default gen_random_uuid(),
  receipt_id text not null,
  reason text not null,
  cancelled_at timestamptz not null default now()
);

insert into public.app_state (id, data)
values (
  'main',
  '{
    "orgName": "มหาวิทยาลัยเทคโนโลยีราชมงคลสุวรรณภูมิ",
    "orgAddress": "ที่อยู่มหาวิทยาลัย / ปรับแก้ข้อความนี้ในเมนูระบบ",
    "position": "เจ้าหน้าที่ผู้รับชำระเงิน",
    "users": [
      {"code": "1001", "name": "เจ้าหน้าที่รับเงิน", "active": true}
    ],
    "titles": ["นาย", "นาง", "นางสาว", "ดร.", "อื่นๆ"],
    "items": ["ค่าลงทะเบียน", "ค่าธรรมเนียมธนาคาร", "ค่าบำรุงการศึกษา"],
    "projects": [
      {"name": "ไม่ระบุโครงการ", "active": true},
      {"name": "โครงการบริการวิชาการ", "active": true},
      {"name": "โครงการอบรมระยะสั้น", "active": true}
    ],
    "payerBanks": ["ธนาคารกรุงไทย", "ธนาคารไทยพาณิชย์", "ธนาคารกสิกรไทย", "ธนาคารกรุงเทพ"],
    "uniBanks": [
      {"id": "bank1", "bank": "ธนาคารกรุงไทย", "name": "มหาวิทยาลัยเทคโนโลยีราชมงคลสุวรรณภูมิ", "no": "000-0-00000-0", "active": true}
    ],
    "books": [
      {"id": "book1", "bookNo": "2569-001", "start": 1, "end": 500, "latest": 0, "active": true, "closed": false}
    ],
    "receipts": []
  }'::jsonb
)
on conflict (id) do nothing;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();

drop trigger if exists app_state_touch_updated_at on public.app_state;
create trigger app_state_touch_updated_at
before update on public.app_state
for each row execute function public.touch_updated_at();

alter table public.profiles enable row level security;
alter table public.app_state enable row level security;
alter table public.cancel_receipt_log enable row level security;

drop policy if exists "read app state" on public.app_state;
create policy "read app state"
on public.app_state
for select
to anon, authenticated
using (true);

drop policy if exists "insert app state" on public.app_state;
create policy "insert app state"
on public.app_state
for insert
to anon, authenticated
with check (true);

drop policy if exists "update app state" on public.app_state;
create policy "update app state"
on public.app_state
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "read profiles" on public.profiles;
create policy "read profiles"
on public.profiles
for select
to anon, authenticated
using (true);

drop policy if exists "write profiles" on public.profiles;
create policy "write profiles"
on public.profiles
for all
to anon, authenticated
using (true)
with check (true);

drop policy if exists "read cancel log" on public.cancel_receipt_log;
create policy "read cancel log"
on public.cancel_receipt_log
for select
to anon, authenticated
using (true);

drop policy if exists "insert cancel log" on public.cancel_receipt_log;
create policy "insert cancel log"
on public.cancel_receipt_log
for insert
to anon, authenticated
with check (true);

create or replace function public.issue_receipt(p_receipt jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_state jsonb;
  v_books jsonb;
  v_book jsonb;
  v_receipts jsonb;
  v_index integer;
  v_active_index integer := null;
  v_start integer;
  v_end integer;
  v_latest integer;
  v_next integer;
  v_receipt jsonb;
begin
  select data into v_state
  from public.app_state
  where id = 'main'
  for update;

  if v_state is null then
    raise exception 'ยังไม่ได้สร้าง app_state ใน Supabase';
  end if;

  v_books := coalesce(v_state->'books', '[]'::jsonb);

  if jsonb_array_length(v_books) = 0 then
    raise exception 'ยังไม่ได้กำหนดเล่มใบเสร็จ';
  end if;

  for v_index in 0..jsonb_array_length(v_books) - 1 loop
    v_book := v_books->v_index;
    if coalesce((v_book->>'active')::boolean, false)
       and not coalesce((v_book->>'closed')::boolean, false) then
      v_active_index := v_index;
      exit;
    end if;
  end loop;

  if v_active_index is null then
    raise exception 'ยังไม่มีเล่มใบเสร็จที่เปิดใช้งาน';
  end if;

  v_book := v_books->v_active_index;
  v_start := greatest(1, coalesce((v_book->>'start')::integer, 1));
  v_end := greatest(v_start, coalesce((v_book->>'end')::integer, 500));

  if v_end - v_start + 1 > 500 then
    raise exception '1 เล่มใบเสร็จต้องไม่เกิน 500 เลข';
  end if;

  v_latest := greatest(0, coalesce((v_book->>'latest')::integer, 0));
  v_next := greatest(v_start, v_latest + 1);

  if v_next > v_end then
    raise exception 'เล่มนี้ออกเลขครบแล้ว กรุณาเลือกเล่มใหม่';
  end if;

  v_books := jsonb_set(v_books, array[v_active_index::text, 'latest'], to_jsonb(v_next), false);
  v_receipt := p_receipt
    || jsonb_build_object(
      'bookNo', v_book->>'bookNo',
      'receiptNo', lpad(v_next::text, 3, '0')
    );

  v_receipts := coalesce(v_state->'receipts', '[]'::jsonb) || jsonb_build_array(v_receipt);
  v_state := jsonb_set(v_state, '{books}', v_books, true);
  v_state := jsonb_set(v_state, '{receipts}', v_receipts, true);

  update public.app_state
  set data = v_state
  where id = 'main';

  return jsonb_build_object('receipt', v_receipt, 'state', v_state);
end;
$$;

create or replace function public.cancel_receipt(p_receipt_id text, p_reason text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_state jsonb;
  v_receipts jsonb;
  v_receipt jsonb;
  v_index integer;
  v_found boolean := false;
begin
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'กรุณาระบุหมายเหตุการยกเลิก';
  end if;

  select data into v_state
  from public.app_state
  where id = 'main'
  for update;

  if v_state is null then
    raise exception 'ยังไม่ได้สร้าง app_state ใน Supabase';
  end if;

  v_receipts := coalesce(v_state->'receipts', '[]'::jsonb);

  if jsonb_array_length(v_receipts) = 0 then
    raise exception 'ไม่พบใบเสร็จในระบบ';
  end if;

  for v_index in 0..jsonb_array_length(v_receipts) - 1 loop
    v_receipt := v_receipts->v_index;
    if v_receipt->>'id' = p_receipt_id then
      v_receipt := v_receipt || jsonb_build_object(
        'status', 'ยกเลิก',
        'cancelReason', p_reason,
        'cancelledAt', now()
      );
      v_receipts := jsonb_set(v_receipts, array[v_index::text], v_receipt, false);
      v_found := true;
      exit;
    end if;
  end loop;

  if not v_found then
    raise exception 'ไม่พบใบเสร็จที่ต้องการยกเลิก';
  end if;

  insert into public.cancel_receipt_log (receipt_id, reason)
  values (p_receipt_id, p_reason);

  v_state := jsonb_set(v_state, '{receipts}', v_receipts, true);

  update public.app_state
  set data = v_state
  where id = 'main';

  return jsonb_build_object('state', v_state);
end;
$$;

grant usage on schema public to anon, authenticated;
grant select, insert, update on public.app_state to anon, authenticated;
grant select, insert, update, delete on public.profiles to anon, authenticated;
grant select, insert on public.cancel_receipt_log to anon, authenticated;
grant execute on function public.issue_receipt(jsonb) to anon, authenticated;
grant execute on function public.cancel_receipt(text, text) to anon, authenticated;

-- Security note:
-- This schema supports a static HTML app and shared database quickly.
-- For production-grade security, move login validation to Supabase Auth or an Edge Function
-- and restrict RLS policies per role instead of allowing anon write access.
