-- Seed dos dados iniciais (spec 009) para produção. Mesma lógica de prisma/seed.ts.
-- Pode rodar quantas vezes quiser: não duplica nada e nunca cria empréstimo.
-- Rode DEPOIS do 1-migrations.sql e DEPOIS de criar a conta do professor no Auth.

BEGIN;

INSERT INTO tenants (slug, nome) VALUES ('suporte_ti', 'Suporte de TI')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO equipamentos (tenant_id, nome, categoria, patrimonio, situacao, imagem_path)
SELECT t.id, v.nome, v.categoria, v.patrimonio, v.situacao, v.imagem_path
FROM tenants t, (VALUES
  ('Notebook 14 polegadas', 'notebook', 'TI-0001', 'disponivel', 'TI-0001.jpg'),
  ('Notebook 15 polegadas', 'notebook', 'TI-0002', 'disponivel', 'TI-0002.jpg'),
  ('Notebook 13 polegadas', 'notebook', 'TI-0003', 'disponivel', 'TI-0003.jpg'),
  ('Notebook 15 polegadas', 'notebook', 'TI-0004', 'manutencao', 'TI-0004.jpg'),
  ('Monitor 24 polegadas', 'monitor', 'TI-0005', 'disponivel', 'TI-0005.jpg'),
  ('Monitor 27 polegadas', 'monitor', 'TI-0006', 'disponivel', 'TI-0006.jpg'),
  ('Monitor 22 polegadas', 'monitor', 'TI-0007', 'manutencao', 'TI-0007.jpg'),
  ('Cabo HDMI 2 m', 'cabo', 'TI-0008', 'disponivel', 'TI-0008.jpg'),
  ('Cabo USB-C 1 m', 'cabo', 'TI-0009', 'disponivel', 'TI-0009.jpg'),
  ('Cabo de rede 3 m', 'cabo', 'TI-0010', 'manutencao', 'TI-0010.jpg'),
  ('Webcam Full HD', 'camera', 'TI-0011', 'disponivel', 'TI-0011.jpg'),
  ('Câmera compacta', 'camera', 'TI-0012', 'disponivel', 'TI-0012.jpg')
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
