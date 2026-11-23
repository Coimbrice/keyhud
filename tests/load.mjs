// QML JS libraries start with `.pragma library` and expose top-level names
// instead of exports, so they are run in a sandbox and read from there.
import { readFileSync } from "node:fs";
import vm from "node:vm";

export function loadLib(name) {
    const url = new URL(`../lib/${name}`, import.meta.url);
    const src = readFileSync(url, "utf8").replace(/^\.pragma library\s*$/m, "");
    const ctx = vm.createContext({});
    vm.runInContext(src, ctx, { filename: url.pathname });
    return ctx;
}
