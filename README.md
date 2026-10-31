# CurseForge Linux – Login-Fix (cfauth://)

Wer den **CurseForge-Launcher als AppImage** unter Linux nutzt und sich per Google (oder einem anderen Browser-Login) anmeldet, landet im Browser auf `login-success.html`, aber der Launcher bleibt abgemeldet. Firefox meldet in der Konsole:

```
Aufruf von "cfauth://login?accessToken=…" aufgrund eines unbekannten Protokolls verhindert
```

bzw. auf Englisch:

```
Prevented navigation to "cfauth://login?accessToken=…" due to an unknown protocol.
```

## Ursache

Nach dem Login schickt die Webseite die Tokens über einen Link mit dem eigenen Protokoll `cfauth://` zurück an den Launcher. Das AppImage bringt die passende Zuordnung zwar in seiner internen `.desktop`-Datei mit (`MimeType=x-scheme-handler/cfauth;…`), aber ein AppImage wird nicht „installiert“. Ohne AppImageLauncher/Gear Lever erfährt das System also nie, dass CurseForge für `cfauth://` zuständig ist. Auch eine selbst angelegte `.desktop`-Datei hilft nur, wenn sie

1. `MimeType=x-scheme-handler/cfauth;` enthält und
2. im `Exec=` ein `%U` (bzw. `%u`) hat, damit der Link an die App übergeben wird.

## Fix (automatisch)

```bash
git clone https://github.com/George-droyd1/curseforge-linux-fix.git
cd curseforge-linux-fix
./install.sh /pfad/zur/curseforge.AppImage
```

Ohne Pfad sucht das Skript in `~/.local/share/CurseForge/`, `~/Applications/` und `~/Downloads/`. Es braucht kein sudo und

- legt `~/.local/share/applications/curseforge-appimage.desktop` an (mit `%U` und allen drei Protokollen `curseforge://`, `cfauth://`, `curseforge-checkout://`),
- holt das Icon aus dem AppImage,
- registriert CurseForge per `xdg-mime` als Standard für diese Protokolle.

Danach den Login im Launcher neu starten. Der Browser fragt einmal, ob er den Link mit CurseForge öffnen soll: „Immer …“ anhaken und „Link öffnen“.

Rückgängig machen: `./install.sh --entfernen`

## Fix (von Hand)

`~/.local/share/applications/curseforge.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=CurseForge
Exec=/pfad/zur/curseforge.AppImage %U
Icon=curseforge
Terminal=false
StartupWMClass=CurseForge
Categories=Game;
MimeType=x-scheme-handler/curseforge;x-scheme-handler/cfauth;x-scheme-handler/curseforge-checkout;
```

```bash
update-desktop-database ~/.local/share/applications
for s in curseforge cfauth curseforge-checkout; do
    xdg-mime default curseforge.desktop x-scheme-handler/$s
done
xdg-mime query default x-scheme-handler/cfauth   # -> curseforge.desktop
```

## Wenn es weiter nicht klappt

- **Firefox fragt nicht nach:** unter *Einstellungen → Allgemein → Anwendungen* nach `cfauth` suchen und dort „CurseForge“ bzw. „Systemstandard“ wählen.
- **Launcher übernimmt den Login nicht:** CurseForge ganz schließen und den Login erneut starten.
- **AppImage verschoben oder aktualisiert:** `install.sh` mit dem neuen Pfad erneut ausführen.
- **Getestet** mit CurseForge 1.325 (AppImage), Firefox 158, Arch Linux und Hyprland. Das Skript nutzt nur `xdg-mime` und `.desktop`-Dateien und sollte daher auch unter GNOME, KDE und anderen Desktops funktionieren.

---

## English (short)

**Problem:** CurseForge AppImage on Linux, Google/browser login ends on `login-success.html` and the browser says *"Prevented navigation to cfauth://… due to an unknown protocol"*.
**Cause:** the AppImage declares the `cfauth://` URL handler only in its internal `.desktop` file, which is never registered with the system.
**Fix:** `./install.sh /path/to/curseforge.AppImage` creates a `.desktop` file with `MimeType=x-scheme-handler/cfauth;…` and `Exec=… %U` and registers it via `xdg-mime` (no root needed). Then retry the login and let the browser open the link with CurseForge. Undo with `./install.sh --entfernen`.
