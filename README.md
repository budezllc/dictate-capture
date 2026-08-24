# dictate-capture

On Windows, hold a shortcut to talk into Grok Bot or Cursor. While you hold it, you can drag a gold box around part of any screen. Let go, and your words (and the screenshot, if you drew a box) land in the chat box. You press Enter when it looks right.

You can run both, or only the one you use.

| App | Hold |
| --- | --- |
| Grok Bot | Ctrl+D |
| Cursor | Ctrl+M |

Those are the same shortcuts the apps already use for talk-to-type. Click in the chat box first, then hold — a quick tap does nothing.

https://github.com/user-attachments/assets/0ba96b72-41a3-4c6f-9783-0d55209996dc

The same file is also in [docs/dictate-capture-demo.mp4](docs/dictate-capture-demo.mp4).

## What this runs on your PC

The helpers sit in the background. After install they start hidden when you sign in. Each one puts a tray icon next to the clock (G for Grok, C for Cursor). Click it, or right-click and choose Quit, to stop that helper. Double-click **Dictate Grok**, **Dictate Cursor**, or **Dictate both** on the desktop to start them again without a reboot. If those desktop files are missing, run `app\install-dictate-capture-desktop.ps1`.

They watch for Ctrl+D and Ctrl+M so extra letters do not pile into the chat. They do not save what you type.

A gold-box drag takes a picture of that area and pastes the file into chat. Leftover pictures are cleared the next time the helper starts. They do not send anything over the network.

Windows may warn about this. That is because of the shortcuts and the login start.

## Install

Windows 10 or 11. You do not need administrator.

In this folder, double-click **Install Dictate Capture.cmd**. That is the install. Double-click **Uninstall Dictate Capture.cmd** to remove it. **app** is the helpers. **tests** is checks. **streamdeck** is optional Stream Deck buttons. **docs** is the demo video. You can ignore those folders unless you need them.

Install copies the helpers for this user, starts them, turns them on at login, adds the desktop shortcuts, and lists **Dictate Capture** under Settings > Apps (Add or remove programs). After that you can delete the download folder; the running copy is the one the installer made. You can also remove it from Apps like any other program. Uninstall stops the helpers.

```powershell
git clone https://github.com/budezllc/dictate-capture.git
cd dictate-capture
powershell -NoProfile -ExecutionPolicy Bypass -File .\app\install-dictate-capture.ps1
```

If you got a ZIP instead of git, unzip it, open PowerShell in that folder, then:

```powershell
Get-ChildItem -Recurse -Filter *.ps1 | Unblock-File
Get-ChildItem -Filter *.cmd | Unblock-File
powershell -NoProfile -ExecutionPolicy Bypass -File .\app\install-dictate-capture.ps1
```

If Windows will not run **Install Dictate Capture.cmd**, right-click it, Properties, Unblock, then try again.

### One app only

After install, press Win+R, type `shell:startup`, and delete the shortcut you do not want (`dictate-grokbot-capture.cmd` or `dictate-cursor-capture.cmd`). Quit that helper from its tray icon (G or C).

### Run it yourself (no login start, no Apps entry)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\app\grokbot-capture.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\app\cursor-capture.ps1
```

Leave the window open. Close it to stop.

### Stop auto-start only

Keeps the copy on disk and does not remove it from Apps. Use Apps uninstall if you want it gone.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\app\uninstall-dictate-capture-autostart.ps1
```

If you moved the git folder and you were not using the Apps installer, run `app\install-dictate-capture-autostart.ps1` again from the new place.

## Stream Deck

Install the helpers first. In Elgato Stream Deck, import the files in **streamdeck**:

- **Dictate Grok.streamDeckAction** — brings Grok Bot forward and sends Ctrl+D
- **Dictate Cursor.streamDeckAction** — brings Cursor forward and sends Ctrl+M

Drag a file onto a key, or double-click it. If the button cannot find the app, open that step in Stream Deck and pick Grok Bot or Cursor on your PC.

## If it does not work

Hold the keys; do not tap. Click in the chat first. If Windows blocked the scripts, use the commands above, or Unblock-File after a ZIP download. If you do not see G or C next to the clock, start from the desktop shortcuts or install again. If nothing runs after a reboot, install again from the folder you kept.
