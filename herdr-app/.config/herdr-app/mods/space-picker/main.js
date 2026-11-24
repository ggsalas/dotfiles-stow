// Go to a space (clone of the shipped `picker`). One row per space, in sidebar
// order, all shown from the start (no folding of quiet spaces, no per-tab rows).
// Type to filter by space, tab or agent name; ↑/↓ and Enter to go, ctrl+d to
// close a space, Esc to leave. Last rows: new tab / new space.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { agents, spaces, terminals, run, hc, exec, checking, theme, settings, props, closeOverlay, openOverlay, shared, setShared } from "herdr";

const MARK = { ansi6: "#22a99a", ansi3: "#e3814f", ansi4: "#5b8def", ansi5: "#8b7cf6", ansi2: "#3fae6a", ansi1: "#d9649a" };

// Space colors, kept by space id in shared "space.colors": a theme
// color name ("ansi6") or a picked #rrggbb. A space seen without one gets
// the theme color fewest spaces use, once; every mod does the same in the
// same order, so they agree, and adding or renaming spaces moves nothing.
const PROJECT_COLORS = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"];
function spaceColors() {
  const ids = new Set(spaces().map((p) => p.id));
  const kept = Object.fromEntries(Object.entries(shared("space.colors") ?? {}).filter(([id]) => ids.has(id)));
  let changed = Object.keys(kept).length !== Object.keys(shared("space.colors") ?? {}).length;
  for (const p of spaces()) {
    if (kept[p.id] || p.name === "~") continue;
    const uses = (c) => Object.values(kept).filter((v) => v === c).length;
    kept[p.id] = PROJECT_COLORS.reduce((best, c) => (uses(c) < uses(best) ? c : best));
    changed = true;
  }
  if (changed) setShared("space.colors", kept);
  return kept;
}
function spaceColor(t, p) {
  if (p.name === "~") return t.dim;
  const c = spaceColors()[p.id] ?? PROJECT_COLORS[0];
  return c.startsWith("#") ? c : (MARK[c] ?? t[c]);
}

// Same repo naming as the sidebar: the folder holding .git, or a bare repo's own name.
const base = (path) => path.replace(/\/+$/, "").split("/").pop();
const repoName = (common) => {
  if (common.endsWith("/.git")) return base(common.slice(0, -5));
  const own = base(common);
  return own === ".bare" ? base(common.slice(0, -own.length - 1)) : own.replace(/\.git$/, "");
};

const STATUSES = ["all", "blocked", "done", "working", "idle"];

export default class Picker extends View {
  init(_props, cx) {
    this.filter = "";
    this.status = "all";
    this.git = {}; // space id -> { repo, linked } | null (not a repo)
    this.asked = new Set();
    this.input = InputState.new({ placeholder: "Press / to search…" });
    this.input.on("change", (_e, cx) => {
      this.filter = this.input.value();
      this.at = this.filter ? Math.max(0, this.rows().filter(r => r.kind !== "head").findIndex(r => r.kind === "sp")) : 0;
      cx.notify();
    });
    this.input.on("focus", (_e, cx) => { this.searching = true; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.searching = false; cx.notify(); });
    this.input.on("submit", (_e, cx) => this.go(this.rows().filter(r => r.kind !== "head")[this.at], cx));
    // Opens on the list, not the search: "/" starts typing, Esc goes back to the list.
    this.searching = false;
    this.at = null;
    this.scroll = 0;
    this.showEarlier = false;
    this.machines = [];
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.timer.after(600, () => { if (!this.searching) this.handle.focus(); });
    cx.spawn(async (cx) => {
      try {
        const r = await hc(["machine", "ls", "--json"]);
        if (r.code === 0) this.machines = (JSON.parse(r.stdout).machines ?? []).filter((m) => m.state === "connected" && !m.temporary).map((m) => m.name);
      } catch {}
      cx.notify();
    });
  }

