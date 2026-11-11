-- Vincula a SUA conta de teste (crie antes no painel do Auth). Troque e-mail e nome.
BEGIN;
UPDATE auth.users
SET raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
    || jsonb_build_object('tenant_id', (SELECT id::text FROM tenants WHERE slug = 'suporte_ti'))
WHERE lower(email) = lower('gabriel.kojikondo@gmail.com');

INSERT INTO memberships (user_id, tenant_id, papel, nome)
SELECT u.id, t.id, 'colaborador', 'Gabriel Kondo'
FROM auth.users u, tenants t
WHERE lower(u.email) = lower('gabriel.kojikondo@gmail.com') AND t.slug = 'suporte_ti'
ON CONFLICT (user_id, tenant_id) DO UPDATE SET papel = EXCLUDED.papel, nome = EXCLUDED.nome;
COMMIT;
