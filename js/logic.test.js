"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const Shingo = require("./logic.js");

function addDays(key, amount) {
  const [y, m, d] = key.split("-").map(Number);
  const date = new Date(y, m - 1, d + amount);
  return Shingo.dateKey(date);
}

test("catalog matches the prototype list", () => {
  assert.deepEqual(
    Shingo.spots.map((spot) => spot.name),
    ["キリストの墓", "グリーンパーク", "新郷村役場", "新郷温泉館", "戸来三嶽神社", "西越三嶽神社"]
  );
  assert.deepEqual(
    Shingo.items.map((item) => item.name),
    [
      "郷のきみ",
      "飲むヨーグルト",
      "銀のカモ",
      "生キャラ煎餅",
      "キリスト",
      "イスキリ",
      "ドラキュラアイス",
      "さかさとち",
      "大石神ピラミッド",
      "みずばしょう",
    ]
  );
  assert.equal(Shingo.benefits[0].title, "さとのきみ一本クーポン");
  assert.equal(Shingo.benefits[1].title, "20%オフクーポン");
  assert.equal(Shingo.benefits[1].kicker, "全コンプリート");
  assert.equal(Shingo.TERM, "〇月から〇月までグリーンパークで使用可");
  assert.equal(Shingo.benefits[0].term, Shingo.TERM);
  assert.equal(Shingo.benefits[1].term, Shingo.TERM);
});

test("a scan gives that place's badge and one unduplicated item", () => {
  const before = Shingo.createState();
  const result = Shingo.scan(before, "christ", "2026-11-08", () => 0);
  assert.equal(result.ok, true);
  assert.equal(result.spot.name, "キリストの墓");
  assert.equal(result.badgeNew, true);
  assert.equal(result.item.name, "郷のきみ");
  assert.equal(result.state.obtainedBadges.christ, "2026-11-08");
  assert.equal(result.state.scans.christ, "2026-11-08");
  assert.deepEqual(before, Shingo.createState());
});

test("the same place cannot be scanned again on the same day", () => {
  const once = Shingo.scan(Shingo.createState(), "onsen", "2026-11-08", () => 0.2);
  const before = structuredClone(once.state);
  const twice = Shingo.scan(once.state, "onsen", "2026-11-08", () => 0.2);
  assert.equal(twice.ok, false);
  assert.equal(twice.reason, "already-scanned");
  assert.equal(twice.state, once.state);
  assert.deepEqual(once.state, before);
});

test("another place can be scanned the same day", () => {
  let state = Shingo.createState();
  const first = Shingo.scan(state, "christ", "2026-11-08", () => 0);
  const second = Shingo.scan(first.state, "green", "2026-11-08", () => 0);
  assert.equal(second.ok, true);
  assert.equal(second.badgeNew, true);
  assert.notEqual(second.item.id, first.item.id);
});

test("the next day gives an item even when the badge is already owned", () => {
  const first = Shingo.scan(Shingo.createState(), "herai", "2026-11-08", () => 0);
  const second = Shingo.scan(first.state, "herai", "2026-11-09", () => 0);
  assert.equal(second.ok, true);
  assert.equal(second.badgeNew, false);
  assert.equal(second.state.obtainedBadges.herai, "2026-11-08");
  assert.ok(second.item);
  assert.notEqual(second.item.id, first.item.id);
});

test("items never duplicate and stop after the tenth", () => {
  let state = Shingo.createState();
  let day = "2026-11-01";
  const seen = [];
  for (let n = 0; n < 12; n += 1) {
    const spotId = Shingo.spots[n % Shingo.spots.length].id;
    if (state.scans[spotId] === day) day = addDays(day, 1);
    const result = Shingo.scan(state, spotId, day, () => 0.99);
    assert.equal(result.ok, true);
    if (result.item) seen.push(result.item.id);
    state = result.state;
  }
  assert.equal(new Set(seen).size, 10);
  assert.equal(seen.length, 10);
  assert.equal(Shingo.progress(state).items, 10);
  assert.equal(Shingo.progress(state).badges, 6);
});

