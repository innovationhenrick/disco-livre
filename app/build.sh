#!/bin/zsh
# Compila o "Disco Livre.app" usando o SDK ativo do macOS.
set -e
cd "${0:A:h}"
VERSAO=$(sed -n 's/^VERSAO="\(.*\)"/\1/p' ../bin/disco-livre)

SDK=$(xcrun --sdk macosx --show-sdk-path)
SWIFTC=$(xcrun --sdk macosx --find swiftc)
LIPO=$(xcrun --sdk macosx --find lipo)
ICONUTIL=${ICONUTIL:-$(command -v iconutil)}

APP="build/Disco Livre.app"
TMP="build/tmp"
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$TMP/AppIcon.iconset"

for arch in arm64 x86_64; do
  "$SWIFTC" -sdk "$SDK" -O -swift-version 5 -parse-as-library -target $arch-apple-macos13.0 \
    DiscoLivre.swift -o "$TMP/DiscoLivre-$arch"
done
"$LIPO" -create "$TMP"/DiscoLivre-* -output "$APP/Contents/MacOS/DiscoLivre"

"$SWIFTC" -sdk "$SDK" -O -swift-version 5 icone.swift -o "$TMP/icone"
"$TMP/icone" "$TMP/AppIcon.iconset"
"$ICONUTIL" -c icns "$TMP/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"

# a ferramenta e a skill vão dentro do app (autoinstalação pra quem baixa o .dmg)
cp ../bin/disco-livre "$APP/Contents/Resources/disco-livre"
cp -R ../skill/disco-livre "$APP/Contents/Resources/skill-disco-livre"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>DiscoLivre</string>
  <key>CFBundleIdentifier</key><string>com.disco-livre.app</string>
  <key>CFBundleName</key><string>Disco Livre</string>
  <key>CFBundleDisplayName</key><string>Disco Livre</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSAO</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
EOF

codesign --force --sign - "$APP"
rm -rf "$TMP"
print -r -- "✓ $APP"
