// Prefix key (like Herdr TUI's `prefix`): keys.json binds ctrl-space to
// `mod.open:leader`; this popup waits for one key, runs its action and closes.
// Mirrors the prefix bindings in ~/.config/herdr/config.toml (Herdr TUI).
import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { run, openOverlay, closeOverlay, props, spaces, panes, theme } from "herdr";

// Shifted digits on a US layout, so prefix+shift+1..9 works whichever way the key arrives.
const SHIFTED = { "!": 1, "@": 2, "#": 3, "$": 4, "%": 5, "^": 6, "&": 7, "*": 8, "(": 9 };

const worktree = () => {
  const space = spaces().find(p => p.active);
  if (!space) return;
  openOverlay({ mod: "worktree", kind: "dialog", width: 440, height: 260,
    props: { space: space.id, folder: panes().find(p => p.focused)?.cwd, action: "new" } });
};

// key (as `keystroke`, without the prefix) -> [hint, action]
const BINDINGS = {
  "?": ["help", () => run("app.help")],
  "shift-/": ["", () => run("app.help")],
  "s": ["settings", () => run("app.settings")],
  "w": ["spaces", () => run("mod.open", { name: "space-picker" })],
  "g": ["goto", () => run("mod.open", { name: "space-picker" })],
  "j": ["goto", () => run("mod.open", { name: "space-picker" })],
  ";": ["palette", () => run("app.palette")],
  "shift-;": ["", () => run("app.palette")],
  "k": ["agents", () => run("mod.open", { name: "agent-picker" })],
  "shift-c": ["new space", () => run("space.new")],
  "shift-g": ["new worktree", worktree],
  "shift-r": ["rename space", () => run("space.rename")],
  "shift-k": ["close space", () => run("space.close")],
  "c": ["new tab", () => run("tab.new")],
  "shift-t": ["rename tab", () => run("tab.rename")],
  "p": ["prev tab", () => run("tab.prev")],
  "n": ["next tab", () => run("tab.next")],
  "shift-x": ["close tab", () => run("tab.close")],
  "v": ["split right", () => run("pane.split", { direction: "right" })],
  "h": ["split down", () => run("pane.split", { direction: "down" })],
  "x": ["close pane", () => run("pane.close")],
  "z": ["zoom", () => run("pane.zoom")],
  "b": ["sidebar", () => run("layout.toggle", { id: "sidebar" })],
};

function resolve(e) {
  const m = e.modifiers ?? {};
  const k = e.key;
  // 1..9: tab, shift+1..9: space.
  if (/^[1-9]$/.test(k) && !m.control && !m.alt && !m.platform) {
    return () => run(m.shift ? "space.select" : "tab.select", { index: Number(k) });
  }
  if (SHIFTED[k] || SHIFTED[e.key_char]) return () => run("space.select", { index: SHIFTED[k] ?? SHIFTED[e.key_char] });
  return BINDINGS[e.keystroke]?.[1] ?? (e.key_char === "?" ? BINDINGS["?"][1] : null);
}

export default class Leader extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.timer.after(50, () => this.handle.focus());
  }

  close() {
    closeOverlay(props().overlay);
  }

  render() {
    const t = theme();
    const hints = Object.entries(BINDINGS).filter(([, [h]]) => h)
      .map(([k, [h]]) => h_flex().gap(4).flex_none()
        .child(div().text_color(t.accent).child(k))
        .child(div().text_color(t.muted).child(h)));
    return v_flex().id("leader").track_focus(this.handle).size_full().p(10).gap(6)
      .bg(t.popover).text_size(12)
      .on_key_down((e, cx) => {
        cx.stop_propagation();
        // Bare modifier presses don't end the prefix.
        if (["shift", "control", "alt", "platform", "function"].includes(e.key)) return;
        const action = resolve(e);
        this.close();
        if (action) action();
      })
      .child(div().font_semibold().text_color(t.foreground).child("ctrl-space  ·  1-9 tab  ·  shift 1-9 space  ·  esc cancel"))
      .child(h_flex().flex_wrap().gap_x(14).gap_y(2).children(hints));
  }
}
