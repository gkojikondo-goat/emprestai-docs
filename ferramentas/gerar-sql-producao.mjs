// Gera os scripts SQL para o Gabriel colar no SQL Editor do Supabase (produção).
// Uso: node gerar-sql-producao.mjs <raiz emprestai-api> <pasta de saída>
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';

const [api, saida] = process.argv.slice(2);
mkdirSync(saida, { recursive: true });
const git = (...a) => execFileSync('git', a, { cwd: api, encoding: 'buffer' });

const NOVAS = [
  '20261110120000_tenants_memberships',
  '20261110140000_equipamentos_emprestimos',
  '20261110160000_auditoria',
];

let sql = `-- Migrations das specs 002, 004 e 006 para o banco de produção (Supabase).
-- Gerado a partir do commit ${git('rev-parse', '--short', 'HEAD').toString().trim()} do emprestai-api.
-- Equivale a \`prisma migrate deploy\`: aplica cada migration e a registra em _prisma_migrations
-- com o mesmo checksum que o Prisma calcula, para um migrate deploy futuro não reaplicar.
-- Tudo numa transação: se algo falhar, nada fica pela metade.

BEGIN;

DO $guarda$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM _prisma_migrations WHERE migration_name = '20261020021810_criar_app_info') THEN
    RAISE EXCEPTION 'Banco inesperado: a migration app_info não está registrada. Pare e avise.';
  END IF;
  IF EXISTS (SELECT 1 FROM _prisma_migrations WHERE migration_name = '${NOVAS[0]}') THEN
    RAISE EXCEPTION 'As migrations novas já foram aplicadas antes. Nada a fazer.';
  END IF;
END
$guarda$;
`;

for (const nome of NOVAS) {
  const bytes = git('show', `HEAD:prisma/migrations/${nome}/migration.sql`);
  const checksum = createHash('sha256').update(bytes).digest('hex');
  sql += `\n-- ===== ${nome} =====\n${bytes.toString('utf8')}\n`;
  sql += `INSERT INTO _prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, '${checksum}', now(), '${nome}', NULL, NULL, now(), 1);\n`;
}
sql += `\nCOMMIT;\n\n-- Conferência (deve listar as 4 migrations):\n-- SELECT migration_name, finished_at FROM _prisma_migrations ORDER BY migration_name;\n`;
writeFileSync(path.join(saida, '1-migrations.sql'), sql);

// Seed: mesma lógica de prisma/seed.ts, em SQL.
const lista = JSON.parse(git('show', 'HEAD:prisma/dados/equipamentos.json').toString('utf8'));
const creditos = JSON.parse(git('show', 'HEAD:imagens/equipamentos/creditos.json').toString('utf8'));
const q = (s) => (s === null ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);
const linhas = lista
  .map((i) => `  (${q(i.nome)}, ${q(i.categoria)}, ${q(i.patrimonio)}, ${q(i.situacao)}, ${q(creditos[i.patrimonio] ? `${i.patrimonio}.jpg` : null)})`)
  .join(',\n');

const seed = `-- Seed dos dados iniciais (spec 009) para produção. Mesma lógica de prisma/seed.ts.
-- Pode rodar quantas vezes quiser: não duplica nada e nunca cria empréstimo.
-- Rode DEPOIS do 1-migrations.sql e DEPOIS de criar a conta do professor no Auth.

BEGIN;

INSERT INTO tenants (slug, nome) VALUES ('suporte_ti', 'Suporte de TI')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO equipamentos (tenant_id, nome, categoria, patrimonio, situacao, imagem_path)
SELECT t.id, v.nome, v.categoria, v.patrimonio, v.situacao, v.imagem_path
FROM tenants t, (VALUES
${linhas}
) AS v(nome, categoria, patrimonio, situacao, imagem_path)
WHERE t.slug = 'suporte_ti'
ON CONFLICT (tenant_id, patrimonio) DO UPDATE
  SET nome = EXCLUDED.nome, categoria = EXCLUDED.categoria,
      situacao = EXCLUDED.situacao, imagem_path = EXCLUDED.imagem_path;

-- Conta do professor (criada no painel): tenant no app_metadata e vínculo como colaborador.
UPDATE auth.users
SET raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
    || jsonb_build_object('tenant_id', (SELECT id::text FROM tenants WHERE slug = 'suporte_ti'))
WHERE lower(email) = 'marcelo.grilo@institutojef.org.br';

INSERT INTO memberships (user_id, tenant_id, papel, nome)
SELECT u.id, t.id, 'colaborador', 'Marcelo Grilo'
FROM auth.users u, tenants t
WHERE lower(u.email) = 'marcelo.grilo@institutojef.org.br' AND t.slug = 'suporte_ti'
ON CONFLICT (user_id, tenant_id) DO UPDATE SET papel = EXCLUDED.papel, nome = EXCLUDED.nome;

COMMIT;

-- Conferência:
-- SELECT patrimonio, nome, situacao, imagem_path FROM equipamentos ORDER BY patrimonio;  -- 12 linhas
-- SELECT m.nome, m.papel, u.raw_app_meta_data->>'tenant_id' AS tenant
--   FROM memberships m JOIN auth.users u ON u.id = m.user_id;                             -- o professor
-- SELECT count(*) FROM emprestimos;                                                     -- 0
`;
writeFileSync(path.join(saida, '2-seed.sql'), seed);

// Vínculo de uma conta de teste (o Gabriel troca o e-mail e o nome).
writeFileSync(
  path.join(saida, '3-conta-de-teste.sql'),
  `-- Vincula a SUA conta de teste (crie antes no painel do Auth). Troque e-mail e nome.
BEGIN;
UPDATE auth.users
SET raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
    || jsonb_build_object('tenant_id', (SELECT id::text FROM tenants WHERE slug = 'suporte_ti'))
WHERE lower(email) = lower('SEU-EMAIL-DE-TESTE@exemplo.com');

INSERT INTO memberships (user_id, tenant_id, papel, nome)
SELECT u.id, t.id, 'colaborador', 'Seu Nome'
FROM auth.users u, tenants t
WHERE lower(u.email) = lower('SEU-EMAIL-DE-TESTE@exemplo.com') AND t.slug = 'suporte_ti'
ON CONFLICT (user_id, tenant_id) DO UPDATE SET papel = EXCLUDED.papel, nome = EXCLUDED.nome;
COMMIT;
`,
);
console.log('ok');
