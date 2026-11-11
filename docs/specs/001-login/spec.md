# Spec — Login

**Status:** aprovada
**Implementada:** não

## Objetivo

Uma pessoa cadastrada consegue entrar no sistema com e-mail e senha, ver quem está
logada e sair.

## Vínculo

- PRD: "O que precisa existir na primeira versão", item 1 (Login). Esta spec cobre só a
  autenticação; "cada pessoa vê os próprios empréstimos" depende de funcionalidades futuras.
- ADRs que restringem: ADR-001 (Supabase Auth com e-mail e senha, cadastro fechado por
  convite, sessão gerenciada pelo `supabase-js`, Tailwind CSS, React Router não é necessário
  nesta spec).
- Visual: docs/layout.md, seções 1 (cores), 2 (tipografia), 3 (medidas) e 5.1 (Login).

## Regras

1. A autenticação é feita no Supabase Auth, por e-mail e senha, direto do front com o
   `supabase-js`. A API não participa desta spec.
2. O cadastro é fechado: não existe tela nem ação de criar conta. As contas são criadas
   por um administrador no painel do Supabase.
3. A aplicação tem duas telas: **Login** (sem sessão) e **Início** (com sessão). A tela
   Início é provisória: mostra o e-mail da pessoa logada, o status da API e do banco
   (a consulta a `/v1/health` que já existe) e o botão Sair. A tela de Login não consulta
   a API.
4. A sessão é mantida pelo `supabase-js` e sobrevive a recarregar a página.
5. A tela de Login segue o docs/layout.md seção 5.1: duas colunas (`1.05fr 0.95fr`); à
   esquerda a marca EMPREST.AI, o título em duas linhas, o texto de apoio e a faixa com as
   estatísticas "3 itens por pessoa", "14 dias de prazo" e "0 linhas para preencher", e o
   rodapé "Operações · TI interno"; à direita uma coluna de 340px com o título "Entrar", o
   texto de apoio, os campos E-mail e Senha, o botão primário de largura total e a nota
   "Cada pessoa vê apenas os próprios empréstimos".
6. Cores, tipografia (Raleway) e medidas vêm do docs/layout.md; nenhum preto puro nem
   branco puro.
7. O botão "Entrar como Operações →" do layout é atalho do protótipo e **não existe** nesta
   spec: não há papéis ainda.
8. Mensagens de erro, em português, sem exclamação:
   - credenciais inválidas: "E-mail ou senha incorretos."
   - falha de rede ou do Supabase: "Não foi possível entrar agora. Tente novamente."
   - campo vazio: "Informe o e-mail." / "Informe a senha."
9. A tela usa apenas a chave pública (anon/publishable) do Supabase, nunca a chave de serviço.

## Critérios de aceitação

- CA-01 · Sem sessão, ao abrir a aplicação, a tela de Login é exibida.
- CA-02 · Com e-mail e senha de um usuário cadastrado no Supabase, ao enviar o formulário a
  pessoa vai para a tela Início, que mostra o e-mail dela.
- CA-03 · Com e-mail ou senha incorretos, a tela de Login permanece, mostra "E-mail ou senha
  incorretos." e a pessoa continua sem sessão.
- CA-04 · Com o e-mail vazio, o formulário não é enviado e mostra "Informe o e-mail."; com a
  senha vazia, mostra "Informe a senha.".
- CA-05 · Enquanto o envio está em andamento, o botão fica desabilitado com o texto
  "Entrando…", impedindo um segundo envio.
- CA-06 · Com sessão ativa, recarregar a página mantém a pessoa na tela Início.
- CA-07 · Na tela Início, o status da API e do banco continua sendo exibido, com os mesmos
  textos e estados de erro do AZ-03 e AZ-04 do andar zero.
- CA-08 · Na tela Início, o botão Sair encerra a sessão e volta para a tela de Login; recarregar
  a página depois disso continua na tela de Login.
- CA-09 · Se o Supabase não puder ser alcançado, a tela de Login mostra "Não foi possível
  entrar agora. Tente novamente." e permanece utilizável.
- CA-10 · Se `VITE_SUPABASE_URL` ou `VITE_SUPABASE_ANON_KEY` estiverem ausentes, a aplicação
  mostra uma mensagem de configuração inválida que cita o nome da variável (mesmo padrão
  do AZ-02 do andar zero).
- CA-11 · A tela de Login usa o fundo `#161826`, a fonte Raleway e o acento `#2fb8ac` do
  docs/layout.md, com o botão primário em contorno (não preenchido).

## Fora de escopo / não decidido

- Criar conta, "esqueci a senha", troca de senha, confirmação de e-mail, login social e MFA.
- Papéis (Colaborador × Operações) e qualquer permissão.
- Rota protegida na API, validação de JWT e `/v1/me`.
- Rotas do React Router, catálogo e demais telas.
- Ficar logado entre dispositivos ou "lembrar de mim".
- shadcn/ui: entra quando houver componentes que justifiquem; esta spec usa Tailwind.
- Política de senha e bloqueio por tentativas: vêm das configurações do Supabase.

## Contrato afetado

- Nenhum endpoint da API muda.
- Chamadas ao Supabase Auth: `signInWithPassword`, `signOut`, `getSession` e
  `onAuthStateChange`.
- Novas variáveis de ambiente do front: `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY`
  (valores públicos; o `.env` continua fora do git e o `.env.example` lista os nomes).
- Não pode mudar: a chamada de `/v1/health` e a variável `VITE_API_URL`.
