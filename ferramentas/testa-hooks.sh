#!/usr/bin/env bash
# Testa os dois hooks contra um repositório de mentira. Uso: testa-hooks.sh <pasta-dos-hooks>
H="$1"
F="$(cygpath -m "$(mktemp -d)")"
cd "$F" || exit 1
git init -q; git config user.email t@t; git config user.name t
mkdir -p docs/specs/999-teste rules src
printf '# Spec\n\n**Status:** aprovada\n**Implementada:** não\n' > docs/specs/999-teste/spec.md
printf 'Checks:\n- `npm test`\n' > rules/checks.md
echo x > src/a.ts
git add -A; git commit -qm base
export CLAUDE_PROJECT_DIR="$F"
SPEC="$F/docs/specs/999-teste/spec.md"
EDIT_PRONTA="{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$SPEC\",\"old_string\":\"**Implementada:** não\",\"new_string\":\"**Implementada:** sim\"}}"

t() { # nome, esperado(0|2), script, json
  out=$(printf '%s' "$4" | node.exe "$H/$3" 2>&1); rc=$?
  [ "$rc" = "$2" ] && r=OK || r=FALHOU
  printf '%-7s %-62s rc=%s %s\n' "$r" "$1" "$rc" "$(echo "$out" | head -c 110)"
}
G=spec-pronta-guarda.cjs; V=verificador-guarda.cjs

echo "--- spec-pronta-guarda (projeto)"
t "marcar implementada sem rodada"              2 $G "$EDIT_PRONTA"
HEAD7=$(git rev-parse --short HEAD)
mkdir -p docs/specs/999-teste/verificacao
printf 'Spec: 999-teste\nCommit verificado: %s\n\nVeredito: NÃO PRONTA — CA-01 sem teste\n' "$HEAD7" > docs/specs/999-teste/verificacao/r1.md
t "marcar implementada com NÃO PRONTA"          2 $G "$EDIT_PRONTA"
printf 'Spec: 999-teste\nCommit verificado: 0000000\n\nVeredito: PRONTA — ok\n' > docs/specs/999-teste/verificacao/r2.md
t "marcar com PRONTA de outro commit"           2 $G "$EDIT_PRONTA"
printf 'Spec: 999-teste\nCommit verificado: %s\n\nVeredito: PRONTA — ok\n' "$HEAD7" > docs/specs/999-teste/verificacao/r3.md
echo y > src/a.ts
t "PRONTA do HEAD mas código alterado depois"   2 $G "$EDIT_PRONTA"
git checkout -q src/a.ts
t "PRONTA do HEAD e árvore limpa"               0 $G "$EDIT_PRONTA"
t "Write com Implementada: sim (mesma regra)"   0 $G "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$SPEC\",\"content\":\"**Implementada:** sim\"}}"
t "editar outra parte da spec"                  0 $G "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$SPEC\",\"old_string\":\"aprovada\",\"new_string\":\"aprovada.\"}}"
t "principal grava em verificacao/"             2 $G "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$F/docs/specs/999-teste/verificacao/falsa.md\",\"content\":\"Veredito: PRONTA\"}}"
t "verificador grava em verificacao/"           0 $G "{\"agent_type\":\"verificador-spec\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$F/docs/specs/999-teste/verificacao/r9.md\",\"content\":\"x\"}}"
t "principal: sed na marca Implementada"        2 $G '{"tool_name":"Bash","tool_input":{"command":"sed -i s/não/sim/ docs/specs/999-teste/spec.md # Implementada"}}'
t "principal: PowerShell grava em verificacao"  2 $G '{"tool_name":"PowerShell","tool_input":{"command":"Set-Content docs\\specs\\999-teste\\verificacao\\x.md PRONTA"}}'
t "principal: git add da rodada"                0 $G '{"tool_name":"Bash","tool_input":{"command":"git add docs/specs/999-teste/verificacao/r3.md"}}'
t "principal: ls da pasta de rodadas"           0 $G '{"tool_name":"Bash","tool_input":{"command":"ls docs/specs/999-teste/verificacao/ && git status --short"}}'
t "principal: cat de uma rodada"                0 $G '{"tool_name":"Bash","tool_input":{"command":"cat docs/specs/999-teste/verificacao/r1.md"}}'
t "principal: grep Implementada"                0 $G '{"tool_name":"Bash","tool_input":{"command":"grep -n Implementada docs/specs/*/spec.md"}}'
t "principal: echo > rodada"                    2 $G '{"tool_name":"Bash","tool_input":{"command":"echo Veredito: PRONTA > docs/specs/999-teste/verificacao/x.md"}}'
t "principal: rm de rodada"                     2 $G '{"tool_name":"Bash","tool_input":{"command":"rm docs/specs/999-teste/verificacao/r1.md"}}'
t "principal: node -e grava Implementada"       2 $G '{"tool_name":"Bash","tool_input":{"command":"node -e \"fs.writeFileSync(f, s.replace(/Implementada:** não/, 1))\""}}'
t "principal: commit com Implementada e <email>" 0 $G '{"tool_name":"Bash","tool_input":{"command":"git add docs && git commit -q -m \"spec marcada Implementada\n\nCo-Authored-By: X <a@b.com>\" && git log --oneline -1"}}'
t "principal: commit por heredoc com <email>"    0 $G '{"tool_name":"Bash","tool_input":{"command":"git commit -F - <<'"'"'EOF'"'"'\nImplementada sim\nCo-Authored-By: X <a@b.com>\nEOF"}}'
t "principal: echo entre aspas > spec"           2 $G '{"tool_name":"Bash","tool_input":{"command":"echo \"**Implementada:** sim\" > docs/specs/999-teste/spec.md"}}'
t "principal: comando comum"                  0 $G '{"tool_name":"Bash","tool_input":{"command":"npm run build"}}'
t "JSON inválido falha fechado"                 2 $G 'nao-e-json'

