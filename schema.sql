-- Rode inteiro no SQL Editor do Supabase.
create extension if not exists pgcrypto;
create table admins (
  user_id uuid primary key references auth.users on delete cascade,
  created_at timestamptz default now()
);
create table categories (
  id uuid primary key default gen_random_uuid(),
  name text not null check(char_length(name) between 2 and 60),
  slug text unique not null,
  sort int default 0
);
create table products (
  id uuid primary key default gen_random_uuid(),
  name text not null check(char_length(name) between 2 and 120),
  description text check(char_length(description)<=3000),
  brand text check(char_length(brand)<=60),
  category_id uuid references categories on delete set null,
  price numeric(10,2) not null check(price>0),
  promo_price numeric(10,2) check(promo_price is null or (promo_price>0 and promo_price<price)),
  min_stock int not null default 2 check(min_stock>=0),
  active boolean not null default true,
  featured boolean not null default false,
  is_new boolean not null default false,
  created_at timestamptz default now()
);
create table product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products on delete cascade,
  path text not null,
  sort int default 0
);
create table variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products on delete cascade,
  size text not null check(char_length(size) between 1 and 20),
  color text not null check(char_length(color) between 1 and 30),
  qty int not null default 0 check(qty>=0),
  unique(product_id,size,color)
);
create table store_settings (
  key text primary key,
  value text check(char_length(value)<=500)
);
create table audit_log (
  id bigserial primary key,
  user_id uuid,
  action text,
  detail jsonb,
  created_at timestamptz default now()
);

create function is_admin() returns boolean language sql security definer stable set search_path=public as
$$ select exists(select 1 from admins where user_id=auth.uid()) $$;

create function audit() returns trigger language plpgsql security definer set search_path=public as
$$ begin insert into audit_log(user_id,action,detail) values(auth.uid(),tg_op||' '||tg_table_name,to_jsonb(coalesce(new,old))); return coalesce(new,old); end $$;
create trigger a1
  after insert or update or delete on products for each row execute function audit();
create trigger a2
  after insert or update or delete on variants for each row execute function audit();
create trigger a3
  after insert or update or delete on categories for each row execute function audit();
create trigger a4
  after insert or update or delete on store_settings for each row execute function audit();

alter table admins enable row level security;
alter table categories enable row level security;
alter table products enable row level security;
alter table product_images enable row level security;
alter table variants enable row level security;
alter table store_settings enable row level security;
alter table audit_log enable row level security;

create policy "admin le o proprio vinculo" on admins
  for select to authenticated
  using(user_id=auth.uid());
create policy "publico le categorias" on categories
  for select
  using(true);
create policy "admin escreve categorias" on categories
  for all to authenticated
  using(is_admin())
  with check(is_admin());
create policy "publico le produtos ativos" on products
  for select
  using(active or is_admin());
create policy "admin escreve produtos" on products
  for all to authenticated
  using(is_admin())
  with check(is_admin());
create policy "publico le imagens" on product_images
  for select
  using(exists(select 1 from products p where p.id=product_id and (p.active or is_admin())));
create policy "admin escreve imagens" on product_images
  for all to authenticated
  using(is_admin())
  with check(is_admin());
create policy "publico le variacoes" on variants
  for select
  using(exists(select 1 from products p where p.id=product_id and (p.active or is_admin())));
create policy "admin escreve variacoes" on variants
  for all to authenticated
  using(is_admin())
  with check(is_admin());
create policy "publico le config" on store_settings
  for select
  using(true);
create policy "admin escreve config" on store_settings
  for all to authenticated
  using(is_admin())
  with check(is_admin());
create policy "admin le logs" on audit_log
  for select to authenticated
  using(is_admin());

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('product-images','product-images',true,5242880,array['image/jpeg','image/png','image/webp']) on conflict do nothing;
create policy "publico le imagens storage" on storage.objects
  for select
  using(bucket_id='product-images');
create policy "admin envia imagens" on storage.objects for insert to authenticated with check(bucket_id='product-images' and is_admin());
create policy "admin altera imagens" on storage.objects for update to authenticated using(bucket_id='product-images' and is_admin());
create policy "admin apaga imagens" on storage.objects for delete to authenticated using(bucket_id='product-images' and is_admin());

insert into categories(name,slug,sort) values
  ('Futebol','futebol',1),
  ('Academia','academia',2),
  ('Corrida','corrida',3),
  ('Basquete','basquete',4),
  ('Vôlei','volei',5),
  ('Boxe e lutas','boxe-lutas',6),
  ('Tênis e calçados','tenis-calcados',7),
  ('Roupas esportivas','roupas',8),
  ('Acessórios','acessorios',9),
  ('Equipamentos de treinamento','treinamento',10),
  ('Outros esportes','outros',11);
insert into store_settings(key,value) values('store_name','Dodô Esportes'),('whatsapp',''),('instagram','https://www.instagram.com/dodoesportestp/'),
('address','Pç. Cônego Vitor, 82 – Centro, Três Pontas – MG, 37190-000'),('phone','3532652905'),('show_qty','false');
