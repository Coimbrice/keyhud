import { test } from "node:test";
import assert from "node:assert/strict";
import { loadLib } from "./load.mjs";

const B = loadLib("binds.js");
const SUPER = 64, SHIFT = 1, CTRL = 4;

function bind(key, fields = {}) {
    return {
        key, modmask: SUPER, submap: "", mouse: false, release: false,
        has_description: false, description: "", dispatcher: "", arg: "",
        ...fields,
    };
}

function described(key, description, fields = {}) {
    return bind(key, { has_description: true, description, dispatcher: "HL.Dispatcher(exec_cmd)", ...fields });
}

// Values made inside the sandbox have its own Array/Object prototypes, which
// deepStrictEqual treats as different; a JSON round trip makes them local.
function plain(v) {
    return JSON.parse(JSON.stringify(v));
}

function build(binds, showAll = false, titles) {
    return plain(B.build(JSON.stringify(binds), showAll, titles));
}

function group(notes, id) {
    return notes.find(n => n.group === id);
}

test("a 'Group: sentence' description picks the group and the row text", () => {
    const notes = build([described("Q", "Windows: Close window")]);
    assert.equal(notes.length, 1);
    assert.equal(notes[0].group, "windows");
    assert.equal(notes[0].rows[0].label, "Close window");
    assert.deepEqual(notes[0].rows[0].mods, ["Super"]);
    assert.deepEqual(notes[0].rows[0].caps, ["Q"]);
});

test("'(more)' rows only show up with showAll and are counted as hidden", () => {
    const binds = [described("Q", "Windows: Close window"), described("C", "Windows (more): Close window")];
    assert.equal(build(binds)[0].rows.length, 1);
    assert.equal(B.lastHidden(), 1);
    assert.equal(build(binds, true)[0].rows.length, 2);
    assert.equal(B.lastHidden(), 0);
});

test("groups come out in display order whatever order the binds are in", () => {
    const notes = build([
        described("A", "Apps: Browser"),
        described("Q", "Windows: Close window"),
        described("L", "Session: Lock"),
    ]);
    assert.deepEqual(notes.map(n => n.group), ["windows", "session", "apps"]);
});

test("titles come from the caller and fall back to the capitalized id", () => {
    const binds = [described("Q", "Windows: Fechar janela"), described("A", "Apps: Navegador")];
    const notes = build(binds, false, { windows: "Janelas" });
    assert.equal(group(notes, "windows").title, "Janelas");
    assert.equal(group(notes, "apps").title, "Apps");
});

test("the group title is part of the searchable text", () => {
    const notes = build([described("Q", "Windows: Fechar janela")], false, { windows: "Janelas" });
    assert.ok(B.matches(notes[0].rows[0], "janelas", 0));
});

test("the same sentence on digit keys folds into one '#' row", () => {
    const binds = [];
    for (let i = 1; i <= 5; i++)
        binds.push(described(String(i), "Workspaces: Go to workspace"));
    const rows = build(binds)[0].rows;
    assert.equal(rows.length, 1);
    assert.deepEqual(rows[0].caps, ["#"]);
});

test("the same sentence on arrow keys folds into one keycap", () => {
    const binds = ["left", "right", "up", "down"].map(k => described(k, "Windows: Move focus"));
    const rows = build(binds)[0].rows;
    assert.equal(rows.length, 1);
    assert.deepEqual(rows[0].caps, ["←/↑/→/↓"]);
});

test("different modifiers keep folded rows apart", () => {
    const binds = [
        described("left", "Windows: Move focus"),
        described("left", "Windows: Move focus", { modmask: SUPER | SHIFT }),
    ];
    assert.equal(build(binds)[0].rows.length, 2);
});

test("a key combo bound twice is flagged as a duplicate", () => {
    const binds = [described("Q", "Windows: Close window"), described("Q", "Apps: Quit app")];
    const notes = build(binds);
    assert.equal(group(notes, "windows").rows[0].dup, true);
    assert.equal(group(notes, "apps").rows[0].dup, true);
});

test("hyprlang workspace binds without descriptions fold into a range", () => {
    const binds = [];
    for (let i = 1; i <= 5; i++)
        binds.push(bind(String(i), { dispatcher: "workspace", arg: String(i) }));
    const rows = group(build(binds), "workspaces").rows;
    assert.equal(rows.length, 1);
    assert.equal(rows[0].label, "Focus workspace # (1–5)");
});

test("exec binds are named by the program they launch", () => {
    const notes = build([
        bind("RETURN", { dispatcher: "exec", arg: "kitty" }),
        bind("B", { dispatcher: "exec", arg: "uwsm app -- firefox" }),
    ]);
    assert.deepEqual(group(notes, "apps").rows.map(r => r.label), ["Terminal", "Browser"]);
});

test("a Quickshell ipc toggle reads as a sentence in the Shell group", () => {
    const notes = build([bind("SPACE", { dispatcher: "exec", arg: "qs -c noctalia-shell ipc call launcher toggle" })]);
    assert.equal(group(notes, "shell").rows[0].label, "Toggle app launcher");
});

test("hardware keys and unnamed binds stay out unless showAll", () => {
    const binds = [
        bind("XF86AudioRaiseVolume", { modmask: 0, dispatcher: "exec", arg: "wpctl set-volume @DEFAULT_SINK@ 5%+" }),
        bind("F12", { dispatcher: "somethingodd", arg: "x" }),
    ];
    assert.deepEqual(build(binds), []);
    assert.equal(B.lastHidden(), 2);
    assert.deepEqual(build(binds, true).map(n => n.group), ["media", "other"]);
});

test("submap binds are ignored", () => {
    assert.deepEqual(build([described("R", "Windows: Resize", { submap: "resize" })]), []);
});

test("a long group is split into numbered panels", () => {
    const binds = [];
    for (let i = 0; i < B.CHUNK + 3; i++)
        binds.push(described("F" + (i + 1), "Apps: App " + i));
    const notes = build(binds, false, { apps: "Apps" });
    assert.deepEqual(notes.map(n => n.title), ["Apps", "Apps (2)"]);
    assert.equal(notes[0].rows.length, B.CHUNK);
    assert.equal(notes[1].rows.length, 3);
});

test("bad input gives no panels instead of throwing", () => {
    assert.deepEqual(plain(B.build("not json", false)), []);
    assert.deepEqual(plain(B.build("{}", false)), []);
});

test("matches needs every word and every active modifier", () => {
    const row = build([described("Q", "Windows: Close window", { modmask: SUPER | SHIFT })])[0].rows[0];
    assert.ok(B.matches(row, "close win", 0));
    assert.ok(!B.matches(row, "close tab", 0));
    assert.ok(B.matches(row, "", SUPER | SHIFT));
    assert.ok(!B.matches(row, "", CTRL));
});

test("place puts each panel in the shortest column", () => {
    const note = rows => ({ rows: new Array(rows).fill({}) });
    const out = plain(B.place([note(10), note(2), note(2)], 2, 20));
    assert.deepEqual(out.items.map(i => i.x), [0, B.NOTE_W + 20, B.NOTE_W + 20]);
    assert.equal(out.items[2].y, B.HEAD_H + 2 * B.ROW_H + B.PAD_H + 20);
    assert.equal(out.height, B.HEAD_H + 10 * B.ROW_H + B.PAD_H + 20);
});
