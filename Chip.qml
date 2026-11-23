import QtQuick

// A small toggle button in the HUD header.
Rectangle {
    id: root

    required property var t
    property string text: ""
    property bool on: false
    signal clicked()

    width: label.implicitWidth + 22
    height: 30
    radius: t.capRadius
    color: on ? t.line : (mouse.containsMouse ? t.faint : "transparent")
    border.width: 1.5
    border.color: on ? t.line : t.dim

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.on ? root.t.onAccent : root.t.line
        font.family: root.t.font
        font.pixelSize: 14
        font.weight: Font.Bold
        font.letterSpacing: 1
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
