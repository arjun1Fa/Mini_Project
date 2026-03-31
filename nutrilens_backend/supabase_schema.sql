-- ============================================================
-- NutriLens — Supabase Schema
-- Run this in the Supabase SQL editor (Dashboard → SQL Editor)
-- ============================================================

-- ── Extensions ───────────────────────────────────────────────
create extension if not exists "uuid-ossp";
create extension if not exists "pg_trgm";   -- for food name fuzzy search

-- ── 1. users ─────────────────────────────────────────────────
create table if not exists public.users (
  id                uuid        primary key references auth.users(id) on delete cascade,
  full_name         text        not null default '',
  daily_goal_kcal   integer     not null default 2000,
  plate_type        text        not null default 'standard'
                                check (plate_type in ('standard','thali','katori','side')),
  units             text        not null default 'grams'
                                check (units in ('grams','oz')),
  fcm_token         text,
  notifications_enabled boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- Auto-create user row on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.users (id, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── 2. food_nutrition ─────────────────────────────────────────
create table if not exists public.food_nutrition (
  id                  uuid    primary key default uuid_generate_v4(),
  food_name           text    not null unique,
  aliases             text[]  not null default '{}',
  calories_per_100g   float   not null,
  protein_per_100g    float   not null,
  carbs_per_100g      float   not null,
  fat_per_100g        float   not null,
  fiber_per_100g      float   not null default 0,
  sodium_per_100g     float   not null default 0,
  calcium_per_100g    float   not null default 0,
  iron_per_100g       float   not null default 0,
  shape_model         text    not null default 'spherical_cap',
  density_g_per_cm3   float   not null default 0.90,
  source              text    not null default 'IFCT2017'
);

-- Trigram index for fast fuzzy food search
create index if not exists idx_food_nutrition_name_trgm
  on public.food_nutrition using gin (food_name gin_trgm_ops);

-- ── 3. meal_logs ──────────────────────────────────────────────
create table if not exists public.meal_logs (
  id              uuid        primary key default uuid_generate_v4(),
  user_id         uuid        not null references public.users(id) on delete cascade,
  logged_at       timestamptz not null default now(),
  image_url       text        not null default '',
  items           jsonb       not null default '[]',
  total_calories  float       not null default 0,
  total_protein_g float       not null default 0,
  total_carbs_g   float       not null default 0,
  total_fat_g     float       not null default 0,
  total_fiber_g   float       not null default 0
);

create index if not exists idx_meal_logs_user_date
  on public.meal_logs (user_id, logged_at desc);

-- ── 4. Row Level Security ─────────────────────────────────────

alter table public.users          enable row level security;
alter table public.meal_logs      enable row level security;
alter table public.food_nutrition enable row level security;

-- users: only own row
create policy "users_select_own" on public.users
  for select using (auth.uid() = id);
create policy "users_update_own" on public.users
  for update using (auth.uid() = id);

-- meal_logs: only own rows
create policy "meals_select_own" on public.meal_logs
  for select using (auth.uid() = user_id);
create policy "meals_insert_own" on public.meal_logs
  for insert with check (auth.uid() = user_id);
create policy "meals_update_own" on public.meal_logs
  for update using (auth.uid() = user_id);
create policy "meals_delete_own" on public.meal_logs
  for delete using (auth.uid() = user_id);

-- food_nutrition: public read-only
create policy "food_nutrition_public_read" on public.food_nutrition
  for select using (true);

-- ── 5. Storage bucket ─────────────────────────────────────────
-- Run in Supabase Dashboard → Storage → New Bucket:
--   Name: meal-images, Public: false
-- Or via SQL (requires pg_net / storage schema access):
-- insert into storage.buckets (id, name, public) values ('meal-images', 'meal-images', false)
-- on conflict do nothing;

-- Storage RLS: authenticated users can manage their own folder
-- insert into storage.policies ... (set via Dashboard for simplicity)

-- ============================================================
-- SEED DATA — food_nutrition (IFCT 2017 values)
-- 60 Indian food classes
-- ============================================================

insert into public.food_nutrition
  (food_name, aliases, calories_per_100g, protein_per_100g, carbs_per_100g,
   fat_per_100g, fiber_per_100g, sodium_per_100g, calcium_per_100g, iron_per_100g,
   shape_model, density_g_per_cm3)
values

-- ── Rice & Grains ──────────────────────────────────────────────────────────
('rice_cooked',       '{"rice","boiled rice","steamed rice"}',             130, 2.7, 28.2, 0.3, 0.4,  1,  3,  0.2, 'spherical_cap', 0.85),
('biryani',           '{"chicken biryani","veg biryani","hyderabadi biryani"}', 163, 7.2, 24.5, 4.5, 0.8, 12, 20, 0.9, 'spherical_cap', 0.90),
('pulao',             '{"veg pulao","matar pulao"}',                       145, 3.4, 26.0, 3.2, 0.7,  8, 15, 0.7, 'spherical_cap', 0.88),
('khichdi',           '{"dal khichdi","moong khichdi"}',                   125, 5.2, 21.0, 2.5, 1.8, 10, 30, 1.2, 'spherical_cap', 0.92),
('poha',              '{"aval","beaten rice","flattened rice"}',           110, 2.4, 22.5, 0.8, 0.6,  2, 12, 0.4, 'flat_disc',     0.70),
('upma',              '{"rava upma","semolina upma"}',                     126, 2.8, 21.0, 3.5, 1.2, 15, 14, 0.7, 'spherical_cap', 0.85),
('pongal',            '{"ven pongal","khara pongal"}',                     140, 4.2, 22.0, 4.0, 1.5, 20, 18, 0.8, 'spherical_cap', 0.90),
('fried_rice',        '{"egg fried rice","veg fried rice"}',               163, 4.5, 26.0, 5.0, 0.6, 25, 10, 0.8, 'spherical_cap', 0.88),

-- ── Flatbreads ─────────────────────────────────────────────────────────────
('roti_chapati',      '{"roti","chapati","phulka","wheat roti"}',          297, 9.9, 59.4, 3.7, 1.9,  4, 23, 2.7, 'flat_disc',     0.72),
('paratha',           '{"aloo paratha","plain paratha","stuffed paratha"}',319, 7.0, 43.2,13.0, 2.1,  5, 30, 2.5, 'flat_disc',     0.75),
('puri',              '{"poori","deep fried puri"}',                       325, 7.0, 43.0,14.0, 1.8,  3, 20, 2.2, 'flat_disc',     0.60),
('bhatura',           '{"batura","fried bread"}',                          330, 8.0, 45.0,13.5, 1.6,  4, 25, 2.0, 'hemisphere',    0.55),
('naan',              '{"tandoor naan","butter naan","garlic naan"}',      310, 8.8, 49.0, 8.5, 2.0, 18, 30, 2.3, 'flat_disc',     0.68),
('kulcha',            '{"amritsari kulcha","stuffed kulcha"}',             305, 8.5, 48.0, 8.0, 2.2, 16, 28, 2.2, 'flat_disc',     0.70),
('dosa',              '{"plain dosa","masala dosa","crispy dosa"}',        168, 3.7, 25.3, 5.8, 0.7, 65, 18, 0.8, 'flat_disc',     0.55),
('uttapam',           '{"onion uttapam","vegetable uttapam"}',             155, 4.5, 24.0, 4.5, 1.2, 55, 22, 1.0, 'flat_disc',     0.65),

-- ── South Indian ───────────────────────────────────────────────────────────
('idli',              '{"idly","rice cake","steamed idli"}',                58, 1.9, 11.4, 0.4, 0.5, 30, 11, 0.4, 'hemisphere',    0.65),
('vada',              '{"medu vada","urad dal vada","donut vada"}',        205, 8.5, 22.0, 9.5, 2.5, 40, 40, 1.8, 'hemisphere',    0.70),
('sambar',            '{"lentil sambar","vegetable sambar"}',               55, 2.8,  7.5, 1.5, 2.0, 18, 30, 1.0, 'cylinder_bowl', 1.01),
('coconut_chutney',   '{"thenga chutney","white chutney"}',                184, 1.8,  5.5,17.5, 2.8,  8, 15, 0.5, 'cylinder_bowl', 1.00),
('rasam',             '{"pepper rasam","tomato rasam"}',                    18, 0.8,  2.5, 0.5, 0.4, 25, 12, 0.8, 'cylinder_bowl', 1.00),

-- ── Lentils & Pulses ───────────────────────────────────────────────────────
('dal_tadka',         '{"tarka dal","yellow dal","arhar dal"}',            119, 6.8, 16.2, 3.0, 3.5,  2, 25, 1.8, 'spherical_cap', 1.01),
('dal_makhani',       '{"black dal","urad dal makhani"}',                  160, 7.5, 18.0, 6.5, 4.2,  5, 40, 2.5, 'spherical_cap', 1.03),
('chana_masala',      '{"chickpea curry","chole masala"}',                 164, 8.9, 27.4, 2.6, 7.6, 10, 49, 2.9, 'spherical_cap', 1.02),
('chole',             '{"pindi chole","punjabi chole"}',                   164, 8.9, 27.4, 2.6, 7.6, 10, 49, 2.9, 'spherical_cap', 1.02),
('rajma',             '{"kidney bean curry","rajma chawal"}',              124, 7.0, 22.8, 0.6, 6.4,  5, 45, 2.5, 'spherical_cap', 1.02),
('moong_dal',         '{"green gram dal","moong","mung dal"}',              99, 7.0, 15.5, 0.5, 4.0,  3, 40, 1.8, 'spherical_cap', 1.00),
('sambhar_dal',       '{"toor dal","pigeon pea dal"}',                    114, 7.2, 18.0, 1.5, 3.8,  2, 28, 1.9, 'spherical_cap', 1.01),

-- ── Vegetables ─────────────────────────────────────────────────────────────
('aloo_sabzi',        '{"potato curry","dry aloo","aloo ki sabzi"}',       97, 1.8, 17.5, 2.8, 2.2,  8, 12, 0.6, 'spherical_cap', 0.95),
('palak_paneer',      '{"spinach paneer","saag paneer"}',                  156, 7.8,  6.2,11.2, 2.3, 22,185, 2.1, 'spherical_cap', 0.98),
('paneer_butter_masala','{"paneer makhani","butter paneer"}',              198,10.0,  8.5,14.5, 1.5, 30,170, 1.0, 'spherical_cap', 1.00),
('paneer',            '{"cottage cheese","fresh paneer"}',                 296,18.3,  1.2,23.5, 0.0, 20,200, 0.3, 'cuboid',        1.05),
('matar_paneer',      '{"peas paneer","mutter paneer"}',                   165, 9.0,  9.5,10.8, 2.8, 18,150, 1.4, 'spherical_cap', 0.97),
('baingan_bharta',    '{"roasted eggplant","brinjal bharta"}',              70, 2.0,  8.5, 3.0, 3.5, 10, 18, 0.5, 'spherical_cap', 0.94),
('gobi_sabzi',        '{"cauliflower curry","aloo gobi dry"}',              65, 2.5,  8.0, 2.5, 2.8, 12, 30, 0.7, 'spherical_cap', 0.80),
('bhindi_masala',     '{"okra curry","lady finger masala"}',                52, 1.8,  7.5, 2.0, 3.2, 10, 66, 0.7, 'spherical_cap', 0.88),
('aloo_gobi',         '{"potato cauliflower"}',                             80, 2.2, 12.0, 2.8, 2.5, 11, 25, 0.7, 'spherical_cap', 0.90),
('mixed_veg_curry',   '{"sabzi","mix vegetable"}',                          72, 2.0,  9.5, 3.0, 2.5, 14, 35, 0.9, 'spherical_cap', 0.93),
('saag',              '{"sarson saag","mustard leaves","saag curry"}',      60, 3.0,  6.0, 2.5, 3.0, 15, 85, 2.0, 'spherical_cap', 0.96),

-- ── Non-Vegetarian ─────────────────────────────────────────────────────────
('chicken_curry',     '{"murgh curry","chicken gravy"}',                   143,13.5,  5.4, 8.0, 0.8, 28, 25, 1.4, 'spherical_cap', 1.02),
('butter_chicken',    '{"murgh makhani","chicken makhani"}',               150,11.0,  7.0, 8.5, 1.0, 35, 30, 1.2, 'spherical_cap', 1.03),
('mutton_curry',      '{"lamb curry","gosht curry"}',                       185,16.0,  4.5,11.5, 0.5, 40, 20, 2.0, 'spherical_cap', 1.04),
('fish_curry',        '{"fish gravy","meen curry","machli curry"}',        120,16.0,  3.0, 5.5, 0.3, 50, 35, 1.0, 'spherical_cap', 1.01),
('egg_curry',         '{"anda curry","egg gravy"}',                        140, 9.5,  5.0, 9.5, 0.5, 22, 40, 1.5, 'spherical_cap', 1.00),
('tandoori_chicken',  '{"tandoor chicken","grilled chicken"}',             165,22.0,  2.5, 7.5, 0.2, 55, 15, 1.2, 'cuboid',        0.95),
('seekh_kebab',       '{"shami kebab","minced meat kebab"}',               215,18.0,  5.0,13.5, 0.8, 45, 22, 2.5, 'cuboid',        0.92),

-- ── Snacks & Street Food ───────────────────────────────────────────────────
('samosa',            '{"baked samosa","fried samosa","aloo samosa"}',     262, 5.0, 30.2,13.8, 2.0, 30, 18, 1.5, 'hemisphere',    0.68),
('pakora',            '{"bhajiya","onion pakora","vegetable pakoda"}',     208, 5.5, 22.0,11.5, 2.5, 25, 45, 1.8, 'hemisphere',    0.65),
('pani_puri',         '{"gol gappa","gup chup","puchka"}',                 165, 3.0, 28.0, 4.5, 1.5, 15, 12, 1.0, 'hemisphere',    0.55),
('bhel_puri',         '{"bhel","puffed rice snack"}',                      150, 3.5, 25.0, 4.0, 2.2, 20, 18, 1.2, 'spherical_cap', 0.60),
('aloo_tikki',        '{"potato patty","aloo pattice"}',                   195, 3.5, 28.0, 8.0, 2.8, 18, 15, 0.8, 'flat_disc',     0.78),
('dhokla',            '{"khaman dhokla","besan dhokla"}',                  140, 5.5, 22.0, 3.5, 1.2, 35, 45, 1.5, 'cuboid',        0.60),
('kachori',           '{"dal kachori","pyaaz kachori"}',                   280, 5.8, 34.0,13.5, 2.0, 20, 20, 1.8, 'hemisphere',    0.65),

-- ── Desserts ───────────────────────────────────────────────────────────────
('gulab_jamun',       '{"gulab jamun","fried milk balls"}',                337, 4.0, 51.3,12.8, 0.2, 12, 90, 0.8, 'hemisphere',    1.10),
('kheer',             '{"rice kheer","payasam","payesh"}',                 150, 3.5, 24.0, 5.0, 0.2, 15,120, 0.3, 'cylinder_bowl', 1.05),
('halwa',             '{"suji halwa","gajar halwa","moong halwa"}',        250, 3.0, 38.0, 9.5, 1.0, 10, 30, 0.8, 'spherical_cap', 1.08),
('jalebi',            '{"jilapi","imarti"}',                               349, 1.5, 65.0, 9.5, 0.2,  5, 15, 1.0, 'flat_disc',     1.12),
('rasgulla',          '{"rasogolla","sponge rasgulla"}',                   186, 3.5, 38.0, 3.0, 0.0,  8, 60, 0.4, 'hemisphere',    1.08),

-- ── Drinks ─────────────────────────────────────────────────────────────────
('lassi',             '{"sweet lassi","salted lassi","mango lassi"}',       75, 3.5, 10.0, 2.5, 0.0, 40,120, 0.1, 'cylinder_bowl', 1.02),
('chai',              '{"masala chai","tea","milk tea"}',                   40, 1.5,  5.5, 1.5, 0.0, 10, 50, 0.1, 'cylinder_bowl', 1.00)

on conflict (food_name) do update set
  aliases             = excluded.aliases,
  calories_per_100g   = excluded.calories_per_100g,
  protein_per_100g    = excluded.protein_per_100g,
  carbs_per_100g      = excluded.carbs_per_100g,
  fat_per_100g        = excluded.fat_per_100g,
  fiber_per_100g      = excluded.fiber_per_100g,
  sodium_per_100g     = excluded.sodium_per_100g,
  calcium_per_100g    = excluded.calcium_per_100g,
  iron_per_100g       = excluded.iron_per_100g,
  shape_model         = excluded.shape_model,
  density_g_per_cm3   = excluded.density_g_per_cm3;
