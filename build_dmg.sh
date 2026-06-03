#!/bin/bash

set -e

APP_NAME="Antigravity Usage"
RELEASE_DIR="build/macos/Build/Products/Release"
APP_PATH="${RELEASE_DIR}/${APP_NAME}.app"
DMG_PATH="${RELEASE_DIR}/${APP_NAME}.dmg"
TEMP_DIR="build/dmg_temp"

echo "🔨 1. Compilando la aplicación en modo Release..."
flutter build macos --release

echo "🔏 2. Re-firmando el .app en profundidad (ad-hoc)..."
# Firma profunda: frameworks + ejecutable principal. Evita que macOS lo marque como roto
# al moverlo entre máquinas o tras pasar por el DMG.
codesign --force --deep --sign - "$APP_PATH"

echo "🧼 3. Quitando atributos de cuarentena del .app..."
xattr -cr "$APP_PATH" || true

echo "📂 4. Preparando el entorno para el instalador..."
rm -rf "$TEMP_DIR"
rm -f "$DMG_PATH"
mkdir -p "$TEMP_DIR"

cp -R "$APP_PATH" "$TEMP_DIR/"
ln -s /Applications "$TEMP_DIR/Applications"

# README dentro del DMG con instrucciones para el usuario final.
cat > "$TEMP_DIR/LEEME.txt" <<'EOF'
Antigravity Usage — Instalación
================================

1. Arrastra "Antigravity Usage.app" a la carpeta Applications.
2. Abre la Terminal y ejecuta UNA sola vez:

   xattr -dr com.apple.quarantine "/Applications/Antigravity Usage.app"

3. Ahora puedes abrir la app normalmente desde Launchpad o Applications.

¿Por qué este paso extra?
La app está firmada ad-hoc (sin Developer ID de Apple). macOS le añade
el atributo de cuarentena al instalarla desde un DMG y Gatekeeper la
bloquea. El comando de arriba quita esa marca solo para esta app.
EOF

echo "💿 5. Creando el instalador DMG..."
hdiutil create -fs HFS+ -srcfolder "$TEMP_DIR" -volname "$APP_NAME" "$DMG_PATH"

echo "🧼 6. Quitando atributos de cuarentena del .dmg..."
xattr -cr "$DMG_PATH" || true

echo "🧹 7. Limpiando archivos temporales..."
rm -rf "$TEMP_DIR"

echo "📦 8. Copiando el instalador DMG al directorio raíz del proyecto..."
cp "$DMG_PATH" "./${APP_NAME}.dmg"

echo ""
echo "✨ ¡Éxito! El instalador DMG está en:"
echo "👉 ./${APP_NAME}.dmg"
echo ""
echo "ℹ️  Recuerda decirle a quien instale la app que, después de copiarla a"
echo "    Applications, ejecute UNA vez en Terminal:"
echo ""
echo "    xattr -dr com.apple.quarantine \"/Applications/${APP_NAME}.app\""
echo ""
