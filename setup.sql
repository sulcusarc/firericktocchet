-- Fire the Taco: shared tallies
-- Paste this whole file into Supabase > SQL Editor > New query, then click Run.

create table if not exists public.counters (
  key   text primary key,
  value bigint not null default 0
);

insert into public.counters (key, value) values
  ('tacos', 0), ('suffer', 0), ('toi', 0), ('cards', 0)
on conflict (key) do nothing;

-- Anyone can read the totals; nobody can write to the table directly.
alter table public.counters enable row level security;
drop policy if exists "Anyone can read totals" on public.counters;
create policy "Anyone can read totals" on public.counters for select using (true);

-- The only way to change a total: add a small positive amount to a known key.
create or replace function public.bump(k text, n int)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  cap int;
  v bigint;
begin
  cap := case k
    when 'tacos'  then 100
    when 'suffer' then 200
    when 'toi'    then 3000
    when 'cards'  then 5
    else null end;
  if cap is null then raise exception 'unknown counter'; end if;
  if n is null or n < 1 or n > cap then raise exception 'amount out of range'; end if;
  update public.counters set value = value + n where key = k returning value into v;
  return v;
end;
$$;

revoke all on function public.bump(text, int) from public;
grant execute on function public.bump(text, int) to anon, authenticated;
