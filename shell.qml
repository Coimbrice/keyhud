// keyhud: a searchable overlay of your Hyprland binds, run as its own
// Quickshell config next to whatever shell you use.
//   qs -c keyhud                                  start it (exec-once at login)
//   qs -c keyhud ipc call keyhud toggle           open / close it
//   qs -c keyhud ipc call keyhud setTheme automata   switch theme
// Based on the cheat sheet in SekaiPop (https://github.com/Blapples/SekaiPop).
import Quickshell
import Quickshell.Io
import QtQuick
import "lib/themes.js" as Themes

ShellRoot {
    id: shell

    // From config.json; see config.example.json for what each one does.
    property string configTheme: Themes.ORDER[0]
    property bool themePicker: true
    property bool parallax: true
    property string language: "en"

    property string savedTheme: ""
    property string theme: Themes.ORDER[0]

    readonly property string home: Quickshell.env("HOME")
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/keyhud"
    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || home + "/.local/state"

    // With the picker on, the last theme picked there wins over the config
    // file; with it off, the config file is the only say.
    function applyTheme() {
        shell.theme = shell.themePicker && Themes.has(shell.savedTheme) ? shell.savedTheme : shell.configTheme;
    }

    function setTheme(name) {
        if (!Themes.has(name))
            return;
        shell.theme = name;
        shell.savedTheme = name;
        stateFile.setText(name + "\n");
    }

    FileView {
        id: configFile
        path: shell.configDir + "/config.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let c = {};
            try {
                c = JSON.parse(configFile.text()) || {};
            } catch (e) {
                console.warn("keyhud: " + path + " is not valid JSON, using defaults");
            }
            shell.configTheme = Themes.has(c.theme) ? c.theme : Themes.ORDER[0];
            shell.themePicker = c.themePicker !== false;
            shell.parallax = c.parallax !== false;
            shell.language = typeof c.language === "string" ? c.language : "en";
            shell.applyTheme();
        }
        onLoadFailed: shell.applyTheme()
    }

    FileView {
        id: stateFile
        path: shell.stateDir + "/keyhud-theme"
        printErrors: false
        onLoaded: {
            shell.savedTheme = stateFile.text().trim();
            shell.applyTheme();
        }
    }

    // Open on the monitor under the mouse, not Hyprland's focused one, which
    // only changes once something there is clicked or focused.
    Process {
        id: cursorProc
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            id: cursorOut
            onStreamFinished: sheet.toggleOn(shell.screenAt(cursorOut.text) || sheet.focusedScreen())
        }
    }

    function screenAt(json) {
        try {
            const c = JSON.parse(json);
            for (const s of Quickshell.screens)
                if (c.x >= s.x && c.x < s.x + s.width && c.y >= s.y && c.y < s.y + s.height)
                    return s;
        } catch (e) {}
        return null;
    }

    Sheet {
        id: sheet
        theme: shell.theme
        language: shell.language
        themePicker: shell.themePicker
        parallax: shell.parallax
        onThemePicked: name => shell.setTheme(name)
    }

    IpcHandler {
        target: "keyhud"

        function toggle(): void {
            if (!cursorProc.running)
                cursorProc.running = true;
        }

        function hide(): void {
            sheet.close();
        }

        function setTheme(name: string): void {
            shell.setTheme(name);
        }

        function themes(): string {
            return Themes.ORDER.join("\n");
        }
    }
}
