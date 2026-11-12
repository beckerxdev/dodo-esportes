# Dodô Esportes — vitrine + painel (HTML/CSS/JS + Supabase)
Site estático (sem build). Arquivos na mesma pasta: `index.html`, `admin.html`, `style.css`, `config.js`. A logo já vai embutida no `index.html`.

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

## Atualizando um banco que já existe
Se você já rodou o `schema.sql` antes, rode só o bloco **Migração** no final do arquivo (cria o campo `audience`, usado no filtro Masculino/Feminino/Infantil do menu). Sem isso, salvar produtos no painel dá erro.

## Cookies e privacidade (LGPD)
O aviso aparece na primeira visita (aceitar todos, recusar opcionais ou configurar). A escolha fica salva por 12 meses no navegador (`localStorage`, chave `dodo_cookie_consent`); depois disso o aviso volta. O link "Preferências de cookies" no rodapé reabre as opções. **Hoje o site não usa ferramentas analíticas nem de marketing.** Quando instalar alguma (Google Analytics, Meta Pixel etc.), carregue-a somente dentro de `DodoConsent.onChange((c) => { if (c.analytics) { /* carregar aqui */ } })`.

## Segurança — checklist antes de publicar
1. **Supabase → Authentication:** desative o cadastro público ("Allow new users to sign up"), exija senha forte, ative **MFA (TOTP)** para a conta da loja e, se possível, o **CAPTCHA**.
2. **SQL:** rode o `schema.sql` inteiro (inclui o bloco "ENDURECIMENTO"). Se o banco já existe, rode só esse bloco.
3. **Cabeçalhos HTTP:** publique junto o arquivo `_headers` (Netlify/Cloudflare Pages) ou `vercel.json` (Vercel). Eles bloqueiam o site dentro de iframes e limitam de onde scripts e imagens podem vir. Hospedagens simples (só upload de arquivos) não aplicam cabeçalhos; nelas vale a política `<meta>` que já está nas páginas, mas sem a proteção contra iframes.
4. **Chaves:** use só a chave `anon` no `config.js`. Nunca publique a `service_role`.
5. **Equipe:** crie um usuário por pessoa, remova quem sair (`delete from admins where user_id = '...'`) e confira o histórico em `audit_log`.
6. **Manutenção:** atualize a versão do `@supabase/supabase-js` de tempos em tempos e revise os acessos todo mês.

## Inspecionar página
O clique direito e os atalhos F12, Ctrl+Shift+I/J/C e Ctrl+U estão bloqueados nas duas páginas. Isso só desestimula o visitante comum: qualquer navegador ainda consegue ler o código público, por isso a segurança dos dados fica no banco (RLS), nunca no navegador.
