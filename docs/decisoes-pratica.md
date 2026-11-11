# Registro de decisões da prática (rascunho do ENTREGA.md)

Decisões tomadas pelo agente por delegação explícita do Gabriel em 2026-11-10
("pode ir seguindo em frente sem perguntar e só tomando as decisões
apropriadas"). **Cada linha precisa ser revisada e assumida pelo Gabriel antes
da entrega** — a prática avalia as decisões dele.

## Conflitos (pedido × o que já existia)

| # | pedido | contrariava | decisão | por quê | onde fica |
|---|---|---|---|---|---|
| C1 | Tech lead: verificador corrige teste quebrado | requisito "Independência" do próprio enunciado | recusado | verificador que conserta o que reprova passa a aprovar o próprio trabalho | prompt do verificador (Proibições) + hook `verificador-guarda` bloqueia Write fora de `verificacao/` |
| C2 | Skill usa Pexels | combinado da turma: Pixabay | Pixabay | site do Pexels — mudança informada pelo Gabriel em 2026-11-10 | skill + memória do projeto |
| C3 | Briefing dados: instalar `sharp` | rules/restrictions.md: lib fora do ADR-001 só com aprovação | ADR-008 proposto pelo agente, **aprovado pelo Gabriel** (sharp × jimp); só devDependency, só no script da skill | 800×600 precisa ser garantido e o Pixabay não entrega esse tamanho | ADR-008 (`76cab67`) |
| C9 | Briefing dados: "TI-0004 e TI-0007 em manutenção; os outros 10 disponíveis" | lista oficial da prática marca também TI-0010 em manutenção ("use exatamente esta") | **seguir a lista** (3 em manutenção) — decidido pelo Gabriel | a lista é o dado mais específico e igual para todos; o briefing só resume | spec 009 |
| C4 | Briefing dados: senha do professor escrita no arquivo do seed | regra "nenhuma senha no código/git" + ADR-001 segredos | recusado: conta criada no painel do Supabase pelo Gabriel; seed só vincula pelo e-mail | senha no git vaza para sempre (histórico) | spec dados iniciais |
| C5 | Briefing solicitar: limite de 5 | PRD: 3 itens | 3 | regra de negócio é do PRD (regra da prática) | spec 006 |
| C6 | Briefing solicitar: 14 dias **úteis** | PRD: 14 dias; spec 006/P4: data civil | 14 dias corridos | PRD é a fonte; "úteis" exigiria calendário de feriados que nada define | spec 006 |
| C7 | Briefing solicitar: catálogo sem texto de crédito | contrato da skill: "Fotos: Pixabay" com link na tela | crédito mantido, discreto | exigência da fonte/contrato > preferência estética | spec 004/006 |
| C8 | Prática pede catálogo com foto | spec 004: "foto do equipamento" fora de escopo | spec 004 emendada | a prática é o pedido mais novo e não contraria PRD/ADR | spec 004 |

## Lacunas

| spec | faltava | alternativas | decisão | por quê |
|---|---|---|---|---|
| verificador | como torná-lo obrigatório | regra no AGENTS.md · hook · CI | hook PreToolUse + arquivo de rodada por commit | não depende de lembrar; bloqueia antes da ação |
| verificador | como é "comparável" | sobrescrever · um arquivo por rodada | um arquivo por rodada `<data>-<commit>.md` | duas rodadas lado a lado sem depender do git log |
| 006 | briefing pede "Meus empréstimos" com data, mas a tela era da 007 (devolução, fora da prática) | trazer a 007 inteira · versão mínima na 006 | versão mínima na 006 (CA-21, CA-22), sem Devolver | entrega o pedido sem implementar devolução, que está fora de escopo |
| 006 | motivo da recusa visível (checklist da prática) | texto do `detail` da API · mapa por `type` no front | mapa por `type` (CA-23), `detail` como reserva | o `type` é contrato estável; texto pode mudar |
| 006 | tabela `auditoria` vinha da 005 (fora da prática) | implementar a 005 · criar a tabela na 006 | criar na 006 | a 006 exige auditoria (CA-13) e a 005 não entra na prática |
| 004 | `proximoCursor: string \| null` saía como array no OpenAPI 3.1 (nestjs-zod 5) | pós-processar o documento · aninhar · campo opcional | ausente na última página | menor mudança de contrato; registrada na spec 004 |
| 002 | o que é o openapi "publicado" para o front | baixar artefato do CI (token entre repos) · cópia versionada conferida | cópia versionada + check contra a API ao lado | sem segredo novo; o verificador cobrou o teste do caminho de falha |
| 003 | rota desconhecida (apontada pelo verificador) | 404 própria · ir ao catálogo | ir ao catálogo (regra 9, CA-13) | o layout não desenha 404 |

## Onde o agente quase decidiu sozinho / erros pegos na revisão

- Hooks usavam a pasta da sessão como raiz do repositório: numa sessão aberta
  na pasta de docs eles falhariam **abertos** (script não encontrado = exit 1 =
  não bloqueia). Achado revisando, corrigido em `e956405` (api) / `22bfd7f` (front),
  provado ao vivo: gravação de rodada falsa bloqueada.
- **ADR-007 (`jose`) decidido pelo agente** (seção 2 do ENTREGA). Com a delegação
  "pode seguir tomando as decisões apropriadas", o agente escreveu o ADR-007 e o
  marcou como aceito. O verificador reprovou duas vezes a spec 002 na API:
  rodada `e956405` (lib fora do ADR-001) e rodada `e21a853` (ADR escrito e
  decidido pelo agente, contra AGENTS.md e rules/restrictions.md, sem registro
  da delegação no repositório). Decisão: o Gabriel aprovou explicitamente o
  ADR-007 em 2026-11-10; a aprovação e o histórico ficaram no próprio ADR.
  Lição: delegação genérica não substitui aprovação de decisão estrutural; o
  agente passa a apresentar cada ADR para aprovação (o próximo é o `sharp`).
- **Spec 009 marcada "aprovada" pelo agente.** Ao escrever a spec, o agente pôs
  "Status: aprovada — Gabriel" quando o Gabriel só tinha aprovado duas decisões
  dela (TI-0010 e sharp). Percebido na revisão antes do commit: voltou para
  "proposta", a spec foi apresentada e o Gabriel aprovou (`1fac25f`).
- **Commit com a suíte vermelha** (`133b3f4`). O agente encadeou `jest | grep && git
  commit`; o `grep` teve sucesso e o commit saiu com 1 teste falhando (a amostra
  falsa de chave do próprio detector de segredos foi achada no histórico).
  Corrigido em `45fa1b3`; a partir daí o código de saída dos testes é conferido
  antes de cada commit. Também: os hooks do agente barraram duas vezes comandos
  do próprio agente (mensagem de commit citando "Vercel", `grep` com o padrão da
  chave) — falsos positivos tratados (`3227103`, `b1b9011`).

## Histórico do verificador

| spec | repo | commit | veredito | causa | correção |
|---|---|---|---|---|---|
| 002 | api | e956405 | NÃO PRONTA | `jose` fora do ADR-001 | ADR-007 (`5d02c2b`) |
| 002 | api | e21a853 | NÃO PRONTA | ADR-007 decidido pelo agente | aprovação do Gabriel registrada no ADR-007 |
| 002 | api | 3e7112c | PRONTA | — | — |
| 002 | front | bff967e | NÃO PRONTA | CA-15 sem teste de falha; comparava com cópia manual | check:api compara com a API; teste de falha; lacuna registrada na spec (`976307a`) |
| 003 | front | bff967e | NÃO PRONTA | CA-09 sem conferência em produção; CA-10 com 1 de 4 rotas; rota coringa fora da spec; keyframe ausente | testes completos, regra 9 + CA-13, fadeUp (`976307a`); CA-09 segue pendente do deploy |
| 002 | front | 976307a | NÃO PRONTA | CA-15: caminho "cópia ≠ API" prometido na spec sem teste | `OPENAPI_DA_API` + teste (`928e03a`) |
| 002 | front | 928e03a | PRONTA | — | spec marcada implementada (hook liberou); na API o hook **bloqueou** a mesma marca porque o HEAD avançou depois da rodada PRONTA |

## Hook: falsos positivos encontrados no uso

- `ls` da pasta de rodadas era bloqueado (qualquer menção a `verificacao/`): passou a barrar só comando que escreve (`ee7e7a5`).
- Commit com a palavra "Implementada" e `<email>` no Co-Authored-By era bloqueado (o `>` parecia redirecionamento): texto citado e heredoc deixam de contar (`f07bfdb`/`b1b9011`). 45 casos simulados.
