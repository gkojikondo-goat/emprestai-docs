# Plano — 001 Login

Deriva de docs/specs/001-login/spec.md.

## Restrições que este plano obedece

- docs/adr/001-stack.md — React, Vite, TypeScript strict, Tailwind, `supabase-js`, Supabase Auth
  com e-mail e senha, cadastro fechado.
- docs/layout.md — seções 1, 2, 3 e 5.1.
- rules/restrictions.md — uma tarefa por vez, sem biblioteca fora do ADR-001.

## Bibliotecas novas (todas previstas no ADR-001)

- `@supabase/supabase-js` — cliente do Supabase Auth.
- `tailwindcss` e `@tailwindcss/vite` — o ADR-001 manda Tailwind; no Tailwind atual o
  plugin do Vite é o pacote oficial que o integra ao build.

Nenhuma outra. Sem React Router (duas telas decididas por estado de sessão), sem shadcn/ui,
sem biblioteca de formulário (dois campos).

## Organização de pastas proposta

```
index.html                       link da fonte Raleway
src/
  index.css                      Tailwind e os tokens de cor/fonte do layout.md
  config/env.ts                  passa a validar também as variáveis do Supabase
  lib/supabase.ts                cria o client do Supabase
  features/
    auth/
      useSession.ts              sessão atual (getSession + onAuthStateChange)
      auth-api.ts                signIn / signOut e tradução dos erros
      LoginPage.tsx              tela de Login
      HomePage.tsx               tela Início
    health/                      já existe; a HomePage reaproveita HealthStatus
  App.tsx                        escolhe Login ou Início conforme a sessão
```

Por que essa e não outra: segue `features/<assunto>/` já usada em `health/`. `lib/` guarda o
que é infraestrutura compartilhada (o client). Só `features/auth/` é novo.

## Como cada parte será feita

- Visual (CA-11): tokens do layout.md em `@theme` do Tailwind; tela montada com classes
  utilitárias. O contorno do botão primário e o brilho radial seguem o layout.md.
- Sessão (CA-01, CA-06, CA-08): `supabase.auth.getSession()` ao abrir e
  `onAuthStateChange` para reagir a entrar e sair; o `supabase-js` guarda a sessão.
- Entrar (CA-02, CA-03, CA-05, CA-09): `signInWithPassword`; o erro "Invalid login
  credentials" vira "E-mail ou senha incorretos."; qualquer outra falha vira a mensagem de rede.
- Validação (CA-04): checagem de campo vazio antes de chamar o Supabase.
- Configuração (CA-10): `loadEnv` valida `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY`,
  no mesmo padrão de `VITE_API_URL`.

## Fora do plano

Deploy na Vercel e as variáveis do projeto do front são passos seus; estão no final de
tasks.md.
