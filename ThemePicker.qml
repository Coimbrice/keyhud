pragma ComponentBehavior: Bound
import QtQuick
import "lib/themes.js" as Themes

// Dropdown under the header's theme button. Each row is drawn in its own
// theme's colors and font, so it doubles as a sample; highlighting a row
// (hover or Up / Down) previews it on the whole sheet, Enter or a click keeps
// it, Esc goes back to what was there.
Rectangle {
    id: root

    required property var t
    property string current: ""
    property int highlighted: 0
    property bool open: false

    signal previewed(string name)
    signal picked(string name)

    readonly property int count: Themes.ORDER.length

    function show() {
        root.highlighted = Math.max(0, Themes.ORDER.indexOf(root.current));
        root.open = true;
    }

    function move(step) {
        root.highlighted = (root.highlighted + step + root.count) % root.count;
        root.previewed(Themes.ORDER[root.highlighted]);
    }

    function accept() {
        root.picked(Themes.ORDER[root.highlighted]);
    }

    visible: open
    width: 260
    height: list.height + 16
    color: t.panel
    radius: t.radius
    border.width: 1.5
    border.color: t.line

    // Swallows clicks between rows so they don't reach the sheet behind,
    // which would close it.
    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: list
        x: 8
        y: 8
        width: parent.width - 16
        spacing: 6

        Repeater {
            model: Themes.ORDER

            Rectangle {
                id: row
                required property string modelData
                required property int index
                readonly property var th: Themes.get(modelData)
                readonly property bool lit: index === root.highlighted

                width: list.width
                height: 44
                color: th.panel
                radius: th.capRadius
                border.width: lit ? 2 : 1
                border.color: lit ? th.accent : th.dim

                Row {
                    id: swatches
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Repeater {
                        model: [row.th.line, row.th.accent, row.th.text]
                        Rectangle {
                            required property color modelData
                            width: 8
                            height: 22
                            color: modelData
                        }
                    }
                }

                Text {
                    anchors.left: swatches.right
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.th.label
                    color: row.th.line
                    font.family: row.th.titleFont
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    font.letterSpacing: 1
                }

                Text {
                    visible: row.modelData === root.current
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "●"
                    color: row.th.accent
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        root.highlighted = row.index;
                        root.previewed(row.modelData);
                    }
                    onClicked: root.picked(row.modelData)
                }
            }
        }
    }
}
