#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────────────────
# Gera o hash BCrypt (cost=11) da senha do administrador.
# Use este hash no arquivo .env -> ADMIN_PASSWORD_HASH=...
#
# Uso: bash scripts/generate-admin-hash.sh
# ────────────────────────────────────────────────────────────────────────────
set -euo pipefail

echo "══════════════════════════════════════"
echo "  Gerador de Hash BCrypt — Admin RSVP"
echo "══════════════════════════════════════"
echo ""

read -rsp "Digite a senha do admin: " PASSWORD
echo ""
read -rsp "Confirme a senha: " PASSWORD2
echo ""

if [ "$PASSWORD" != "$PASSWORD2" ]; then
  echo "❌  As senhas não coincidem. Tente novamente."
  exit 1
fi

if [ ${#PASSWORD} -lt 8 ]; then
  echo "❌  A senha deve ter pelo menos 8 caracteres."
  exit 1
fi

# Tenta usar Python3 com bcrypt (recomendado)
if python3 -c "import bcrypt" 2>/dev/null; then
  HASH=$(python3 -c "
import bcrypt, sys
password = sys.argv[1].encode('utf-8')
hashed = bcrypt.hashpw(password, bcrypt.gensalt(rounds=11))
print(hashed.decode('utf-8'))
" "$PASSWORD")

# Fallback: htpasswd (apache2-utils)
elif command -v htpasswd &>/dev/null; then
  HASH=$(htpasswd -bnBC 11 "" "$PASSWORD" | tr -d ':\n' | sed 's/^!//')

else
  echo "❌  Instale python3-bcrypt ou apache2-utils:"
  echo "    Ubuntu/Debian: sudo apt install python3-bcrypt"
  echo "    ou: sudo apt install apache2-utils"
  exit 1
fi

echo ""
echo "✅  Hash gerado com sucesso!"
echo ""
echo "Adicione ao seu arquivo .env:"
echo "─────────────────────────────────────────────────"
echo "ADMIN_PASSWORD_HASH=${HASH}"
echo "─────────────────────────────────────────────────"
