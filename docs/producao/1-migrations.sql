-- Migrations das specs 002, 004 e 006 para o banco de produção (Supabase).
-- Gerado a partir do commit e9ee4f3 do emprestai-api.
-- Equivale a `prisma migrate deploy`: aplica cada migration e a registra em _prisma_migrations
-- com o mesmo checksum que o Prisma calcula, para um migrate deploy futuro não reaplicar.
-- Tudo numa transação: se algo falhar, nada fica pela metade.

BEGIN;

DO $guarda$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM _prisma_migrations WHERE migration_name = '20261020021810_criar_app_info') THEN
    RAISE EXCEPTION 'Banco inesperado: a migration app_info não está registrada. Pare e avise.';
  END IF;
  IF EXISTS (SELECT 1 FROM _prisma_migrations WHERE migration_name = '20261110120000_tenants_memberships') THEN
    RAISE EXCEPTION 'As migrations novas já foram aplicadas antes. Nada a fazer.';
  END IF;
END
$guarda$;

-- ===== 20261110120000_tenants_memberships =====
-- Spec 002 · T1. Gerado com `prisma migrate diff` + SQL bruto (CHECK e RLS).

-- CreateTable
CREATE TABLE "tenants" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "slug" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "criado_em" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tenants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "memberships" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "papel" TEXT NOT NULL,
    "nome" TEXT NOT NULL,

    CONSTRAINT "memberships_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "tenants_slug_key" ON "tenants"("slug");

-- CreateIndex
CREATE INDEX "memberships_tenant_id_idx" ON "memberships"("tenant_id");

-- CreateIndex
CREATE UNIQUE INDEX "memberships_user_id_tenant_id_key" ON "memberships"("user_id", "tenant_id");

-- AddForeignKey
ALTER TABLE "memberships" ADD CONSTRAINT "memberships_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- SQL bruto: o Prisma não modela CHECK nem RLS.
ALTER TABLE "memberships" ADD CONSTRAINT "memberships_papel_check" CHECK ("papel" IN ('colaborador', 'operacoes'));

-- RLS ligado e sem policy = deny by default para as roles do Supabase (ADR-001).
-- O Prisma conecta como dono das tabelas e não é afetado (defesa em profundidade).
ALTER TABLE "tenants" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "memberships" ENABLE ROW LEVEL SECURITY;

INSERT INTO _prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, '7899f476ddd2d34cfa4dfe7f19f6fb635ceda1739f0f3e0fe6b5c0cf46b491b1', now(), '20261110120000_tenants_memberships', NULL, NULL, now(), 1);

-- ===== 20261110140000_equipamentos_emprestimos =====
-- Spec 004 · T1 e T10. Gerado com `prisma migrate diff` + SQL bruto (CHECK, unique parcial, RLS).

-- CreateTable
CREATE TABLE "equipamentos" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "nome" TEXT NOT NULL,
    "categoria" TEXT NOT NULL,
    "patrimonio" TEXT,
    "situacao" TEXT NOT NULL,
    "observacao" TEXT,
    "imagem_path" TEXT,
    "criado_em" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "equipamentos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "emprestimos" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "equipamento_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "retirada_em" DATE NOT NULL,
    "devolver_ate" DATE NOT NULL,
    "devolvido_em" DATE,
    "criado_em" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "emprestimos_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "equipamentos_tenant_id_criado_em_id_idx" ON "equipamentos"("tenant_id", "criado_em" DESC, "id" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "equipamentos_tenant_id_patrimonio_key" ON "equipamentos"("tenant_id", "patrimonio");

-- CreateIndex
CREATE INDEX "emprestimos_tenant_id_user_id_idx" ON "emprestimos"("tenant_id", "user_id");

-- AddForeignKey
ALTER TABLE "equipamentos" ADD CONSTRAINT "equipamentos_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "emprestimos" ADD CONSTRAINT "emprestimos_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "emprestimos" ADD CONSTRAINT "emprestimos_equipamento_id_fkey" FOREIGN KEY ("equipamento_id") REFERENCES "equipamentos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- SQL bruto: o Prisma não modela CHECK, índice parcial nem RLS.
ALTER TABLE "equipamentos" ADD CONSTRAINT "equipamentos_categoria_check"
  CHECK ("categoria" IN ('notebook', 'monitor', 'cabo', 'camera', 'acessorio'));
ALTER TABLE "equipamentos" ADD CONSTRAINT "equipamentos_situacao_check"
  CHECK ("situacao" IN ('disponivel', 'manutencao'));

-- Um equipamento tem no máximo um empréstimo em aberto (rede de segurança da spec 006 CA-07).
CREATE UNIQUE INDEX "emprestimos_um_aberto_por_equipamento"
  ON "emprestimos"("equipamento_id") WHERE "devolvido_em" IS NULL;
CREATE INDEX "emprestimos_abertos_por_pessoa"
  ON "emprestimos"("tenant_id", "user_id") WHERE "devolvido_em" IS NULL;

-- RLS ligado e sem policy = deny by default (ADR-001).
ALTER TABLE "equipamentos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "emprestimos" ENABLE ROW LEVEL SECURITY;

INSERT INTO _prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, 'a7bfa000b8525b81b6548d26cebe3f085e15ecf8a70ecfa6984781897bd0d93c', now(), '20261110140000_equipamentos_emprestimos', NULL, NULL, now(), 1);

-- ===== 20261110160000_auditoria =====
-- Spec 006 (emenda da prática): tabela de auditoria append-only.

-- CreateTable
CREATE TABLE "auditoria" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "ator_id" UUID NOT NULL,
    "acao" TEXT NOT NULL,
    "recurso_tipo" TEXT NOT NULL,
    "recurso_id" UUID NOT NULL,
    "dados" JSONB,
    "criado_em" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "auditoria_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "auditoria_tenant_id_criado_em_idx" ON "auditoria"("tenant_id", "criado_em" DESC);

-- AddForeignKey
ALTER TABLE "auditoria" ADD CONSTRAINT "auditoria_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- SQL bruto: append-only (ADR-001). UPDATE e DELETE são recusados pelo banco.
CREATE FUNCTION auditoria_somente_insercao() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'auditoria é append-only: % não é permitido', TG_OP;
END;
$$;
CREATE TRIGGER auditoria_append_only
  BEFORE UPDATE OR DELETE ON "auditoria"
  FOR EACH ROW EXECUTE FUNCTION auditoria_somente_insercao();

ALTER TABLE "auditoria" ENABLE ROW LEVEL SECURITY;

INSERT INTO _prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, '1bad337b8d2137504c3644b1a6a1a5c7625dce39fb1ff75e8e9695880465ebfb', now(), '20261110160000_auditoria', NULL, NULL, now(), 1);

COMMIT;

-- Conferência (deve listar as 4 migrations):
-- SELECT migration_name, finished_at FROM _prisma_migrations ORDER BY migration_name;
