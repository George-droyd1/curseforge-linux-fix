#!/usr/bin/env bash
# Fix für den CurseForge-Launcher (AppImage) unter Linux:
# Login per Google/Browser endet in Firefox mit "unbekanntes Protokoll" für cfauth://.
#
# Das AppImage bringt die Protokolle in seiner eigenen .desktop-Datei mit, aber ohne
# Installation über AppImageLauncher/Gear Lever kennt das System sie nicht. Dieses Skript
# legt eine passende .desktop-Datei an und meldet CurseForge als Handler für
# cfauth://, curseforge:// und curseforge-checkout:// an. Kein sudo nötig.
#
#   ./install.sh [Pfad/zur/curseforge.AppImage]
#
# Ohne Pfad wird ~/.local/share/CurseForge/curseforge.AppImage verwendet,
# sonst die erste curseforge*.AppImage in ~/Applications oder ~/Downloads.
# --entfernen   Handler und .desktop-Datei wieder entfernen
set -euo pipefail

SCHEMES=(curseforge cfauth curseforge-checkout)
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESKTOP="$APPS/curseforge-appimage.desktop"
ICON="${XDG_DATA_HOME:-$HOME/.local/share}/icons/curseforge-appimage.png"

info() { printf '\033[1;35m==>\033[0m %s\n' "$*"; }
fehler() { printf '\033[1;31mFehler:\033[0m %s\n' "$*" >&2; exit 1; }

if [[ ${1:-} == --entfernen ]]; then
    rm -f "$DESKTOP" "$ICON"
    # mimeapps.list-Einträge auf diese .desktop-Datei entfernen
    for liste in "${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list" "$APPS/mimeapps.list"; do
        [[ -f $liste ]] && sed -i '/^x-scheme-handler\/\(curseforge\|cfauth\|curseforge-checkout\)=curseforge-appimage\.desktop;\?$/d' "$liste"
    done
    command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" || true
    info "Entfernt."
    exit 0
fi

appimage="${1:-}"
if [[ -z $appimage ]]; then
    for kandidat in "$HOME/.local/share/CurseForge/curseforge.AppImage" \
                    "$HOME"/Applications/[Cc]urse[Ff]orge*.AppImage \
                    "$HOME"/Downloads/[Cc]urse[Ff]orge*.AppImage; do
        [[ -f $kandidat ]] && { appimage="$kandidat"; break; }
    done
fi
[[ -n $appimage ]] || fehler "Keine CurseForge-AppImage gefunden. Pfad angeben: $0 /pfad/zur/curseforge.AppImage"
[[ -f $appimage ]] || fehler "$appimage gibt es nicht."
appimage="$(realpath "$appimage")"
chmod +x "$appimage"
info "AppImage: $appimage"

# Icon aus dem AppImage holen (optional). curseforge.png ist dort nur ein Symlink
# auf usr/share/icons/..., darum die echte Datei auspacken.
icon=curseforge
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
pfad=usr/share/icons/hicolor/1024x1024/apps/curseforge.png
if (cd "$tmp" && "$appimage" --appimage-extract "$pfad" >/dev/null 2>&1) && [[ -f $tmp/squashfs-root/$pfad ]]; then
    mkdir -p "$(dirname "$ICON")"
    cp "$tmp/squashfs-root/$pfad" "$ICON"
    icon="$ICON"
fi

mime=""
for s in "${SCHEMES[@]}"; do mime+="x-scheme-handler/$s;"; done

mkdir -p "$APPS"
# %U ist wichtig: so bekommt die App den cfauth://-Link mit den Login-Tokens übergeben
cat > "$DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=CurseForge
Comment=The CurseForge Electron App
Exec="$appimage" %U
Icon=$icon
Terminal=false
StartupWMClass=CurseForge
Categories=Game;
MimeType=$mime
EOF
info "Angelegt: $DESKTOP"

command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" || true
for s in "${SCHEMES[@]}"; do
    xdg-mime default "$(basename "$DESKTOP")" "x-scheme-handler/$s"
    printf '    %-20s -> %s\n' "$s://" "$(xdg-mime query default "x-scheme-handler/$s")"
done

info "Fertig. Login in CurseForge erneut starten; der Browser fragt einmal, ob er den Link mit CurseForge öffnen soll."
