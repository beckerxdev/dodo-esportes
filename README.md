# Dodô Esportes — vitrine + painel (HTML/CSS/JS + Supabase)
Site estático (sem build). Pastas: `index.html` (vitrine), `admin.html` (painel), `config.js`, `supabase/schema.sql`, `assets/`.

## 1. Supabase
1. Crie um projeto em supabase.com.
2. SQL Editor → cole e execute `supabase/schema.sql` (tabelas, RLS, auditoria, bucket `product-images` limitado a JPG/PNG/WebP de 5 MB).
3. Authentication → Providers → Email: **desative "Allow new users to sign up"** (sem cadastro público) e ative confirmação/regras de senha fortes.
4. Authentication → URL Configuration: informe a URL do site (necessário para recuperar senha).
5. Project Settings → API: copie **URL** e **anon key** para `config.js`. Nunca use a service_role.

## 2. Primeiro administrador
1. Authentication → Users → *Add user* (e-mail + senha forte, marque "auto confirm").
2. SQL Editor (substitua o e-mail):
`insert into admins(user_id) select id from auth.users where email='SEU@EMAIL.com';`
Sem esta linha, o login é recusado e todas as escritas são bloqueadas pelo RLS.

## 3. Rodar e publicar
Local: `npx serve .` (módulos ES exigem servidor). Publicar: Netlify, Vercel ou Cloudflare Pages (pasta raiz, sem build). Painel em `/admin.html`.

## 4. Configurar a loja
No painel → Configurações: WhatsApp (55+DDD+número), Instagram, horário. Sem WhatsApp configurado, o botão avisa em vez de abrir número falso.

## 5. Trocar imagens de demonstração
Banners: `assets/hero-1.jpg`, `hero-2.jpg`, `hero-3.jpg`. Categorias: `assets/categorias/<slug>.jpg` (ex.: `futebol.jpg`). Se o arquivo não existir, aparece um fundo de cor da marca. Fotos de produtos são enviadas pelo painel.

## Segurança (resumo)
RLS em todas as tabelas; escrita só para quem está em `admins`; visitantes só leem produtos ativos; validação com CHECK no banco e no formulário; saídas escapadas (XSS); upload restrito por tipo/tamanho no bucket; log de operações em `audit_log`; bloqueio de 1 min após 5 falhas de login no painel, além do limite de requisições do próprio Supabase Auth. Nenhum sistema é invulnerável: mantenha senhas fortes e revise os acessos.
