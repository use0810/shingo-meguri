"use strict";

(function (root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  root.Shingo = api;
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
  const TERM = "〇月から〇月までグリーンパークで使用可";

  const spots = freeze([
    { id: "christ", name: "キリストの墓" },
    { id: "green", name: "グリーンパーク" },
    { id: "office", name: "新郷村役場" },
    { id: "onsen", name: "新郷温泉館" },
    { id: "herai", name: "戸来三嶽神社" },
    { id: "nishikoshi", name: "西越三嶽神社" },
  ]);

  const items = freeze([
    { id: "sato", name: "郷のきみ" },
    { id: "yogurt", name: "飲むヨーグルト" },
    { id: "duck", name: "銀のカモ" },
    { id: "senbei", name: "生キャラ煎餅" },
    { id: "christ-item", name: "キリスト" },
    { id: "isukiri", name: "イスキリ" },
    { id: "dracula", name: "ドラキュラアイス" },
    { id: "sakasa", name: "さかさとち" },
    { id: "pyramid", name: "大石神ピラミッド" },
    { id: "mizubasho", name: "みずばしょう" },
  ]);

  const benefits = freeze([
    {
      id: "sato",
      title: "さとのきみ一本クーポン",
      kicker: "郷のきみを獲得",
      term: TERM,
    },
    {
      id: "complete",
      title: "20%オフクーポン",
      kicker: "全コンプリート",
      term: TERM,
    },
  ]);

  function freeze(list) {
    return Object.freeze(list.map((entry) => Object.freeze({ ...entry })));
  }

  function createState() {
    return {
      obtainedBadges: {},
      obtainedItems: {},
      scans: {},
      consumed: {},
      demoDayOffset: 0,
      demoForceItemId: null,
    };
  }

  function dateKey(date) {
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, "0");
    const d = String(date.getDate()).padStart(2, "0");
    return `${y}-${m}-${d}`;
  }

  function currentDateKey(state, now) {
    const date = new Date(now ? now.getTime() : Date.now());
    date.setDate(date.getDate() + (state.demoDayOffset || 0));
    return dateKey(date);
  }

  function formatDisplay(key) {
    const parts = String(key).split("-");
    return `${Number(parts[1])}月${Number(parts[2])}日`;
  }

  function advanceDay(state) {
    return { ...state, demoDayOffset: (state.demoDayOffset || 0) + 1 };
  }

  function armSato(state) {
    if (state.obtainedItems.sato) return state;
    return { ...state, demoForceItemId: "sato" };
  }

  function isUnlocked(state, id) {
    if (id === "sato") return Boolean(state.obtainedItems.sato);
    if (id === "complete") {
      const badgesDone = spots.every((spot) => state.obtainedBadges[spot.id]);
      const itemsDone = items.every((item) => state.obtainedItems[item.id]);
      return badgesDone && itemsDone;
    }
    return false;
  }

  function progress(state) {
    return {
      badges: spots.filter((spot) => state.obtainedBadges[spot.id]).length,
      badgeTotal: spots.length,
      items: items.filter((item) => state.obtainedItems[item.id]).length,
      itemTotal: items.length,
      benefits: benefits.filter((benefit) => isUnlocked(state, benefit.id)).length,
      benefitTotal: benefits.length,
    };
  }

  function newlyUnlocked(before, after) {
    return benefits.filter(
      (benefit) => isUnlocked(after, benefit.id) && !isUnlocked(before, benefit.id)
    );
  }

  function scan(state, spotId, today, rng) {
    const spot = spots.find((entry) => entry.id === spotId);
    if (!spot) return { ok: false, reason: "unknown-spot", state };
    if (state.scans[spotId] === today) {
      return { ok: false, reason: "already-scanned", state };
    }

    const random = typeof rng === "function" ? rng : Math.random;
    const remaining = items.filter((item) => !state.obtainedItems[item.id]);
    let item = null;
    if (remaining.length) {
      const forced = remaining.find((entry) => entry.id === state.demoForceItemId);
      if (forced) {
        item = forced;
      } else {
        let index = Math.floor(random() * remaining.length);
        if (index < 0 || index >= remaining.length) index = 0;
        item = remaining[index];
      }
    }

    const next = {
      obtainedBadges: { ...state.obtainedBadges },
      obtainedItems: { ...state.obtainedItems },
      scans: { ...state.scans, [spotId]: today },
      consumed: { ...state.consumed },
      demoDayOffset: state.demoDayOffset || 0,
      demoForceItemId: null,
    };
    const badgeNew = !next.obtainedBadges[spotId];
    if (badgeNew) next.obtainedBadges[spotId] = today;
    if (item) next.obtainedItems[item.id] = today;

    return {
      ok: true,
      spot,
      badgeNew,
      item,
      unlocked: newlyUnlocked(state, next),
      state: next,
    };
  }

  function consume(state, id, today) {
    if (!benefits.some((benefit) => benefit.id === id)) {
      return { ok: false, reason: "unknown", state };
    }
    if (!isUnlocked(state, id)) return { ok: false, reason: "locked", state };
    if (state.consumed[id]) return { ok: false, reason: "consumed", state };
    if (!today) return { ok: false, reason: "no-date", state };
    return {
      ok: true,
      state: {
        ...state,
        consumed: { ...state.consumed, [id]: today },
      },
    };
  }

  function grantAll(state, today) {
    const obtainedBadges = { ...state.obtainedBadges };
    const obtainedItems = { ...state.obtainedItems };
    spots.forEach((spot) => {
      if (!obtainedBadges[spot.id]) obtainedBadges[spot.id] = today;
    });
    items.forEach((item) => {
      if (!obtainedItems[item.id]) obtainedItems[item.id] = today;
    });
    return {
      ...state,
      obtainedBadges,
      obtainedItems,
      demoForceItemId: null,
    };
  }

  return {
    TERM,
    spots,
    items,
    benefits,
    createState,
    dateKey,
    currentDateKey,
    formatDisplay,
    advanceDay,
    armSato,
    isUnlocked,
    progress,
    scan,
    consume,
    grantAll,
  };
});