echo "--- verificador-guarda (só dentro do verificador)"
t "Write fora de verificacao/"                  2 $V "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$F/src/a.ts\",\"content\":\"x\"}}"
t "Write teste corrigido (pedido do tech lead)" 2 $V "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$F/src/a.spec.ts\",\"content\":\"x\"}}"
t "Write rodada nova"                           0 $V "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$F/docs/specs/999-teste/verificacao/nova.md\",\"content\":\"x\"}}"
t "Write sobrescreve rodada antiga"             2 $V "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$F/docs/specs/999-teste/verificacao/r1.md\",\"content\":\"x\"}}"
t "git rev-parse --short HEAD"                  0 $V '{"tool_name":"Bash","tool_input":{"command":"git rev-parse --short HEAD"}}'
t "comando do rules/checks.md"                  0 $V '{"tool_name":"Bash","tool_input":{"command":"npm test"}}'
t "git push"                                    2 $V '{"tool_name":"Bash","tool_input":{"command":"git push"}}'
t "git commit"                                  2 $V '{"tool_name":"Bash","tool_input":{"command":"git commit -am x"}}'
t "npx prisma migrate deploy"                   2 $V '{"tool_name":"Bash","tool_input":{"command":"npx prisma migrate deploy"}}'
t "npm install"                                 2 $V '{"tool_name":"Bash","tool_input":{"command":"npm install sharp"}}'
t "git status encadeado com rm"                 2 $V '{"tool_name":"Bash","tool_input":{"command":"git status; rm -rf src"}}'
t "checks + endereço de produção"               2 $V '{"tool_name":"Bash","tool_input":{"command":"npm test --url=x.supabase.co"}}'
t "Read liberado"                               0 $V '{"tool_name":"Read","tool_input":{"file_path":"src/a.ts"}}'

echo "--- sessão aberta na pasta vizinha (CLAUDE_PROJECT_DIR = pasta de docs)"
P="$(cygpath -m "$(mktemp -d)")"
export CLAUDE_PROJECT_DIR="$P"
NOME="$(basename "$F")"
REPO_REL="../$NOME"
t "verificador: cd <repo> && npm test"          0 $V "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"cd $F && npm test\"}}"
t "verificador: cd <repo> && git push"          2 $V "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"cd $F && git push\"}}"
t "verificador: npm test fora do repo"          2 $V '{"tool_name":"Bash","tool_input":{"command":"npm test"}}'
t "verificador: Write rodada no repo vizinho"   0 $V "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$F/docs/specs/999-teste/verificacao/viz.md\",\"content\":\"x\"}}"
t "verificador: Write em src do repo vizinho"   2 $V "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$F/src/b.ts\",\"content\":\"x\"}}"
t "principal: marcar implementada no vizinho"   0 $G "$EDIT_PRONTA"
printf '\n' >> src/a.ts
t "principal: idem com código sujo"             2 $G "$EDIT_PRONTA"
git checkout -q src/a.ts
t "principal: gravar rodada falsa no vizinho"   2 $G "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$F/docs/specs/999-teste/verificacao/f.md\",\"content\":\"x\"}}"
t "arquivo fora de qualquer repo: liberado"     0 $G "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$P/notas.md\",\"content\":\"x\"}}"
rm -rf "$F" "$P"
