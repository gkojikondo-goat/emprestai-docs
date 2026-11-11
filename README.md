# Emprestai — documentação e coordenação

Terceiro repositório da prática "subagentes, skills e SDD". O sistema de empréstimo de
equipamentos vive em dois repositórios (turma REST); este reúne o que fica **acima** deles: os
documentos de origem, o registro das decisões, o harness do agente e as ferramentas usadas na
entrega.

| Repositório | Conteúdo |
|---|---|
| [emprestai-api](https://github.com/gkojikondo-goat/emprestai-api) | NestJS + Prisma + Postgres (Supabase); skill `imagens-equipamentos`; specs com `[back]` |
| [emprestai-front](https://github.com/gkojikondo-goat/emprestai-front) | Vite + React; specs com `[front]` |
| este | docs de origem, decisões, ENTREGA, harness e ferramentas |

Produção: front https://emprestai-front-wine.vercel.app · API https://emprestai-api.vercel.app/v1/health

## O que tem aqui

| Caminho | O que é |
|---|---|
| `docs/ENTREGA.md` | o mesmo ENTREGA.md da raiz dos dois repositórios (tag `entrega-pratica`) |
| `docs/decisoes-pratica.md` | registro de trabalho das decisões, conflitos, lacunas e rodadas do verificador |
| `docs/PRD.md`, `docs/layout.md`, `docs/adr/001-stack.md`, `docs/stacks_i.md` | documentos de origem do projeto |
| `docs/specs/` | **versão original** das specs 001–008, escrita antes da prática. A versão vigente (com as emendas da prática, a spec 009 e as rodadas do verificador em `verificacao/`) está em cada repositório |
| `docs/producao/` | os scripts SQL aplicados pelo Gabriel no SQL Editor do Supabase (migrations com registro em `_prisma_migrations` e seed). Não contêm segredo |
| `.claude/agents/verificador-spec.md` | o subagente verificador (cópia idêntica à dos dois repositórios) |
| `.claude/hooks/`, `.claude/settings.json` | hooks `spec-pronta-guarda`, `verificador-guarda` e `producao-guarda` |
| `ferramentas/testa-hooks.sh` | os casos simulados dos hooks (`bash ferramentas/testa-hooks.sh <pasta .claude/hooks>`) |
| `ferramentas/gerar-sql-producao.mjs` | gera os scripts de `docs/producao/` a partir das migrations do git (checksum igual ao do Prisma) |
| `ferramentas/folha.mjs` | folha de contato usada na revisão visual das fotos |

## Por que três repositórios

Front e API têm ciclo de release separado (ADR-001). O que é da prática como um todo — o
verificador, os hooks, o registro de decisões e as ferramentas que não pertencem a nenhum dos
dois — ficava nesta pasta de trabalho, de onde o agente operou sobre os dois repositórios
vizinhos. Os hooks aqui descobrem o repositório pelo `.git` do arquivo editado, por isso valem
também quando a sessão é aberta nesta pasta.
