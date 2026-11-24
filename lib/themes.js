.pragma library

// The looks of the sheet. Everything that differs between them lives here,
// so the components only read `t.<name>`. A new theme is a new entry in
// THEMES plus its name in ORDER; the picker lists whatever ORDER has.
//
//   alien     green-phosphor CRT terminal with scanlines
//   jurassic  holographic map table: cyan contour lines, orange markers
//   automata  printed game-menu look: dark ink on warm beige paper, square
//             bullets and a hard offset shadow instead of a glow
//
// `prompt` is the search label; {search} and {query} come from strings.js.
//
// Shared switches: `bar` draws panel titles on a solid strip, `brackets`
// adds corner marks outside each panel, `shadowX` offsets the panel shadow
// (0 makes it a glow), `dots` puts a dot grid on the backdrop, `emblem`
// adds the turning rings, drifting squares and scrolling log behind it,
// `parallax` is how far (px) the backdrop drifts against the pointer.

var THEMES = {
    alien: {
        name: "alien",
        label: "ALIEN",
        // See-through tube: the scanlines still cover it, the panels stay dense.
        backdrop: "#a8020906",
        panel: "#f005170e",
        line: "#6dffb5",
        dim: "#2f8f66",
        faint: "#164d36",
        text: "#b9ffd9",
        accent: "#e8ff5a",
        onAccent: "#04140c",
        font: "Share Tech Mono",
        titleFont: "Share Tech Mono",
        upper: true,
        radius: 0,
        cut: 0,
        capRadius: 0,
        glow: 0.55,
        scanlines: true,
        contours: false,
        float: 0,
        titlePrefix: "▌ ",
        prompt: "> {search}:",
        bar: true,
        brackets: true,
        rowSize: 14,
        blockCursor: true,
        dupText: "!DUP",
        alert: "#e8ff5a",
        shadow: "#6dffb5",
        shadowX: 0,
        vignette: "#66000000",
        dots: false,
        emblem: false,
        parallax: 0
    },
    jurassic: {
        name: "jurassic",
        label: "JURASSIC",
        // See-through backdrop; the panels are a bit denser to stay readable.
        backdrop: "#99030d16",
        panel: "#b806243b",
        line: "#4fd8ff",
        dim: "#2a7fa3",
        faint: "#123e57",
        text: "#d6f4ff",
        accent: "#ffae3d",
        onAccent: "#1a0d00",
        font: "Rajdhani",
        titleFont: "Rajdhani",
        upper: false,
        radius: 2,
        cut: 14,
        capRadius: 4,
        glow: 0.7,
        scanlines: false,
        contours: true,
        float: 3,
        titlePrefix: "◢ ",
        prompt: "{query} ▸",
        bar: false,
        brackets: false,
        rowSize: 16,
        blockCursor: false,
        dupText: "2×",
        alert: "#ffae3d",
        shadow: "#4fd8ff",
        shadowX: 0,
        vignette: "#66000000",
        dots: false,
        emblem: false,
        parallax: 22
    },
    automata: {
        name: "automata",
        label: "AUTOMATA",
        // Paper you can still see the desktop through.
        backdrop: "#f2d6d0b6",
        panel: "#ecdcd7c2",
        line: "#4e4b42",
        dim: "#8f8a78",
        faint: "#bcb6a0",
        text: "#3f3c34",
        accent: "#4e4b42",
        onAccent: "#dad4bb",
        font: "Noto Sans",
        titleFont: "Noto Sans",
        upper: true,
        radius: 0,
        cut: 0,
        capRadius: 0,
        glow: 0.45,
        scanlines: false,
        contours: false,
        float: 0,
        titlePrefix: "■ ",
        prompt: "■ {search}",
        bar: true,
        brackets: false,
        rowSize: 14,
        blockCursor: false,
        dupText: "DUP",
        alert: "#b4513b",
        shadow: "#4e4b42",
        shadowX: 6,
        vignette: "#40a39d86",
        dots: true,
        emblem: true,
        parallax: 0
    }
};

var ORDER = ["alien", "jurassic", "automata"];

function has(name) {
    return ORDER.indexOf(name) >= 0;
}

function get(name) {
    return THEMES[name] || THEMES[ORDER[0]];
}
