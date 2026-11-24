pragma ComponentBehavior: Bound
import QtQuick

// Full-screen layer behind the panels. Alien: CRT scanlines, a slow scan bar
// and a faint flicker. Jurassic: a topographic contour map with a grid.
// Automata: ruled paper with a dot grid and a slow reading line.
Item {
    id: root

    required property var t
    property bool running: false
    property bool parallax: true
    // How far (px) the backdrop drifts; the theme sets it, the config can zero it.
    readonly property real depth: parallax ? t.parallax : 0

    // Pointer over the sheet, -1..1 on each axis; 0 when it is elsewhere
    // (another monitor), so the backdrop settles back to the middle.
    property real aimX: 0
    property real aimY: 0

    // Two chained lerps: `lag` eases toward the pointer and `drift` follows
    // `lag`, so the motion starts and stops softly and never overshoots.
    property real lagX: 0
    property real lagY: 0
    property real driftX: 0
    property real driftY: 0
    readonly property bool settled: Math.abs(aimX - driftX) < 0.001 && Math.abs(aimY - driftY) < 0.001

    FrameAnimation {
        running: root.running && root.depth > 0 && !root.settled
        onTriggered: {
            // Same speed at any refresh rate: about 2% of the gap is left per second.
            const k = 1 - Math.pow(0.02, frameTime);
            root.lagX += (root.aimX - root.lagX) * k;
            root.lagY += (root.aimY - root.lagY) * k;
            root.driftX += (root.lagX - root.driftX) * k;
            root.driftY += (root.lagY - root.driftY) * k;
        }
    }

    onTChanged: {
        contours.requestPaint();
        sweep.requestPaint();
        scan.requestPaint();
        paper.requestPaint();
    }

    Rectangle {
        anchors.fill: parent
        color: root.t.backdrop
    }

    // Jurassic: contour map.
    // The map is the far layer: it drifts half as much as the range ring and
    // overhangs the screen by the full amount, so its edges never show.
    Canvas {
        id: contours
        anchors.fill: parent
        anchors.margins: -root.depth
        visible: root.t.contours
        transform: Translate {
            x: -root.driftX * root.depth * 0.5
            y: -root.driftY * root.depth * 0.5
        }
        opacity: 0.55
        renderStrategy: Canvas.Cooperative
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()

        // Wobbly closed rings around a centre: a few sine terms make them
        // read as terrain instead of circles.
        function ring(ctx, cx, cy, r, seed) {
            ctx.beginPath();
            for (let i = 0; i <= 120; i++) {
                const a = i / 120 * Math.PI * 2;
                const w = 1 + 0.16 * Math.sin(a * 3 + seed) + 0.08 * Math.sin(a * 5 + seed * 1.7)
                    + 0.05 * Math.sin(a * 9 + seed * 0.3);
                const x = cx + Math.cos(a) * r * w * 1.35;
                const y = cy + Math.sin(a) * r * w;
                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.stroke();
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const W = width, H = height;

            ctx.strokeStyle = root.t.faint;
            ctx.lineWidth = 1;
            for (let x = 0; x < W; x += 96) {
                ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, H); ctx.stroke();
            }
            for (let y = 0; y < H; y += 96) {
                ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke();
            }

            const islands = [[0.22, 0.7, 9, 1.1], [0.78, 0.3, 11, 4.2], [0.6, 0.82, 6, 2.5], [0.12, 0.2, 5, 5.9]];
            for (const [fx, fy, n, seed] of islands) {
                for (let k = 1; k <= n; k++) {
                    ctx.strokeStyle = k === n ? root.t.dim : root.t.faint;
                    ctx.lineWidth = k % 4 === 0 ? 1.6 : 1;
                    ring(ctx, W * fx, H * fy, k * 26, seed + k * 0.35);
                }
            }

            // Crosshair markers on grid intersections.
            ctx.strokeStyle = root.t.dim;
            ctx.lineWidth = 1.2;
            for (let x = 192; x < W; x += 384) {
                for (let y = 192; y < H; y += 288) {
                    ctx.beginPath(); ctx.moveTo(x - 7, y); ctx.lineTo(x + 7, y); ctx.stroke();
                    ctx.beginPath(); ctx.moveTo(x, y - 7); ctx.lineTo(x, y + 7); ctx.stroke();
                }
            }
        }
    }

    // A slowly turning range ring, like the one on the map table.
    Item {
        visible: root.t.contours
        width: Math.min(root.width, root.height) * 0.9
        height: width
        anchors.centerIn: parent
        opacity: 0.35
        transform: Translate {
            x: -root.driftX * root.depth
            y: -root.driftY * root.depth
        }

        Canvas {
            id: sweep
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                if (width < 20)
                    return;
                const c = width / 2;
                ctx.strokeStyle = root.t.line;
                ctx.lineWidth = 1;
                ctx.beginPath(); ctx.arc(c, c, c - 2, 0, Math.PI * 2); ctx.stroke();
                ctx.setLineDash([2, 10]);
                ctx.beginPath(); ctx.arc(c, c, c * 0.72, 0, Math.PI * 2); ctx.stroke();
                ctx.setLineDash([]);
                ctx.strokeStyle = root.t.accent;
                ctx.lineWidth = 2;
                ctx.beginPath(); ctx.arc(c, c, c - 2, -0.25, 0.25); ctx.stroke();
            }
            onVisibleChanged: if (visible) requestPaint()
            Component.onCompleted: requestPaint()
        }

        RotationAnimation on rotation {
            running: root.running && root.t.contours
            from: 0
            to: 360
            duration: 60000
            loops: Animation.Infinite
        }
    }

    // Alien: CRT.
    Canvas {
        id: scan
        anchors.fill: parent
        visible: root.t.scanlines
        opacity: 0.22
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = "#000000";
            for (let y = 0; y < height; y += 3)
                ctx.fillRect(0, y, width, 1);
        }
    }

    Rectangle {
        id: scanBar
        visible: root.t.scanlines
        width: parent.width
        height: 140
        opacity: 0.06
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: root.t.line }
            GradientStop { position: 1.0; color: "transparent" }
        }
        NumberAnimation on y {
            running: root.running && root.t.scanlines
            from: -140
            to: root.height
            duration: 7000
            loops: Animation.Infinite
        }
    }

    // Automata: faint horizontal ruling, a dot grid, and long rules with square
    // markers near the top and bottom edges, like the game's menu screens.
    Canvas {
        id: paper
        anchors.fill: parent
        visible: root.t.dots
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const W = width, H = height;

            ctx.fillStyle = root.t.faint;
            ctx.globalAlpha = 0.35;
            for (let y = 0; y < H; y += 4)
                ctx.fillRect(0, y, W, 1);

            ctx.globalAlpha = 0.5;
            ctx.fillStyle = root.t.dim;
            for (let x = 14; x < W; x += 28)
                for (let y = 14; y < H; y += 28)
                    ctx.fillRect(x, y, 2, 2);

            ctx.globalAlpha = 0.8;
            ctx.fillStyle = root.t.line;
            for (const fy of [0.06, 0.95]) {
                const y = Math.round(H * fy);
                ctx.fillRect(W * 0.04, y, W * 0.92, 1);
                ctx.fillRect(W * 0.04 - 4, y - 4, 9, 9);
                ctx.fillRect(W * 0.96 - 4, y - 4, 9, 9);
                for (let x = W * 0.1; x < W * 0.9; x += W * 0.1)
                    ctx.fillRect(x, y - 6, 1, 6);
            }
        }
    }

    // The thin line that slides down the screen while the game "reads" data.
    Rectangle {
        visible: root.t.dots
        width: parent.width
        height: 2
        color: root.t.line
        opacity: 0.12
        NumberAnimation on y {
            running: root.running && root.t.dots
            from: 0
            to: root.height
            duration: 9000
            loops: Animation.Infinite
        }
    }

    // Automata: a large faint emblem of rings turning against each other, with
    // squares orbiting it. Each ring is drawn once and only rotated.
    Item {
        id: emblem
        visible: root.t.emblem
        width: Math.min(root.width, root.height) * 0.78
        height: width
        x: root.width * 0.62 - width / 2
        y: root.height * 0.55 - height / 2
        opacity: 0.22

        component Ring: Canvas {
            id: ring
            property real radius: 0.5
            property real thickness: 1
            property int ticks: 0
            property real tickLen: 8
            property var dash: []
            property real turn: 0
            property int period: 60000
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onVisibleChanged: if (visible) requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                if (width < 20)
                    return;
                const c = width / 2, r = c * radius;
                ctx.strokeStyle = root.t.line;
                ctx.fillStyle = root.t.line;
                ctx.lineWidth = thickness;
                ctx.setLineDash(dash);
                ctx.beginPath(); ctx.arc(c, c, r, 0, Math.PI * 2); ctx.stroke();
                ctx.setLineDash([]);
                for (let i = 0; i < ticks; i++) {
                    const a = i / ticks * Math.PI * 2;
                    const long = i % 6 === 0 ? 2 : 1;
                    ctx.beginPath();
                    ctx.moveTo(c + Math.cos(a) * r, c + Math.sin(a) * r);
                    ctx.lineTo(c + Math.cos(a) * (r - tickLen * long), c + Math.sin(a) * (r - tickLen * long));
                    ctx.stroke();
                }
            }
            RotationAnimation on rotation {
                running: root.running && root.t.emblem
                from: ring.turn
                to: ring.turn + (ring.period > 0 ? 360 : -360)
                duration: Math.abs(ring.period)
                loops: Animation.Infinite
            }
        }

        Ring { radius: 0.98; thickness: 2; ticks: 120; tickLen: 10; period: 120000 }
        Ring { radius: 0.86; dash: [2, 8]; period: -70000 }
        Ring { radius: 0.74; thickness: 6; dash: [40, 18, 6, 18]; period: 45000 }
        Ring { radius: 0.58; ticks: 24; tickLen: 14; period: -90000 }
        Ring { radius: 0.40; thickness: 1.5; dash: [12, 6]; period: 30000 }

        // Crosshair through the centre, still while everything turns around it.
        Rectangle { width: parent.width * 0.3; height: 1; color: root.t.line; anchors.centerIn: parent }
        Rectangle { width: 1; height: parent.height * 0.3; color: root.t.line; anchors.centerIn: parent }
        Rectangle { width: 18; height: 18; color: root.t.line; rotation: 45; anchors.centerIn: parent }

        // Squares riding an invisible orbit, a little like the Pods.
        Item {
            anchors.fill: parent
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    width: 14; height: 14
                    color: root.t.line
                    x: emblem.width / 2 + Math.cos(index * 2.094) * emblem.width * 0.66 / 2 - 7
                    y: emblem.height / 2 + Math.sin(index * 2.094) * emblem.width * 0.66 / 2 - 7
                }
            }
            RotationAnimation on rotation {
                running: root.running && root.t.emblem
                from: 0; to: 360
                duration: 24000
                loops: Animation.Infinite
            }
        }
    }

    // Squares drifting up and fading, the dust of the game's menus.
    Repeater {
        model: root.t.emblem ? 26 : 0
        Rectangle {
            id: mote
            required property int index
            // Fixed pseudo-random spread so they do not all move in step.
            readonly property real seed: (index * 0.6180339) % 1
            width: 3 + Math.round(seed * 5)
            height: width
            color: root.t.line
            x: root.width * ((index * 0.3819 + seed * 0.37) % 1)
            opacity: 0
            SequentialAnimation {
                running: root.running && root.t.emblem
                loops: Animation.Infinite
                PauseAnimation { duration: mote.seed * 9000 }
                ParallelAnimation {
                    NumberAnimation {
                        target: mote; property: "y"
                        from: root.height * (0.75 + mote.seed * 0.25)
                        to: root.height * (0.15 + mote.seed * 0.2)
                        duration: 14000 + mote.seed * 10000
                    }
                    SequentialAnimation {
                        NumberAnimation { target: mote; property: "opacity"; from: 0; to: 0.45; duration: 2500 }
                        PauseAnimation { duration: 9000 + mote.seed * 10000 }
                        NumberAnimation { target: mote; property: "opacity"; to: 0; duration: 2500 }
                    }
                }
            }
        }
    }

    // A diagnostics log scrolling up the left edge, two copies stacked so
    // the loop has no seam.
    Item {
        visible: root.t.emblem
        x: root.width * 0.012
        y: root.height * 0.09
        width: 185
        height: root.height * 0.83
        clip: true
        opacity: 0.4

        Column {
            id: logCol
            width: parent.width
            readonly property var lines: [
                "UNIT STATUS ........ NOMINAL", "BLACK BOX TEMP ...... 36.6C",
                "UPLINK ............... UP", "MEMORY CHECK ........... OK",
                "PROTOCOL 4 ........ ACTIVE", "SIGNAL 0x2F4A ...... STABLE",
                "SYNC RATE ............. 98%", "FIRMWARE ......... v11.0.7",
                "LOG 0042 ....... ARCHIVED", "NODE LINK ....... STANDBY",
                "DATA PACKET ...... 1A-77F", "CORE TEMP ........... 41.2C",
                "SELF REPAIR ........... IDLE", "INPUT DEVICE ......... OK",
                "ENCRYPTION ....... AES-256", "BUNKER LINK ....... LOST",
                "ARCHIVE SIZE ....... 2.4TB", "UPTIME ......... 1047:22:09"
            ]
            Repeater {
                model: logCol.lines.concat(logCol.lines)
                Text {
                    required property string modelData
                    text: modelData
                    color: root.t.line
                    font.family: root.t.font
                    font.pixelSize: 11
                    font.letterSpacing: 1
                    height: 20
                }
            }
            NumberAnimation on y {
                running: root.running && root.t.emblem
                from: 0
                to: -logCol.lines.length * 20
                duration: logCol.lines.length * 1800
                loops: Animation.Infinite
            }
        }
    }

    // Signature on the bottom rule, as on the boot screen.
    Row {
        visible: root.t.emblem
        x: root.width * 0.04
        y: Math.round(root.height * 0.95) - 26
        spacing: 12
        Text {
            text: "FIELD UNIT OS"
            color: root.t.line
            font.family: root.t.font
            font.pixelSize: 15
            font.weight: Font.Light
            font.letterSpacing: 5
        }
        Text {
            anchors.baseline: parent.children[0].baseline
            text: "SYSTEM TERMINAL // COMMAND INDEX"
            color: root.t.dim
            font.family: root.t.font
            font.pixelSize: 10
            font.letterSpacing: 3
        }
    }

    // Edges fall off a little, like a curved tube, a lit table or old paper.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: root.t.vignette }
            GradientStop { position: 0.12; color: "transparent" }
            GradientStop { position: 0.88; color: "transparent" }
            GradientStop { position: 1.0; color: root.t.vignette }
        }
    }
}
