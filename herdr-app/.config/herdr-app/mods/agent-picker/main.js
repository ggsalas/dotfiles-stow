// Go to an agent. One row per agent, most urgent first (blocked > done >
// working > idle). Opens on the list: "/" searches, Esc leaves the search (a
// second Esc closes), a/b/d/w/i pick the status filter, j/k or ↑/↓ move, Enter goes.

import { View, div, svg, image } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { agents, run, theme, settings, props, closeOverlay } from "herdr";

const STATUSES = ["all", "blocked", "done", "working", "idle"];
const ORDER = { blocked: 0, done: 1, working: 2, idle: 3 };
const SHORT = { a: "all", b: "blocked", d: "done", w: "working", i: "idle" };
const ROW = 36;

export default class AgentPicker extends View {
  init(_props, cx) {
    this.filter = "";
    this.status = "all";
    this.searching = false;
    this.at = 0;
    this.input = InputState.new({ placeholder: "Press / to search…" });
    this.input.on("change", (_e, cx) => { this.filter = this.input.value(); this.at = 0; cx.notify(); });
    this.input.on("focus", (_e, cx) => { this.searching = true; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.searching = false; cx.notify(); });
    this.input.on("submit", (_e, cx) => { this.leaveSearch(); this.go(this.rows()[this.at]); });
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.timer.after(600, () => { if (!this.searching) this.handle.focus(); });
  }

  leaveSearch() { this.searching = false; this.handle.focus(); }

  close() { closeOverlay(props().overlay); }

  rows() {
    const f = this.filter.toLowerCase();
    return agents()
      .filter((a) => this.status === "all" || a.status === this.status)
      .filter((a) => !f || [a.space_name, a.tab_name, a.program?.name ?? "", a.title ?? "", a.pane_name ?? ""].join(" ").toLowerCase().includes(f))
      .sort((a, b) => (ORDER[a.status] ?? 4) - (ORDER[b.status] ?? 4) || b.seq - a.seq);
  }

  setStatus(st) { this.status = st; this.at = 0; }

  go(a) {
    if (!a) return;
    this.close();
    run("space.select", { id: a.space });
    run("tab.select", { id: a.tab });
    run("pane.focus", { pane: a.pane });
  }

  glyph(t, st) {
    if (st === "working") return svg("mods/workspace-chrome/spinner.svg").size(12).flex_none().text_color(t.working).spin(900);
    return div().w(12).flex_none().text_color(t[st] ?? t.dim).child(st === "idle" ? "○" : "●");
  }

  render() {
    const t = theme();
    const rows = this.rows();
    const all = agents();
    this.at = Math.max(0, Math.min(this.at, rows.length - 1));
    const sel = rows[this.at];
    const n = rows.length;

    const chip = (st) => {
      const count = st === "all" ? all.length : all.filter((a) => a.status === st).length;
      const on = this.status === st;
      const color = st === "all" ? t.foreground : t[st];
      return h_flex().id(`ap-f-${st}`).h(24).px(9).gap(5).items_center().rounded(12).text_size(11.5).cursor_pointer()
        .border_1().border_color(on ? color : t.border).bg(on ? t.hover : t.popover)
        .text_color(on ? t.foreground : t.muted)
        .hover((s) => s.bg(t.hover))
        .on_click((_e, cx) => { this.setStatus(st); this.leaveSearch(); cx.notify(); })
        .when(st !== "all", (el) => el.child(div().size(6).rounded(3).bg(color)))
        .child(st)
        .child(div().text_color(t.dim).child(`${count}`));
    };

    const row = (a, i) => {
      const prog = a.program;
      const pic = prog?.icon ? (prog.tint ? svg(prog.icon).size(14).flex_none().text_color(t.muted) : image(prog.icon).size(14).flex_none()) : null;
      return h_flex().id(`ap-${a.address}`).mx(4).px(10).h(ROW).flex_none().rounded(7).gap(10).items_center().cursor_pointer()
        .when(i === this.at, (el) => el.bg(t.hover))
        .hover((s) => s.bg(t.hover))
        .on_click(() => this.go(a))
        .child(this.glyph(t, a.status))
        .when(Boolean(pic), (el) => el.child(pic))
        .child(div().flex_none().text_color(t.foreground).font_semibold().child(a.pane_name || prog?.name || "agent"))
        .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.dim).child(a.title && a.title !== prog?.name ? a.title : ""))
        .when(a.status === "blocked", (el) => el.child(div().text_size(11).text_color(t.blocked).child("needs you")))
        .when(a.status === "done", (el) => el.child(div().text_size(11).text_color(t.done).child("finished")))
        .child(div().flex_none().text_size(11).text_color(t.muted).child(`${a.space_name} · ${a.tab_name}`));
    };

    return v_flex().id("agent-picker")
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation()).track_focus(this.handle).w_full().min_h(0).p(18).gap(10).bg(t.popover).text_size(13)
      .on_key_down((e, cx) => {
        const k = e.key;
        const plain = !e.modifiers.control && !e.modifiers.alt && !e.modifiers.platform;
        if (k === "escape") {
          if (this.searching) { this.leaveSearch(); cx.stop_propagation(); cx.notify(); return; }
          return this.close();
        }
        if (!this.searching && plain && k === "/") {
          cx.timer.after(30, (cx) => { this.input.focus(); cx.notify(); });
          this.searching = true;
        } else if (!this.searching && plain && SHORT[k]) this.setStatus(SHORT[k]);
        else if (!this.searching && k === "enter") { this.go(sel); cx.stop_propagation(); return; }
        else if (k === "tab") this.setStatus(STATUSES[(STATUSES.indexOf(this.status) + (e.modifiers.shift ? STATUSES.length - 1 : 1)) % STATUSES.length]);
        else if (n && (k === "down" || (!this.searching && plain && k === "j"))) this.at = (this.at + 1) % n;
        else if (n && (k === "up" || (!this.searching && plain && k === "k"))) this.at = (this.at + n - 1) % n;
        else return;
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child("Agents")).child(div().id("ap-esc").px(6).py(2).rounded(5).text_size(11).text_color(t.dim).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click(() => this.close()).child("Esc")))
      .child(
        h_flex().h(36).flex_none().px(10).gap(8).items_center().rounded(9).border_1().border_color(this.searching ? t.accent : t.border).bg(t.background)
          .child(svg("mods/workspace-chrome/search.svg").size(15).text_color(t.dim))
          .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground)),
      )
      .child(h_flex().gap(6).flex_none().items_center().children(STATUSES.map(chip)).child(div().flex_1()).child(div().text_size(11).text_color(t.dim).child(this.searching ? "esc: back" : "/ search · a b d w i")))
      .child(
        v_flex().id("ap-list").h(Math.min(320, Math.max(ROW, n * ROW))).min_h(0).mb(6).overflow_y_scroll()
          .children(n ? rows.map(row) : [div().px(14).py(10).text_color(t.dim).child("No agents")]),
      );
  }
}
