pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "lib/binds.js" as CB

// One floating panel: a group of binds from binds.js, drawn in the active theme.
Item {
    id: root

    required property var t
    required property var note
    required property int order
    property string query: ""
    property int modFilter: 0
    property bool shown: false

    readonly property int headH: CB.HEAD_H
    readonly property int rowH: CB.ROW_H
    readonly property int hits: {
        let n = 0;
        for (const r of note.rows)
            if (CB.matches(r, query, modFilter))
                n++;
        return n;
    }

    width: CB.NOTE_W
    height: headH + note.rows.length * rowH + CB.PAD_H
    opacity: (hits > 0 ? 1 : 0.16) * appear
    Behavior on opacity { NumberAnimation { duration: 160 } }

    function up(s) {
        return root.t.upper ? String(s).toUpperCase() : s;
    }

    // Staggered appearance and an idle float.
    property real appear: 0
    property real floatY: 0
    transform: Translate { y: (1 - root.appear) * 18 + root.floatY }

    onShownChanged: {
        appearAnim.stop();
        if (shown) {
            root.appear = 0;
            appearAnim.start();
        } else {
            root.appear = 0;
        }
    }
    SequentialAnimation {
        id: appearAnim
        PauseAnimation { duration: root.order * 40 }
        NumberAnimation { target: root; property: "appear"; to: 1; duration: 260; easing.type: Easing.OutCubic }
    }
    SequentialAnimation on floatY {
        running: root.shown && root.t.float > 0
        loops: Animation.Infinite
        NumberAnimation { to: -root.t.float; duration: 2600 + root.order * 310; easing.type: Easing.InOutSine }
        NumberAnimation { to: root.t.float; duration: 2600 + root.order * 310; easing.type: Easing.InOutSine }
    }

    Canvas {
        id: frame
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.t.shadow
            // An offset shadow is a hard print-like block; no offset is a glow.
            shadowBlur: root.t.shadowX > 0 ? 0.15 : 0.9
            shadowOpacity: root.t.glow * (root.hits > 0 ? 0.8 : 0.2)
            shadowHorizontalOffset: root.t.shadowX
            shadowVerticalOffset: root.t.shadowX
            blurMax: 24
        }
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const c = root.t.cut, w = width - 1, h = height - 1;
            ctx.beginPath();
            ctx.moveTo(0.5 + c, 0.5);
            ctx.lineTo(w, 0.5);
            ctx.lineTo(w, h - c);
            ctx.lineTo(w - c, h);
            ctx.lineTo(0.5, h);
            ctx.lineTo(0.5, 0.5 + c);
            ctx.closePath();
            ctx.fillStyle = root.t.panel;
            ctx.fill();
            ctx.lineWidth = 1.5;
            ctx.strokeStyle = root.t.line;
            ctx.stroke();
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }
    onTChanged: frame.requestPaint()

    // Little corner brackets just outside the frame.
    Repeater {
        model: root.t.brackets ? 4 : 0
        Item {
            required property int index
            id: corner
            readonly property bool isRight: index % 2 === 1
            readonly property bool isBottom: index > 1
            x: isRight ? root.width - 8 + 5 : -5
            y: isBottom ? root.height - 8 + 5 : -5
            width: 8; height: 8
            Rectangle { width: 8; height: 2; color: root.t.accent; y: corner.isBottom ? 6 : 0 }
            Rectangle { width: 2; height: 8; color: root.t.accent; x: corner.isRight ? 6 : 0 }
        }
    }

    Rectangle {
        id: titleBar
        visible: root.t.bar
        x: 8; y: 8
        width: root.width - 16
        height: 26
        color: root.t.line
    }
    Text {
        x: 16 + (root.t.bar ? 0 : root.t.cut * 0.4)
        y: root.t.bar ? 11 : 10
        text: root.t.titlePrefix + root.up(root.note.title)
        color: root.t.bar ? root.t.onAccent : root.t.accent
        font.family: root.t.titleFont
        font.pixelSize: root.t.bar ? 16 : 20
        font.weight: Font.Bold
        font.letterSpacing: root.t.bar ? 1.5 : 1
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 16
        y: root.t.bar ? 12 : 13
        text: root.t.bar ? "[" + String(root.hits).padStart(2, "0") + "]" : String(root.hits).padStart(2, "0")
        color: root.t.bar ? root.t.onAccent : root.t.dim
        font.family: root.t.font
        font.pixelSize: 14
        font.weight: Font.DemiBold
    }
    // Without a title strip: a thin rule under the title, a tick at each end.
    Rectangle {
        visible: !root.t.bar
        x: 14; y: 38
        width: root.width - 28; height: 1
        color: root.t.dim
        Rectangle { width: 1; height: 5; y: -2; color: root.t.line }
        Rectangle { width: 1; height: 5; y: -2; x: parent.width - 1; color: root.t.line }
    }

    Column {
        x: 14
        y: root.headH
        width: root.width - 28

        Repeater {
            model: root.note.rows

            Item {
                id: row
                required property var modelData
                readonly property bool hit: CB.matches(modelData, root.query, root.modFilter)
                width: parent.width
                height: root.rowH
                opacity: hit ? 1 : 0.28
                Behavior on opacity { NumberAnimation { duration: 120 } }

                Row {
                    id: caps
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: row.modelData.mods.concat(row.modelData.caps)
                        Rectangle {
                            required property string modelData
                            width: Math.max(22, keyText.implicitWidth + 12)
                            height: 21
                            radius: root.t.capRadius
                            color: "transparent"
                            border.width: 1
                            border.color: row.hit ? root.t.line : root.t.dim
                            Text {
                                id: keyText
                                anchors.centerIn: parent
                                text: root.up(parent.modelData)
                                color: root.t.line
                                font.family: root.t.font
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                Text {
                    anchors.left: caps.right
                    anchors.leftMargin: 10
                    anchors.right: dupTag.visible ? dupTag.left : parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.up(row.modelData.label)
                    elide: Text.ElideRight
                    color: root.t.text
                    font.family: root.t.font
                    font.pixelSize: root.t.rowSize
                    font.weight: Font.Medium
                }

                Text {
                    id: dupTag
                    visible: !!row.modelData.dup
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.t.dupText
                    color: root.t.alert
                    font.family: root.t.font
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }
            }
        }
    }
}