test("random draws stay inside the remaining items", () => {
  for (let seed = 0; seed < 20; seed += 1) {
    let state = Shingo.createState();
    let day = "2026-11-01";
    const seen = [];
    const rng = () => ((seed * 13 + seen.length * 7) % 100) / 100;
    for (let n = 0; n < 10; n += 1) {
      const spotId = Shingo.spots[n % Shingo.spots.length].id;
      if (state.scans[spotId] === day) day = addDays(day, 1);
      const result = Shingo.scan(state, spotId, day, rng);
      assert.equal(result.ok, true);
      assert.ok(result.item);
      seen.push(result.item.id);
      state = result.state;
    }
    assert.equal(new Set(seen).size, 10);
  }
});

test("郷のきみ unlocks only the single-item coupon", () => {
  const state = Shingo.armSato(Shingo.createState());
  const result = Shingo.scan(state, "green", "2026-11-08", () => 0.99);
  assert.equal(result.item.id, "sato");
  assert.deepEqual(
    result.unlocked.map((benefit) => benefit.id),
    ["sato"]
  );
  assert.equal(result.state.demoForceItemId, null);
  assert.equal(Shingo.isUnlocked(result.state, "complete"), false);
});

test("a failed rescan keeps the forced item armed", () => {
  const scanned = Shingo.scan(Shingo.createState(), "christ", "2026-11-08", () => 0.4);
  const armed = { ...scanned.state, demoForceItemId: "sato" };
  const denied = Shingo.scan(armed, "christ", "2026-11-08", () => 0);
  assert.equal(denied.ok, false);
  assert.equal(denied.state, armed);
});

test("full completion requires every badge and every item", () => {
  let state = Shingo.createState();
  let day = "2026-11-01";
  for (let n = 0; n < 10; n += 1) {
    const spotId = Shingo.spots[n % 5].id;
    if (state.scans[spotId] === day) day = addDays(day, 1);
    state = Shingo.scan(state, spotId, day, () => 0).state;
  }
  assert.equal(Shingo.progress(state).badges, 5);
  assert.equal(Shingo.progress(state).items, 10);
  assert.equal(Shingo.isUnlocked(state, "sato"), true);
  assert.equal(Shingo.isUnlocked(state, "complete"), false);
});

test("the scan that finishes both collections unlocks the 20% coupon", () => {
  let state = Shingo.createState();
  const today = "2026-11-08";
  Shingo.spots.forEach((spot) => {
    state.obtainedBadges[spot.id] = today;
  });
  Shingo.items.forEach((item) => {
    if (item.id !== "sato") state.obtainedItems[item.id] = today;
  });
  const before = structuredClone(state);
  const result = Shingo.scan(state, "nishikoshi", today, () => 0.5);
  assert.equal(result.item.id, "sato");
  assert.deepEqual(
    result.unlocked.map((benefit) => benefit.id).sort(),
    ["complete", "sato"]
  );
  assert.deepEqual(state, before);
});

test("staff can mark an unlocked coupon consumed once", () => {
  const granted = Shingo.grantAll(Shingo.createState(), "2026-11-08");
  assert.deepEqual(granted.scans, {});
  const locked = Shingo.consume(Shingo.createState(), "sato", "2026-11-08");
  assert.equal(locked.ok, false);
  const used = Shingo.consume(granted, "complete", "2026-11-08");
  assert.equal(used.ok, true);
  assert.equal(used.state.consumed.complete, "2026-11-08");
  const again = Shingo.consume(used.state, "complete", "2026-11-09");
  assert.equal(again.ok, false);
  assert.equal(again.reason, "consumed");
});

test("the demo date moves forward without using the UTC clock", () => {
  const now = new Date(2026, 10, 8, 23, 30);
  const state = Shingo.advanceDay(Shingo.createState());
  assert.equal(Shingo.currentDateKey(state, now), "2026-11-09");
  assert.equal(Shingo.formatDisplay("2026-11-09"), "11月9日");
});