  // Is this space a linked worktree, and of which repo? Asked once per space and folder.
  look(w, cx) {
    const key = `${w.id}|${w.folder}`;
    if (this.asked.has(key) || !w.folder || checking()) return;
    this.asked.add(key);
    cx.spawn(async (cx) => {
      try {
        const [top, common] = await Promise.all([
          exec("git", ["rev-parse", "--path-format=absolute", "--show-toplevel"], { cwd: w.folder, on: w.machine }),
          exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd: w.folder, on: w.machine }),
        ]);
        if (top.code !== 0 || common.code !== 0) this.git[w.id] = null;
        else {
          const t = top.stdout.replace(/\n$/, ""), c = common.stdout.replace(/\n$/, "");
          this.git[w.id] = { repo: repoName(c), linked: c !== `${t}/.git` };
        }
      } catch { this.asked.delete(key); }
      cx.notify();
    });
  }

  close() {
    closeOverlay(props().overlay);
  }

  rows() {
    const f = this.filter.toLowerCase();
    const all = agents();
    const live = terminals().filter((x) => x.state === "live");
    const teamOf = (addrs) => {
      let n = 0;
      const walk = (a) => live.filter((x) => x.parent === a).forEach((k) => (n++, walk(k.address)));
      addrs.forEach(walk);
      return n;
    };
    const out = spaces()
      .map((w) => {
        const mine = all.filter((a) => a.space === w.id || w.tabs.some((c) => c.id === a.tab));
        return { kind: "sp", w, mine, team: teamOf(mine.map((a) => a.address)) };
      })
      .filter((r) => this.status === "all" || r.mine.some((a) => a.status === this.status))
      .filter((r) => !f || [r.w.name, r.w.branch ?? "", this.git[r.w.id]?.linked ? `worktree ${this.git[r.w.id].repo}` : "", ...r.w.tabs.map((c) => c.name), ...r.mine.map((a) => a.program?.name ?? "")].join(" ").toLowerCase().includes(f));
    if (this.status !== "all") return out;
    out.push({ kind: "new" });
    out.push({ kind: "space", machine: null });
    for (const m of this.machines) out.push({ kind: "space", machine: m });
    return out;
  }

  setStatus(st) {
    this.status = st;
    this.at = 0;
    this.scroll = 0;
  }

  go(r, cx) {
    if (!r) return;
    this.close();
    if (r.kind === "sp") run("space.select", { id: r.w.id });
    else if (r.kind === "new") run("tab.new");
    else if (r.kind === "space") run("space.new", { machine: r.machine ?? "" });
  }

  glyph(t, st) {
    if (st === "working") return svg("mods/workspace-chrome/spinner.svg").size(12).flex_none().text_color(t.working).spin(900);
    return div().w(12).flex_none().text_color(t[st] ?? t.dim).child(st === "idle" ? "○" : st ? "●" : "·");
  }

  render(cx) {
    const t = theme();
    spaces().forEach((w) => this.look(w, cx));
    const rows = this.rows();
    const pickable = rows.filter((r) => r.kind !== "head");
    // Opens on where you are.
    if (this.at === null) this.at = Math.max(0, pickable.findIndex((r) => r.kind === "sp" && r.w.active));
    this.at = Math.max(0, Math.min(this.at, pickable.length - 1));
    const sel = pickable[this.at];
    // One continuous strip: each row (and the group title before it) at a fixed
    // y. Scrolling moves the strip only as far as it takes to keep the selected
    // row in view, so the arrows can't run the selection off the list.
    const H = { new: 36, sp: 32, space: 32 };
    const tops = [];
    let y = 0;
    rows.forEach((r) => { tops.push(y); y += H[r.kind] ?? 32; });
    const total = y;
    const height = Math.min(320, this.listHeight ?? 320);
    const fixed = total > height;
    const maxScroll = Math.max(0, total - height);
    this.scroll = Math.max(0, Math.min(this.scroll, maxScroll));
    const si = rows.indexOf(sel);
    if (si >= 0) {
      if (tops[si] < this.scroll) this.scroll = tops[si];
      if (tops[si] + (H[sel.kind] ?? 32) > this.scroll + height) this.scroll = tops[si] + (H[sel.kind] ?? 32) - height;
    }
    const place = (el, i) =>
      fixed
        ? el.absolute().left(0).right(0).top(tops[i] - this.scroll).bottom(height - (tops[i] + (H[rows[i].kind] ?? 32) - this.scroll))
        : el;
    const visible = (i) => !fixed || (tops[i] + (H[rows[i].kind] ?? 32) > this.scroll && tops[i] < this.scroll + height);

    const row = (r) => {
      if (r.kind === "head") {
        return h_flex()
          .px(10)
          .pt(10)
          .pb(3)
          .gap(8)
          .items_center()
          .text_size(11)
          .font_semibold()
          .text_color(t.dim)
          .child(h_flex().size(18).rounded(5).bg(spaceColor(t, r.w)).items_center().justify_center().text_size(10.5).font_bold().text_color("#ffffff").child([...r.w.name][0]?.toUpperCase() ?? "?"))
          .child(r.w.name);
      }
      if (r.kind === "earlier") {
        return h_flex()
          .id("pk-earlier")
          .mt(6)
          .px(10)
          .py(6)
          .border_t(1)
          .border_color(t.border)
          .text_size(12)
          .text_color(t.dim)
          .cursor_pointer()
          .when(r === sel, (el) => el.bg(t.hover).text_color(t.foreground))
          .hover((s) => s.bg(t.hover).text_color(t.foreground))
          .on_click((_e, cx) => this.go(r, cx))
          .child(`earlier: ${r.count} quiet space${r.count > 1 ? "s" : ""} ${this.showEarlier ? "▴" : "▾"}`);
      }
      const on = r === sel;
      if (r.kind === "new" || r.kind === "space") {
        const label = r.kind === "new" ? "new tab" : r.machine ? `new space on ${r.machine}` : "new space";
        return h_flex()
          .id(r.kind === "new" ? "pk-new" : `pk-space-${r.machine ?? "here"}`)
          .mx(4)
          .when(r.kind === "new", (el) => el.mt(4))
          .px(10)
          .h(32)
          .items_center()
          .rounded(7)
          .gap(8)
          .text_color(t.muted)
          .cursor_pointer()
          .when(on, (el) => el.bg(t.hover))
          .hover((s) => s.bg(t.hover))
          .on_click(() => this.go(r))
          .child(div().w(12).child("+"))
          .child(label);
      }
      const wt = this.git[r.w.id]?.linked ? this.git[r.w.id] : null;
      const who = r.mine.map((a) => a.program?.name ?? "agent").join(" · ");
      const n = spaces().findIndex((p) => p.id === r.w.id) + 1;
      return h_flex()
        .id(`pk-${r.w.id}`)
        .mx(4)
        .px(10)
        .h(32)
        .rounded(7)
        .gap(10)
        .items_center()
        .cursor_pointer()
        .when(on, (el) => el.bg(t.hover))
        .hover((s) => s.bg(t.hover))
        .on_click(() => this.go(r))
        .child(this.glyph(t, r.w.status))
        .child(div().w(14).flex_none().text_size(11).text_color(t.dim).child(n <= 9 ? `${n}` : ""))
        .when(Boolean(wt), (el) => el.child(div().flex_none().w(10).text_color(t.dim).child("└")))
        .child(h_flex().size(18).flex_none().rounded(5).bg(spaceColor(t, r.w)).items_center().justify_center().text_size(10.5).font_bold().text_color("#ffffff").child([...r.w.name][0]?.toUpperCase() ?? "?"))
        .child(div().flex_1().truncate().text_color(t.foreground).when(r.w.active, (d) => d.font_semibold()).child(r.w.name))
        .when(Boolean(wt), (el) => el.child(h_flex().flex_none().h(18).px(6).gap(4).items_center().rounded(5).bg(t.raised).text_size(10.5).text_color(t.muted).child(svg("mods/workspace-chrome/branch.svg").size(10).text_color(t.dim)).child(`worktree of ${wt.repo}`)))
        .when(Boolean(r.w.branch) && r.w.branch !== r.w.name, (el) => el.child(div().text_size(11).text_color(t.dim).truncate().max_w(160).child(r.w.branch)))
        .when(r.w.status === "blocked", (el) => el.child(div().text_size(11).text_color(t.blocked).child("needs you")))
        .when(r.w.status === "done", (el) => el.child(div().text_size(11).text_color(t.done).child("finished")))
        .child(div().text_size(11).text_color(t.dim).child(who + (r.team ? `  +${r.team}` : "")));
    };

    return v_flex()
      .id("picker")
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .track_focus(this.handle)
      .w_full()
      .min_h(0)
      .p(18)
      .gap(10)
      .bg(t.popover)
      .text_size(13)
      .on_key_down((e, cx) => {
        const k = e.key;
        const plain = !e.modifiers.control && !e.modifiers.alt && !e.modifiers.platform;
        if (k === "escape") {
          if (this.searching) { this.searching = false; this.handle.focus(); cx.stop_propagation(); cx.notify(); return; }
          return this.close();
        }
        if (this.searching && k === "enter") { this.searching = false; this.handle.focus(); }
        // Not searching: letters are shortcuts.
        const SHORT = { a: "all", b: "blocked", d: "done", w: "working", i: "idle" };
        if (!this.searching && plain && k === "/") {
          this.searching = true;
          cx.timer.after(30, (cx) => { this.input.focus(); cx.notify(); });
          cx.stop_propagation(); cx.notify(); return;
        }
        const n = pickable.length;
        if (!this.searching && plain && SHORT[k]) this.setStatus(SHORT[k]);
        else if (!this.searching && k === "enter") { this.go(sel, cx); cx.stop_propagation(); return; }
        else if (k === "tab") {
          const i = STATUSES.indexOf(this.status);
          this.setStatus(STATUSES[(i + (e.modifiers.shift ? STATUSES.length - 1 : 1)) % STATUSES.length]);
        } else if (n && (k === "down" || (!this.searching && plain && k === "j"))) this.at = (this.at + 1) % n;
        else if (n && (k === "up" || (!this.searching && plain && k === "k"))) this.at = (this.at + n - 1) % n;
        else if (k === "d" && e.modifiers.control) {
          if (sel?.kind === "sp") {
            this.close();
            run("space.close", { id: sel.w.id });
          }
        } else return;
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child("Spaces")).child(div().id("picker-esc").px(6).py(2).rounded(5).text_size(11).text_color(t.dim).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click(() => this.close()).child("Esc")))
      .child(
        h_flex().h(36).flex_none().px(10).gap(8).items_center().rounded(9).border_1().border_color(this.searching ? t.accent : t.border).bg(t.background)
          .child(svg("mods/workspace-chrome/search.svg").size(15).text_color(t.dim))
          .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground)),
      )
      .child(
        h_flex().gap(6).flex_none().items_center().children(STATUSES.map((st) => {
          const n = st === "all" ? spaces().length : spaces().filter((w) => agents().some((a) => (a.space === w.id || w.tabs.some((c) => c.id === a.tab)) && a.status === st)).length;
          const on = this.status === st;
          const color = st === "all" ? t.foreground : t[st];
          return h_flex().id(`pk-f-${st}`).h(24).px(9).gap(5).items_center().rounded(12).text_size(11.5).cursor_pointer()
            .border_1().border_color(on ? color : t.border).bg(on ? t.hover : t.popover)
            .text_color(on ? t.foreground : t.muted)
            .hover((s) => s.bg(t.hover))
            .on_click((_e, cx) => { this.setStatus(st); this.handle.focus(); this.searching = false; cx.notify(); })
            .when(st !== "all", (el) => el.child(div().size(6).rounded(3).bg(color)))
            .child(st)
            .child(div().text_color(t.dim).child(`${n}`));
        })).child(div().flex_1()).child(div().text_size(11).text_color(t.dim).child(this.searching ? "esc: back" : "/ search · a b d w i")),
      )
      .child(
        v_flex()
          .id("pk-list")
          .on_size_change((size, cx) => {
            this.listHeight = size.height / settings().zoom;
            cx.notify();
          })
          .h(Math.min(320, total))
          .min_h(0)
          .mb(6)
          .when(fixed, (el) =>
            el.overflow_hidden().on_scroll_wheel((e, cx) => {
              this.scroll = Math.max(0, Math.min(this.scroll - e.delta.y, maxScroll));
              // The selection follows the wheel, so the next frame doesn't scroll back to it.
              while (this.at < pickable.length - 1 && tops[rows.indexOf(pickable[this.at])] < this.scroll) this.at++;
              while (this.at > 0 && tops[rows.indexOf(pickable[this.at])] + (H[pickable[this.at].kind] ?? 32) > this.scroll + height) this.at--;
              cx.notify();
            }))
          .children(rows.map((r, i) => (visible(i) ? place(row(r), i) : null)).filter(Boolean)),
      );
  }
}
