.pragma library

// Every piece of text the sheet draws itself. Bind names are not here: they
// are the descriptions in your Hyprland config. Themes upper-case these when
// their style asks for it, so write them in normal case.

var STRINGS = {
    en: {
        search: "Search",
        query: "Query",
        binds: "binds",
        essentials: "essentials",
        loading: "Reading binds...",
        noResults: "No results",
        groups: {
            shell: "Shell", utilities: "Utilities", windows: "Windows",
            workspaces: "Workspaces", session: "Session", screen: "Screen",
            media: "Media", apps: "Apps", other: "Other"
        }
    },
    pt: {
        search: "Buscar",
        query: "Consulta",
        binds: "atalhos",
        essentials: "principais",
        loading: "Lendo atalhos...",
        noResults: "Nenhum resultado",
        groups: {
            shell: "Shell", utilities: "Utilitários", windows: "Janelas",
            workspaces: "Áreas de trabalho", session: "Sessão", screen: "Tela",
            media: "Mídia", apps: "Apps", other: "Outros"
        }
    }
};

function get(lang) {
    return STRINGS[lang] || STRINGS.en;
}

// "> {search}:" -> "> Search:"
function fill(template, strings) {
    return String(template).replace(/\{(\w+)\}/g, function (m, key) {
        return typeof strings[key] === "string" ? strings[key] : m;
    });
}
