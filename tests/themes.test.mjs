import { test } from "node:test";
import assert from "node:assert/strict";
import { loadLib } from "./load.mjs";

const T = loadLib("themes.js");
const S = loadLib("strings.js");
const B = loadLib("binds.js");

test("every theme in ORDER exists and has the same keys as the first", () => {
    const keys = Object.keys(T.THEMES[T.ORDER[0]]).sort();
    for (const name of T.ORDER) {
        assert.ok(T.THEMES[name], name);
        assert.deepEqual(Object.keys(T.THEMES[name]).sort(), keys, name);
        assert.equal(T.THEMES[name].name, name);
    }
});

test("an unknown theme falls back to the first one", () => {
    assert.ok(!T.has("cork"));
    assert.equal(T.get("cork").name, T.ORDER[0]);
});

test("every language has the same keys and a title for every group", () => {
    const keys = Object.keys(S.STRINGS.en).sort();
    for (const lang of Object.keys(S.STRINGS)) {
        assert.deepEqual(Object.keys(S.STRINGS[lang]).sort(), keys, lang);
        for (const g of B.GROUPS)
            assert.ok(S.STRINGS[lang].groups[g], `${lang}.groups.${g}`);
    }
});

test("an unknown language falls back to English", () => {
    assert.equal(S.get("xx").search, "Search");
});

test("theme prompts only use placeholders that strings provide", () => {
    for (const name of T.ORDER) {
        const filled = S.fill(T.THEMES[name].prompt, S.get("en"));
        assert.ok(!/\{\w+\}/.test(filled), `${name}: ${filled}`);
    }
});

test("fill leaves unknown placeholders alone", () => {
    assert.equal(S.fill("{search} {nope}", S.get("pt")), "Buscar {nope}");
});
