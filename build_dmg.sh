#!/bin/bash

set -euo pipefail

APP_NAME="Antigravity Usage"
RELEASE_DIR="build/macos/Build/Products/Release"
APP_PATH="${RELEASE_DIR}/${APP_NAME}.app"
DMG_PATH="${RELEASE_DIR}/${APP_NAME}.dmg"
TEMP_DIR="build/dmg_temp"
ENTITLEMENTS="macos/Runner/Release.entitlements"

echo "🔨 1. Compilando la aplicación en modo Release..."
flutter build macos --release

echo "🧼 2. Quitando atributos de cuarentena ANTES de firmar..."
xattr -cr "$APP_PATH" || true

echo "🔏 3. Firmando ad-hoc de adentro hacia afuera..."
# IMPORTANTE: NO usar `codesign --deep` para firmar. Apple lo desaconseja y con
# apps Flutter (múltiples frameworks anidados) deja el sello de App.framework
# inválido → la app pasa la verificación local pero macOS la mata al abrirla
# desde /Applications. La forma correcta es firmar inside-out: primero cada
# binario/framework anidado, y el bundle .app al final.

# 3a. Binarios Mach-O sueltos dentro de Frameworks (dylibs, helpers).
find "$APP_PATH/Contents/Frameworks" -type f \( -name "*.dylib" -o -perm +111 \) 2>/dev/null | while read -r f; do
  if file "$f" | grep -q "Mach-O"; then
    codesign --force --timestamp=none --sign - "$f"
  fi
done

# 3b. Cada .framework como bundle.
for fw in "$APP_PATH/Contents/Frameworks/"*.framework; do
  [ -d "$fw" ] && codesign --force --timestamp=none --sign - "$fw"
done

# 3c. Ejecutable principal y, por último, el bundle .app con entitlements.
codesign --force --timestamp=none --sign - "$APP_PATH/Contents/MacOS/"* 2>/dev/null || true
codesign --force --timestamp=none --entitlements "$ENTITLEMENTS" --sign - "$APP_PATH"

echo "✅ 4. Verificando la firma (falla aquí si quedó inválida)..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
echo "   Firma válida."

echo "📂 5. Preparando el entorno para el instalador..."
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
2. La PRIMERA vez, haz clic derecho sobre la app → "Abrir" → "Abrir".
   (O en Terminal, una sola vez:
    xattr -dr com.apple.quarantine "/Applications/Antigravity Usage.app")
3. A partir de ahí se abre normal desde Launchpad o Applications.

¿Por qué este paso extra?
La app está firmada ad-hoc (sin Developer ID de Apple). macOS le añade
cuarentena al descargarla y Gatekeeper pide confirmación la primera vez.
La app NO tiene icono en el Dock: vive en la barra de menú (arriba a la
derecha).
EOF

echo "💿 6. Creando el instalador DMG..."
hdiutil create -fs HFS+ -srcfolder "$TEMP_DIR" -volname "$APP_NAME" "$DMG_PATH"

echo "🧹 7. Limpiando archivos temporales..."
rm -rf "$TEMP_DIR"

echo "📦 8. Copiando el instalador DMG al directorio raíz del proyecto..."
cp "$DMG_PATH" "./${APP_NAME}.dmg"

echo ""
echo "✨ ¡Éxito! El instalador DMG está en:"
echo "👉 ./${APP_NAME}.dmg"
echo ""
echo "ℹ️  Primera apertura: clic derecho → Abrir (la app vive en la barra de menú,"
echo "    no en el Dock)."
echo ""
