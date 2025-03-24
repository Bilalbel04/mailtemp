#!/bin/bash
# V0.1
# Obtener un dominio válido desde Mail.tm
echo "🔍 Buscando dominios disponibles..."
DOMAIN=$(curl -s "https://api.mail.tm/domains" | jq -r '.["hydra:member"] | map(.domain) | .[]' | shuf -n 1)

if [[ -z "$DOMAIN" ]]; then
    echo "❌ No se pudo obtener un dominio."
    exit 1
fi

# 2️⃣ Generar un correo aleatorio con el dominio obtenido
EMAIL="user$RANDOM@$DOMAIN"
PASSWORD="password123"

echo "📩 Correo generado: $EMAIL"

# 3️⃣ Crear cuenta en Mail.tm
echo "🔑 Registrando correo en Mail.tm..."
ACCOUNT_RESPONSE=$(curl -s -X POST "https://api.mail.tm/accounts" \
    -H "Content-Type: application/json" \
    -d "{\"address\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

if echo "$ACCOUNT_RESPONSE" | grep -q "error"; then
    echo "❌ Error al registrar el correo."
    exit 1
fi

# 4️⃣ Obtener token de sesión
echo "🔐 Obteniendo token de sesión..."
TOKEN=$(curl -s -X POST "https://api.mail.tm/token" \
    -H "Content-Type: application/json" \
    -d "{\"address\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" | jq -r '.token')

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "❌ No se pudo obtener un token."
    exit 1
fi

echo "✅ Correo registrado y listo para recibir mensajes."
echo "🔄 Monitoreando correos en tiempo real..."

# Monitorear correos en tiempo real
while true; do
    RESPONSE=$(curl -s -X GET "https://api.mail.tm/messages" \
        -H "Authorization: Bearer $TOKEN")

    if [[ "$RESPONSE" == "[]" ]]; then
        echo "⌛ No hay correos nuevos..."
    else
    echo "$RESPONSE" | jq -r '.["hydra:member"][] | "📧 De: \(.from.address)\n📌 Asunto: \(.subject)\n📅 Fecha: \(.createdAt)\n------------------------"'
    fi

    sleep 10  # Esperar 10 segundos antes de actualizar
done
