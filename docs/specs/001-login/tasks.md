# Tarefas — 001 Login

Uma tarefa por vez, um commit por tarefa. Ao terminar cada uma: build passando e a
verificação abaixo.

- [x] T1 · Tailwind com os tokens do layout.md e a fonte Raleway
      atende: CA-11 (parcial)
      verifico assim: `npm run build` passa; no navegador, uma página de teste mostra o
      fundo `#161826`, o texto na cor do layout e a fonte Raleway

- [x] T2 · Variáveis do Supabase no `loadEnv` e no `.env.example`
      atende: CA-10
      verifico assim: sem `VITE_SUPABASE_URL` ou sem `VITE_SUPABASE_ANON_KEY` a página
      mostra uma mensagem que cita o nome da variável; com as duas, a aplicação carrega

- [x] T3 · Client do Supabase, hook de sessão e `App` alternando entre telas provisórias
      de Login e Início
      atende: CA-01, CA-06 (parcial)
      verifico assim: sem sessão abre a tela de Login; com uma sessão simulada abre Início

- [x] T4 · Tela de Login com o visual do layout.md 5.1 e validação dos campos vazios
      atende: CA-11, CA-04
      verifico assim: no navegador, a tela tem as duas colunas, a faixa de estatísticas e o
      botão em contorno; enviar com e-mail vazio mostra "Informe o e-mail.", com senha vazia
      mostra "Informe a senha."

- [x] T5 · Entrar de verdade: `signInWithPassword`, erros traduzidos e botão "Entrando…"
      atende: CA-03, CA-05, CA-09 e a parte "entrar" do CA-02
      verifico assim: com e-mail e senha inventados aparece "E-mail ou senha incorretos.";
      durante o envio o botão fica desabilitado; com o Supabase inacessível aparece
      "Não foi possível entrar agora. Tente novamente."

- [x] T6 · Tela Início: e-mail da pessoa, status da API e do banco e botão Sair
      atende: CA-02, CA-07, CA-08
      verifico assim: com a sessão ativa a tela mostra o e-mail e o status do `/v1/health`;
      Sair volta ao Login e recarregar a página continua no Login

- [x] T7 · Conferência de segredos e do `.gitignore`
      atende: CA-10 (apoio)
      verifico assim: `git ls-files` mostra `.env.example` e nenhum outro `.env*`; nenhuma
      chave secreta/service_role no código

- [ ] T8 · Deploy: você cadastra `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY` no projeto
      do front na Vercel e faz o redeploy
      atende: CA-02 em produção
      verifico assim: no site de produção você entra com o usuário de teste e vê a tela Início
      com o status da API e do banco

## Depois do alvo

Testes automatizados (Vitest) para CA-03, CA-04 e CA-10, citando o CA no nome do teste.
