pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "lib/binds.js" as CB
import "lib/themes.js" as Themes
import "lib/strings.js" as Strings

// The overlay: search box, modifier filters and the panels of binds.
//
// Keys: type to search, Esc clears the search and modifier filters and then
// closes, Up / Down / PgUp / PgDn scroll, Ctrl+T opens the theme picker
// (when enabled), where Up / Down preview and Enter keeps a theme.
Scope {
    id: root

    property string theme: Themes.ORDER[0]
    property string language: "en"
    property bool themePicker: true
    property bool parallax: true
    signal themePicked(string name)

    // Set while the picker highlights a theme; empty means `theme`.
    property string previewTheme: ""
    readonly property var t: Themes.get(root.previewTheme || root.theme)
    readonly property var s: Strings.get(root.language)
    property bool open: false
    property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    property var notes: []
    property bool showAll: false
    property int hiddenCount: 0
    property int modFilter: 0
    property string query: ""

    // KEYHUD_DEMO=1 shows demo/binds.json on a plain background instead of
    // your own binds and desktop, for screenshots.
    readonly property bool demo: Quickshell.env("KEYHUD_DEMO") === "1"

    readonly property int gap: 26
    readonly property int maxCols: 4

    readonly property int totalRows: {
        let n = 0;
        for (const note of root.notes)
            n += note.rows.length;
        return n;
    }
    readonly property int hitRows: {
        let n = 0;
        for (const note of root.notes)
            for (const r of note.rows)
                if (CB.matches(r, root.query, root.modFilter))
                    n++;
        return n;
    }

    function up(text) {
        return root.t.upper ? String(text).toUpperCase() : text;
    }

    function focusedScreen() {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        for (const s of Quickshell.screens)
            if (s.name === name)
                return s;
        return Quickshell.screens[0];
    }

    function openOn(screen) {
        if (screen)
            root.targetScreen = screen;
        root.query = "";
        root.modFilter = 0;
        root.open = true;
        // Read the binds every time: the config may have been reloaded.
        if (!getBinds.running)
            getBinds.running = true;
    }

    function close() {
        root.open = false;
        root.closePicker();
    }

    function closePicker() {
        picker.open = false;
        root.previewTheme = "";
    }

    function toggleOn(screen) {
        if (root.open && (!screen || screen === root.targetScreen))
            root.close();
        else
            root.openOn(screen);
    }

    function rebuild() {
        root.notes = CB.build(bindsOut.text, root.showAll, root.s.groups);
        root.hiddenCount = CB.lastHidden();
    }

    onShowAllChanged: rebuild()
    // Deferred: rebuilding inside the language change re-enters bindings that
    // read both `s` and `notes`.
    onLanguageChanged: Qt.callLater(rebuild)

    Process {
        id: getBinds
        command: root.demo ? ["cat", Quickshell.shellPath("demo/binds.json")] : ["hyprctl", "-j", "binds"]
        stdout: StdioCollector {
            id: bindsOut
            onStreamFinished: root.rebuild()
        }
    }

    // Quickshell registers PanelWindow in a way qmllint reads as uncreatable.
    PanelWindow { // qmllint disable uncreatable-type
        id: win
        screen: root.targetScreen
        visible: root.open || fade.running
        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "keyhud"

        onVisibleChanged: if (visible) Qt.callLater(() => search.forceActiveFocus())

        Item {
            id: stage
            anchors.fill: parent
            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { id: fade; duration: root.open ? 180 : 130 } }

            readonly property int cols: Math.max(1, Math.min(root.maxCols,
                Math.floor((width * 0.94 + root.gap) / (CB.NOTE_W + root.gap))))
            readonly property var layout: CB.place(root.notes, cols, root.gap)
            readonly property int gridW: cols * CB.NOTE_W + (cols - 1) * root.gap

            function scrollBy(dy) {
                flick.contentY = Math.max(0, Math.min(flick.contentY + dy, flick.contentHeight - flick.height));
            }

            Rectangle {
                visible: root.demo
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: "#2a2d34" }
                    GradientStop { position: 1; color: "#121317" }
                }
            }

            HoverHandler {
                id: pointer
            }

            Backdrop {
                anchors.fill: parent
                t: root.t
                running: root.open
                parallax: root.parallax
                aimX: pointer.hovered ? Math.max(-1, Math.min(1, pointer.point.position.x / width * 2 - 1)) : 0
                aimY: pointer.hovered ? Math.max(-1, Math.min(1, pointer.point.position.y / height * 2 - 1)) : 0
            }

            MouseArea {
                anchors.fill: parent
                onClicked: picker.open ? root.closePicker() : root.close()
                onWheel: wheel => flick.flick(0, wheel.angleDelta.y * 8)
            }

            Item {
                id: header
                width: stage.gridW
                height: 44
                anchors.horizontalCenter: parent.horizontalCenter
                // Clear of a top bar, with room to breathe.
                y: Math.round(parent.height * 0.11)

                Rectangle {
                    id: searchBox
                    width: Math.min(460, parent.width * 0.45)
                    height: parent.height
                    color: root.t.panel
                    radius: root.t.radius
                    border.width: 1.5
                    border.color: search.activeFocus ? root.t.line : root.t.dim

                    Text {
                        id: prompt
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: Strings.fill(root.t.prompt, root.s).toUpperCase()
                        color: root.t.accent
                        font.family: root.t.font
                        font.pixelSize: 17
                        font.weight: Font.Bold
                    }

                    TextInput {
                        id: search
                        anchors.left: prompt.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.t.text
                        selectionColor: root.t.dim
                        font.family: root.t.font
                        font.pixelSize: 18
                        clip: true
                        text: root.query
                        onTextChanged: root.query = text
                        cursorDelegate: Rectangle {
                            width: root.t.blockCursor ? 10 : 2
                            color: root.t.line
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: search.activeFocus
                                NumberAnimation { to: 0; duration: 450 }
                                NumberAnimation { to: 1; duration: 450 }
                            }
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_T && (event.modifiers & Qt.ControlModifier)) {
                                if (picker.open)
                                    root.closePicker();
                                else if (root.themePicker)
                                    picker.show();
                                event.accepted = true;
                                return;
                            }
                            if (picker.open) {
                                switch (event.key) {
                                case Qt.Key_Down: picker.move(1); break;
                                case Qt.Key_Up: picker.move(-1); break;
                                case Qt.Key_Return:
                                case Qt.Key_Enter: picker.accept(); break;
                                default: return;
                                }
                                event.accepted = true;
                                return;
                            }
                            switch (event.key) {
                            case Qt.Key_Down: stage.scrollBy(90); break;
                            case Qt.Key_Up: stage.scrollBy(-90); break;
                            case Qt.Key_PageDown: stage.scrollBy(flick.height * 0.8); break;
                            case Qt.Key_PageUp: stage.scrollBy(-flick.height * 0.8); break;
                            default: return;
                            }
                            event.accepted = true;
                        }
                        Keys.onEscapePressed: {
                            if (picker.open)
                                root.closePicker();
                            else if (search.text !== "")
                                search.text = "";
                            else if (root.modFilter !== 0)
                                root.modFilter = 0;
                            else
                                root.close();
                        }
                    }
                }

                Row {
                    anchors.left: searchBox.right
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Repeater {
                        model: CB.MODS
                        Chip {
                            required property var modelData
                            t: root.t
                            text: root.up(modelData[0])
                            on: (root.modFilter & modelData[1]) !== 0
                            onClicked: root.modFilter ^= modelData[1]
                        }
                    }
                    Chip {
                        t: root.t
                        text: root.showAll ? root.up(root.s.essentials) : "+" + root.hiddenCount
                        on: root.showAll
                        onClicked: root.showAll = !root.showAll
                    }
                }

                Chip {
                    id: themeButton
                    visible: root.themePicker
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    t: root.t
                    text: "◐ " + root.t.label + (picker.open ? " ▴" : " ▾")
                    on: picker.open
                    onClicked: picker.open ? root.closePicker() : picker.show()
                }

                Text {
                    id: counter
                    anchors.right: root.themePicker ? themeButton.left : parent.right
                    anchors.rightMargin: root.themePicker ? 14 : 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.hitRows + "/" + root.totalRows + " " + root.up(root.s.binds)
                    color: root.t.dim
                    font.family: root.t.font
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
            }

            Flickable {
                id: flick
                width: stage.gridW + 40
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: header.bottom
                anchors.topMargin: 22
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
                contentWidth: width
                contentHeight: stage.layout.height + 40
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Behavior on contentY { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                Repeater {
                    model: stage.layout.items
                    Panel {
                        required property var modelData
                        x: 20 + modelData.x
                        y: 14 + modelData.y
                        t: root.t
                        note: modelData.note
                        order: modelData.order
                        query: root.query
                        modFilter: root.modFilter
                        shown: root.open
                    }
                }
            }

            ThemePicker {
                id: picker
                t: root.t
                current: root.theme
                x: header.x + header.width - width
                y: header.y + header.height + 8
                onPreviewed: name => root.previewTheme = name
                onPicked: name => {
                    root.themePicked(name);
                    root.closePicker();
                }
            }

            Text {
                visible: root.notes.length === 0 || root.hitRows === 0
                anchors.centerIn: parent
                text: root.up(root.notes.length === 0 ? root.s.loading : root.s.noResults)
                color: root.t.accent
                font.family: root.t.font
                font.pixelSize: 22
                font.weight: Font.Bold
            }
        }
    }
}
