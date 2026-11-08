"use strict";

const KEY = "shingo-meguri-prototype-v1";
const APP_NAME = "新郷観光アプリ（仮）";
const PAGES = new Set(["home", "profile", "map", "badges", "items", "benefits"]);
const MAP_SRC = "img/shingo-map.jpg?v=2";

const svg = (body, extra = "") =>
  `<svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"${extra}>${body}</svg>`;

const ICONS = {
  profile: svg('<circle cx="12" cy="9" r="3.4"/><path d="M5.8 19.4c1.3-2.7 3.4-4 6.2-4s4.9 1.3 6.2 4"/>'),
  badge: svg('<circle cx="12" cy="9.5" r="5"/><path d="M8.6 13.6 7.4 20.5l4.6-2 4.6 2-1.2-6.9"/><path d="m10 9.6 1.4 1.4 2.8-2.8"/>'),
  item: svg('<path d="M4.5 8.5h15v11a1 1 0 0 1-1 1h-13a1 1 0 0 1-1-1z"/><path d="M3.5 5h17v3.5h-17zM12 5v15.5"/><path d="M12 5c-1.5-2.6-5-2.6-4.4-.4.3 1 2.4.4 4.4.4zm0 0c1.5-2.6 5-2.6 4.4-.4-.3 1-2.4.4-4.4.4z"/>'),
  benefit: svg('<path d="M3.5 7.5a1 1 0 0 1 1-1h15a1 1 0 0 1 1 1v2.3a2.2 2.2 0 0 0 0 4.4v2.3a1 1 0 0 1-1 1h-15a1 1 0 0 1-1-1v-2.3a2.2 2.2 0 0 0 0-4.4z"/><path d="M14.5 7v10" stroke-dasharray="1.6 2.2"/>'),
  map: svg('<path d="M9 4.5 3.5 6.6v13l5.5-2.1 6 2.1 5.5-2.1v-13L15 6.6z"/><path d="M9 4.5v13M15 6.6v13"/>'),
  qr: svg('<rect x="3.5" y="3.5" width="6.5" height="6.5" rx="1.2"/><rect x="14" y="3.5" width="6.5" height="6.5" rx="1.2"/><rect x="3.5" y="14" width="6.5" height="6.5" rx="1.2"/><path d="M14 14h2.5v2.5H14zM18 18h2.5v2.5H18zM18 14h2.5M14 18v2.5"/>'),
  close: svg('<path d="M6 6l12 12M18 6 6 18"/>'),
  route: svg('<circle cx="6" cy="18" r="2"/><circle cx="18" cy="6" r="2"/><path d="M8 18h7.5a3 3 0 0 0 0-6h-7a3 3 0 0 1 0-6H16"/>'),
  lock: svg('<rect x="5" y="10.5" width="14" height="10" rx="2"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5"/>'),
  rotate: svg('<rect x="7" y="2.5" width="10" height="17" rx="2" transform="rotate(-90 12 12)"/><path d="M4 8.5a8 8 0 0 1 4-4.6M8 1.8l.2 2.3-2.2.5"/>'),
  chevron: svg('<path d="m9 6 6 6-6 6"/>'),
};

const BRAND_MARK =
  '<svg viewBox="0 0 40 40" aria-hidden="true"><circle cx="28" cy="12" r="5" fill="#f6b73c"/><path d="M2 32 14 15l7 9 5-6 12 14z" fill="#5aa83c"/><path d="M14 15l4 5.2-3 1.6-3-2.2z" fill="#fff" opacity=".85"/><path d="M2 32h36v3H2z" fill="#a0673a"/></svg>';

/* 地図画像の中で、各スポットのイラストが描かれている位置（px） */
const ART = {
  office: [728, 152],
  herai: [636, 146],
  christ: [470, 174],
  green: [298, 380],
  onsen: [432, 466],
  nishikoshi: [748, 352],
};

const ITEM_LOOK = {
  sato: { glyph: "郷", color: "#f2b632" },
  yogurt: { glyph: "乳", color: "#6fb1d6" },
  duck: { glyph: "鴨", color: "#8f9ca6" },
  senbei: { glyph: "煎", color: "#c98a4b" },
  "christ-item": { glyph: "キ", color: "#b07cc6" },
  isukiri: { glyph: "イ", color: "#e0789a" },
  dracula: { glyph: "ド", color: "#8a4b5c" },
  sakasa: { glyph: "栃", color: "#5c9a4a" },
  pyramid: { glyph: "石", color: "#7c7f86" },
  mizubasho: { glyph: "芭", color: "#4fb39a" },
};

const MAP_PLACES = [
  { id: "office", label: "新郷村役場", query: "新郷村役場 青森県三戸郡新郷村大字戸来字風呂前10", left: 68, top: 16, width: 14, height: 14 },
  { id: "herai", label: "戸来三嶽神社", query: "戸来三嶽神社 青森県三戸郡新郷村大字戸来字三嶽下15", left: 56.5, top: 18, width: 11, height: 13 },
  { id: "christ", label: "キリストの墓", query: "キリストの墓 青森県三戸郡新郷村大字戸来字野月33-1", left: 39, top: 21, width: 11, height: 16 },
  { id: "densho", label: "伝承館", query: "キリストの里伝承館 青森県三戸郡新郷村大字戸来字野月33-1", left: 50, top: 29, width: 7, height: 10 },
  { id: "pyramid", label: "大石神ピラミッド", query: "大石神ピラミッド 青森県三戸郡新郷村大字戸来字雨池11-41", left: 18, top: 39, width: 15, height: 11 },
  { id: "nishikoshi", label: "西越三嶽神社", query: "西越三嶽神社 青森県三戸郡新郷村大字西越字林ノ前62-2", left: 66, top: 52, width: 14, height: 13 },
  { id: "green", label: "道の駅しんごう・間木ノ平グリーンパーク", query: "道の駅しんごう 青森県三戸郡新郷村大字戸来字雨池11-2", left: 20, top: 57, width: 18, height: 15 },
  { id: "mizu", label: "水芭蕉群生地", query: "水芭蕉群生地 菅場 新郷村", left: 7, top: 71, width: 13, height: 12 },
  { id: "onsen", label: "新郷温泉館（伝説の湯の里）", query: "新郷温泉館 青森県三戸郡新郷村大字西越字温泉沢5-4", left: 36, top: 69, width: 15, height: 15 },
];

const landscapeMq = window.matchMedia("(orientation: landscape)");

let root;
let state = load();
let view = { name: "home" };

function esc(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function isObj(value) {
  return Boolean(value) && typeof value === "object" && !Array.isArray(value);
}

function load() {
  const blank = Shingo.createState();
  try {
    const raw = JSON.parse(localStorage.getItem(KEY) || "null");
    if (!isObj(raw)) return blank;
    return {
      ...blank,
      obtainedBadges: isObj(raw.obtainedBadges) ? raw.obtainedBadges : {},
      obtainedItems: isObj(raw.obtainedItems) ? raw.obtainedItems : {},
      scans: isObj(raw.scans) ? raw.scans : {},
      consumed: isObj(raw.consumed) ? raw.consumed : {},
      demoDayOffset: Number.isInteger(raw.demoDayOffset) ? raw.demoDayOffset : 0,
      demoForceItemId: raw.demoForceItemId === "sato" ? "sato" : null,
    };
  } catch (error) {
    return blank;
  }
}

function save() {
  try {
    localStorage.setItem(KEY, JSON.stringify(state));
  } catch (error) {
    /* The prototype still runs for this tab if storage is blocked. */
  }
}

function today() {
  return Shingo.currentDateKey(state);
}

/* ---------- 部品 ---------- */

function artHtml(spotId, extraClass = "", label = "") {
  const pos = ART[spotId];
  if (!pos) return "";
  const aria = label ? ` role="img" aria-label="${esc(label)}"` : ' aria-hidden="true"';
  return `<span class="art ${extraClass}" style="--x:${pos[0]};--y:${pos[1]}"${aria}></span>`;
}

function hankoHtml(itemId, extraClass = "") {
  const look = ITEM_LOOK[itemId] || { glyph: "？", color: "#999" };
  return `<span class="hanko ${extraClass}" style="--c:${look.color}" aria-hidden="true">${esc(look.glyph)}</span>`;
}

function stampsHtml() {
  return Shingo.spots.map((spot) => {
    const got = Boolean(state.obtainedBadges[spot.id]);
    return `
      <li class="stamp-slot${got ? " is-got" : ""}">
        ${artHtml(spot.id, got ? "" : "is-locked", got ? spot.name : "未獲得")}
        ${got ? '<span class="stamp-done" aria-hidden="true">済</span>' : ""}
        <span class="stamp-name">${got ? esc(spot.name) : "？？？"}</span>
      </li>
    `;
  }).join("");
}

/* ---------- 画面 ---------- */

function homeHtml() {
  const key = today();
  const prog = Shingo.progress(state);
  const visited = Shingo.spots.filter((spot) => state.scans[spot.id] === key);
  const left = prog.badgeTotal - prog.badges;
  const todayList = visited.length
    ? `<ul class="chips">${visited.map((spot) => `<li>${artHtml(spot.id, "chip-art")}${esc(spot.name)}</li>`).join("")}</ul>`
    : `<p class="empty">今日はまだ読み取っていません。<br>近くのスポットでQRを探してみよう！</p>`;
  return `
    <section class="hero">
      <div class="hero-img" aria-hidden="true"></div>
      <div class="hero-text">
        <p class="hero-kicker">青森県 新郷村へ ようこそ</p>
        <h1>スポットをめぐって<br>バッジを集めよう</h1>
      </div>
    </section>

    <section class="card stampcard">
      <div class="card-head">
        <h2>スタンプ帳</h2>
        <p class="count"><b>${prog.badges}</b> / ${prog.badgeTotal}</p>
      </div>
      <ol class="stamps">${stampsHtml()}</ol>
      <div class="bar" aria-hidden="true"><span style="width:${(prog.badges / prog.badgeTotal) * 100}%"></span></div>
      <p class="card-foot">${left ? `あと <b>${left}</b> か所でバッジコンプリート！` : "バッジコンプリート！おめでとうございます"}</p>
    </section>

    <button type="button" class="qr-cta" data-action="start-scan">
      <span class="qr-icon">${ICONS.qr}</span>
      <span class="qr-text"><b>QRを読み込む</b><small>スポットにあるQRコードをスキャン</small></span>
      <span class="qr-arrow">${ICONS.chevron}</span>
    </button>
    <p class="hint">QRを読み取ると、その地点のバッジと、アイテムが1つ届きます。同じ地点は1日1回です。</p>

    <div class="tiles">
      <button type="button" class="tile tile-item" data-action="go" data-view="items">
        <span class="tile-icon">${ICONS.item}</span>
        <span class="tile-label">アイテム</span>
        <span class="tile-num"><b>${prog.items}</b>/${prog.itemTotal}</span>
      </button>
      <button type="button" class="tile tile-benefit" data-action="go" data-view="benefits">
        <span class="tile-icon">${ICONS.benefit}</span>
        <span class="tile-label">特典</span>
        <span class="tile-num"><b>${prog.benefits}</b>/${prog.benefitTotal}</span>
      </button>
    </div>

    <h2 class="block-title">今日の読み取り</h2>
    ${todayList}
  `;
}

function rulesHtml() {
  const sato = Shingo.benefits[0];
  const complete = Shingo.benefits[1];
  return `
    <section class="card">
      <h2 class="card-title">特典の内容</h2>
      <ul class="rules">
        <li>郷のきみを獲得すると、「${esc(sato.title)}」</li>
        <li>バッジ${Shingo.spots.length}つとアイテム${Shingo.items.length}個をすべて集めると、「${esc(complete.title)}」</li>
        <li>どちらも、${esc(Shingo.TERM)}</li>
        <li>使うときは、担当者が消費済みにします</li>
      </ul>
    </section>
  `;
}

function demoHtml() {
  const key = today();
  const offset = state.demoDayOffset || 0;
  const dateLine = offset === 0
    ? `基準日は${Shingo.formatDisplay(key)}です。`
    : `基準日は${Shingo.formatDisplay(key)}です。日付を${offset}日進めています。`;
  const satoOwned = Boolean(state.obtainedItems.sato);
  const armed = state.demoForceItemId === "sato";
  const complete = Shingo.isUnlocked(state, "complete");
  let forceLabel = "次の1回は郷のきみを出す";
  if (satoOwned) forceLabel = "郷のきみは所持済み";
  else if (armed) forceLabel = "次は郷のきみを出します";
  return `
    <section class="demo">
      <h2>デモ用</h2>
      <p>客先で流れを見せるための操作です。本番の画面には出しません。</p>
      <p>${esc(dateLine)}</p>
      ${armed ? '<p class="armed">次の読み取りでは、郷のきみを出します。</p>' : ""}
      <button type="button" data-action="arm-sato" ${satoOwned || armed ? "disabled" : ""}>${esc(forceLabel)}</button>
      ${armed ? '<button type="button" data-action="clear-force">指定をやめる</button>' : ""}
      <button type="button" data-action="grant-all" ${complete ? "disabled" : ""}>${complete ? "すでに全コンプリート" : "全コンプリートにする"}</button>
      <button type="button" data-action="advance-day">日付を1日進める</button>
      <button type="button" data-action="open-reset">記録をリセット</button>
    </section>
  `;
}

function profileHtml() {
  const prog = Shingo.progress(state);
  return `
    <h1 class="page-title">マイページ</h1>
    <p class="lead">記録はこのスマホの中に保存しています。電波の届かない場所でも、このまま使えます。</p>
    <div class="stats">
      <div><b>${prog.badges}</b><span>/${prog.badgeTotal}</span><small>バッジ</small></div>
      <div><b>${prog.items}</b><span>/${prog.itemTotal}</span><small>アイテム</small></div>
      <div><b>${prog.benefits}</b><span>/${prog.benefitTotal}</span><small>特典</small></div>
    </div>
    ${rulesHtml()}
    ${demoHtml()}
  `;
}

function albumHtml(kind) {
  const isBadge = kind === "badges";
  const entries = isBadge ? Shingo.spots : Shingo.items;
  const ownedMap = isBadge ? state.obtainedBadges : state.obtainedItems;
  const prog = Shingo.progress(state);
  const count = isBadge ? prog.badges : prog.items;
  const cells = entries.map((entry) => {
    const owned = ownedMap[entry.id];
    const pic = isBadge
      ? artHtml(entry.id, owned ? "" : "is-locked")
      : owned ? hankoHtml(entry.id) : '<span class="hanko is-locked" aria-hidden="true">？</span>';
    if (!owned) {
      return `<article class="cell is-locked" aria-label="未獲得">${pic}<p class="cell-name">？？？</p></article>`;
    }
    const extra = !isBadge && entry.id === "sato" ? '<p class="ribbon">特典つき</p>' : "";
    return `
      <article class="cell is-owned">
        ${extra}
        ${pic}
        <h3 class="cell-name">${esc(entry.name)}</h3>
        <p class="date">${esc(Shingo.formatDisplay(owned))} 獲得</p>
      </article>
    `;
  }).join("");
  const note = count < entries.length
    ? (isBadge ? "スポットでQRを読み取るとバッジが手に入ります。" : "QRを読み取るたびに、アイテムが1つ届きます。")
    : "すべて集まっています。おめでとうございます！";
  return `
    <div class="page-head">
      <h1 class="page-title">${isBadge ? "バッジ" : "アイテム"}</h1>
      <p class="count"><b>${count}</b> / ${entries.length}</p>
    </div>
    <div class="bar" aria-hidden="true"><span style="width:${(count / entries.length) * 100}%"></span></div>
    <p class="note">${note}</p>
    <div class="grid ${isBadge ? "grid-badge" : "grid-item"}">${cells}</div>
  `;
}

function lockHint(benefitId) {
  if (benefitId === "sato") return "アイテム「郷のきみ」を手に入れると届きます";
  const prog = Shingo.progress(state);
  const b = prog.badgeTotal - prog.badges;
  const i = prog.itemTotal - prog.items;
  const parts = [];
  if (b) parts.push(`バッジあと${b}つ`);
  if (i) parts.push(`アイテムあと${i}個`);
  return `全部集めると届きます（${parts.join("・")}）`;
}

function benefitsHtml() {
  const prog = Shingo.progress(state);
  const cards = Shingo.benefits.map((benefit) => {
    if (!Shingo.isUnlocked(state, benefit.id)) {
      return `
        <article class="coupon is-locked">
          <span class="lock-icon">${ICONS.lock}</span>
          <div>
            <p class="kicker">${esc(benefit.kicker)}</p>
            <h3>？？？ クーポン</h3>
            <p class="term">${esc(lockHint(benefit.id))}</p>
          </div>
        </article>
      `;
    }
    const used = state.consumed[benefit.id];
    const completeClass = benefit.id === "complete" ? " is-complete" : "";
    return `
      <article class="coupon${completeClass}${used ? " is-used" : ""}">
        ${used ? '<p class="used-stamp">消費済み</p>' : ""}
        <p class="kicker">${esc(benefit.kicker)}</p>
        <h3>${esc(benefit.title)}</h3>
        <p class="term">${esc(benefit.term)}</p>
        ${used
          ? `<p class="used-date">${esc(Shingo.formatDisplay(used))}に消費済み</p>`
          : `<button type="button" class="staff" data-action="open-consume" data-id="${benefit.id}">担当者が消費済みにする</button>`}
      </article>
    `;
  }).join("");
  const note = prog.benefits < prog.benefitTotal
    ? "条件を達成すると、クーポンが届きます。"
    : "受け取ったクーポンです。使うときは、担当者が消費済みにします。";
  return `
    <div class="page-head">
      <h1 class="page-title">特典</h1>
      <p class="count"><b>${prog.benefits}</b> / ${prog.benefitTotal}</p>
    </div>
    <p class="note">${note}</p>
    <div class="stack">${cards}</div>
  `;
}

function spotStatus(spotId) {
  if (state.scans[spotId] === today()) return "本日読取済み";
  if (state.obtainedBadges[spotId]) return "バッジ所持済み";
  return "はじめて";
}

function scanHtml() {
  const alert = view.message ? `<p class="alert" role="alert">${esc(view.message)}</p>` : "";
  const buttons = Shingo.spots.map((spot) => {
    const disabled = state.scans[spot.id] === today();
    const status = spotStatus(spot.id);
    return `
      <button type="button" class="spot" data-action="choose-spot" data-spot="${spot.id}" ${disabled ? "disabled" : ""}>
        ${artHtml(spot.id, "spot-art")}
        <span class="spot-name">${esc(spot.name)}</span>
        <span class="spot-state${status === "はじめて" ? " is-new" : ""}">${esc(status)}</span>
      </button>
    `;
  }).join("");
  return `
    <section class="scan">
      <div class="finder" aria-hidden="true"><span></span><span></span><span></span><span></span><i>${ICONS.qr}</i><b></b></div>
      ${alert}
      <h1 class="scan-title">QRを読み込みました</h1>
      <p class="lead">カメラの代わりに、読み取った地点を選びます。</p>
      <div class="spots">${buttons}</div>
    </section>
  `;
}

const UFO_SVG = `
<svg viewBox="0 0 120 64" aria-hidden="true">
  <defs>
    <linearGradient id="ufo-dome" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e8fbff"/><stop offset="1" stop-color="#8fd3ea"/></linearGradient>
    <linearGradient id="ufo-body" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f4f6f8"/><stop offset=".55" stop-color="#b9c2cb"/><stop offset="1" stop-color="#7d8893"/></linearGradient>
  </defs>
  <path d="M38 30c0-12 10-21 22-21s22 9 22 21z" fill="url(#ufo-dome)" stroke="#5b8fa3" stroke-width="2"/>
  <path d="M46 22q4-5 9-3" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" opacity=".85"/>
  <ellipse cx="60" cy="36" rx="56" ry="14" fill="url(#ufo-body)" stroke="#66717c" stroke-width="2"/>
  <ellipse cx="60" cy="31" rx="40" ry="5" fill="#fff" opacity=".45"/>
  <g class="ufo-lights"><circle cx="22" cy="38" r="3.6"/><circle cx="41" cy="42" r="3.6"/><circle cx="60" cy="43.5" r="3.6"/><circle cx="79" cy="42" r="3.6"/><circle cx="98" cy="38" r="3.6"/></g>
  <path d="M46 49h28l-4 7H50z" fill="#66717c"/>
</svg>`;

function gachaHtml(result) {
  const rare = Boolean(result.item && result.item.id === "sato");
  const badgeMark = result.badgeNew ? "はじめて" : "所持済み";
  const itemBlock = result.item
    ? `
        <div class="beam" aria-hidden="true"></div>
        <div class="drop">
          ${rare ? '<span class="rare-tag">レア！</span>' : ""}
          ${hankoHtml(result.item.id, "hanko-lg")}
        </div>
        <p class="drop-name"><small>アイテム</small>${esc(result.item.name)}<em>はじめて</em></p>
      `
    : `<p class="drop-name is-none"><small>アイテム</small>すべて揃っています</p>`;
  const awards = result.unlocked.map((benefit) => `
    <section class="award">
      <p class="label">🎉 特典が届きました</p>
      <h3>${esc(benefit.title)}</h3>
      <p>${esc(benefit.term)}</p>
    </section>
  `).join("");
  const srText = `バッジ「${result.spot.name}」（${badgeMark}）。${result.item ? `アイテム「${result.item.name}」が届きました。` : "アイテムはすでにすべて揃っています。"}${result.unlocked.map((b) => `特典「${b.title}」が届きました。`).join("")}`;
  return `
    <div class="gacha${rare ? " is-rare" : ""}">
      <p class="sr-only" role="status">${esc(srText)}</p>
      <div class="confetti" aria-hidden="true">${"<i></i>".repeat(14)}</div>
      <div class="clouds" aria-hidden="true"><i></i><i></i><i></i></div>
      <p class="gacha-kicker">届きました！</p>
      <h2 class="gacha-place">${esc(result.spot.name)}</h2>

      <section class="stampbook" aria-hidden="true">
        <div class="stampbook-slot">
          <div class="imprint">${artHtml(result.spot.id)}<span class="seal">済</span></div>
          <div class="burst">${"<i></i>".repeat(8)}</div>
          <div class="stamper"><span class="stamper-knob"></span><span class="stamper-neck"></span><span class="stamper-base"></span></div>
          <span class="pon">ポン！</span>
        </div>
        <div class="stampbook-text">
          <span class="face-kind">バッジ</span>
          <strong>${esc(result.spot.name)}</strong>
          <em class="${result.badgeNew ? "is-new" : ""}">${badgeMark}</em>
        </div>
      </section>

      <section class="sky${result.item ? "" : " is-empty"}" aria-hidden="true">
        <div class="ufo"><div class="ufo-bob">${UFO_SVG}</div></div>
        ${itemBlock}
        <div class="grass"></div>
      </section>

      <div class="gacha-result">${awards}</div>
      <div class="gacha-actions">
        <button type="button" class="ghost" data-action="skip-gacha">スキップ</button>
        <button type="button" class="primary" data-action="close-gacha">閉じる</button>
      </div>
    </div>
  `;
}

/* ---------- マップ（横画面・全画面） ---------- */

function mapsUrl(query) {
  return `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(query)}&travelmode=driving`;
}

function placeCardHtml() {
  const place = MAP_PLACES.find((entry) => entry.id === view.place);
  if (!place) {
    return `<p class="map-tip">スポットをタップすると、ルートを確認できます</p>`;
  }
  const spot = Shingo.spots.find((entry) => entry.id === place.id);
  let chip = "";
  if (spot) {
    chip = state.obtainedBadges[spot.id]
      ? '<span class="pchip is-got">バッジ獲得済み</span>'
      : '<span class="pchip">QRスポット</span>';
  }
  const alert = view.message ? `<p class="alert" role="alert">${esc(view.message)}</p>` : "";
  return `
    <div class="place-card" role="dialog" aria-label="${esc(place.label)}">
      <button type="button" class="place-x" data-action="unpick" aria-label="閉じる">${ICONS.close}</button>
      <div class="place-top">
        ${spot ? artHtml(spot.id, "place-art") : `<span class="place-pin">${ICONS.map}</span>`}
        <div>
          ${chip}
          <h2>${esc(place.label)}</h2>
        </div>
      </div>
      ${alert}
      <a class="route-btn" data-action="route" href="${mapsUrl(place.query)}" target="_blank" rel="noopener noreferrer">${ICONS.route}Googleマップでルートを見る</a>
    </div>
  `;
}

function mapHtml() {
  const hotspots = MAP_PLACES.map((place) => `
    <button type="button" class="hotspot${view.place === place.id ? " is-active" : ""}" data-action="pick-place" data-place="${place.id}" aria-label="${esc(place.label)}" style="left:${place.left}%;top:${place.top}%;width:${place.width}%;height:${place.height}%"></button>
  `).join("");
  const pins = Shingo.spots.filter((spot) => ART[spot.id]).map((spot) => {
    const [x, y] = ART[spot.id];
    const got = Boolean(state.obtainedBadges[spot.id]);
    return `<span class="pin${got ? " is-got" : ""}" style="left:${(x / 1024) * 100}%;top:${((y - 46) / 616) * 100}%" aria-hidden="true">${got ? "✓" : "QR"}</span>`;
  }).join("");
  return `
    <div class="mapfull">
      <div class="mapfull-rot">
        <div class="mapfull-bg" aria-hidden="true"></div>
        <div class="mapfull-stage">
          <img src="${MAP_SRC}" alt="新郷村観光マップ" width="1024" height="616" draggable="false" />
          ${pins}
          ${hotspots}
        </div>
        <button type="button" class="map-close" data-action="close-map" aria-label="マップを閉じる">${ICONS.close}</button>
        <div class="map-legend" aria-hidden="true"><span class="pin-dot">QR</span>バッジがもらえる場所</div>
        ${placeCardHtml()}
        ${view.hint ? `<div class="rotate-hint" aria-hidden="true">${ICONS.rotate}<span>スマホを横にしてご覧ください</span></div>` : ""}
      </div>
    </div>
  `;
}

async function lockLandscape() {
  if (landscapeMq.matches) return;
  try {
    if (!document.fullscreenElement && document.documentElement.requestFullscreen) {
      await document.documentElement.requestFullscreen({ navigationUI: "hide" });
      if (view.name === "map") view.fs = true;
    }
    if (screen.orientation && screen.orientation.lock) {
      await screen.orientation.lock("landscape");
    }
  } catch (error) {
    /* iPhone などは向きを固定できないので、CSS で90°回転して横向き表示にする */
  }
}

function unlockLandscape() {
  try {
    if (screen.orientation && screen.orientation.unlock) screen.orientation.unlock();
  } catch (error) { /* noop */ }
  try {
    if (document.fullscreenElement && document.exitFullscreen) document.exitFullscreen();
  } catch (error) { /* noop */ }
}

function openMap() {
  const back = view.name === "map" ? view.back : view.name;
  view = { name: "map", back: PAGES.has(back) && back !== "map" ? back : "home", hint: !landscapeMq.matches };
  render();
  lockLandscape();
}

function closeMap() {
  const back = view.back || "home";
  unlockLandscape();
  show(back);
}

/* ---------- 枠 ---------- */

function bodyHtml() {
  if (view.name === "profile") return profileHtml();
  if (view.name === "badges") return albumHtml("badges");
  if (view.name === "items") return albumHtml("items");
  if (view.name === "benefits") return benefitsHtml();
  if (view.name === "scan") return scanHtml();
  return homeHtml();
}

function headerHtml() {
  if (view.name === "scan") {
    return `
      <header class="top top-scan">
        <button type="button" class="text-btn" data-action="go" data-view="home">${ICONS.close}<span>閉じる</span></button>
        <strong>読み取り</strong>
        <span></span>
      </header>
    `;
  }
  const current = view.name === "profile" ? ' aria-current="page"' : "";
  return `
    <header class="top">
      <button type="button" class="brand" data-action="go" data-view="home">
        <span class="brand-mark">${BRAND_MARK}</span>
        <span class="brand-text"><small>青森県 新郷村</small><b>${APP_NAME}</b></span>
      </button>
      <button type="button" class="icon-btn" data-action="go" data-view="profile" aria-label="マイページ"${current}>${ICONS.profile}</button>
    </header>
  `;
}

function navHtml() {
  if (view.name === "scan") return "";
  const item = (name, label, icon) => {
    const current = view.name === name ? ' aria-current="page"' : "";
    return `<button type="button" data-action="go" data-view="${name}"${current}><span class="tab-icon">${icon}</span><span>${label}</span></button>`;
  };
  return `
    <nav class="tab">
      ${item("map", "マップ", ICONS.map)}
      ${item("badges", "バッジ", ICONS.badge)}
      <button type="button" class="tab-qr" data-action="start-scan" aria-label="QRを読み込む"><span>${ICONS.qr}</span></button>
      ${item("items", "アイテム", ICONS.item)}
      ${item("benefits", "特典", ICONS.benefit)}
    </nav>
  `;
}

function dialogHtml() {
  if (!view.dialog) return "";
  if (view.dialog.type === "reset") {
    return `
      <dialog class="sheet">
        <h2>記録を消しますか</h2>
        <p>このスマホの中の収集記録を消します。デモのための操作です。</p>
        <button type="button" class="primary" data-action="confirm-reset">記録を消す</button>
        <button type="button" class="ghost" data-action="close-dialog" autofocus>やめる</button>
      </dialog>
    `;
  }
  const benefit = Shingo.benefits.find((entry) => entry.id === view.dialog.id);
  if (!benefit) return "";
  return `
    <dialog class="sheet">
      <h2>消費済みにしますか</h2>
      <p>${esc(benefit.title)}</p>
      <p>担当者が操作してください。消費済みにすると、このクーポンは使えなくなります。</p>
      <button type="button" class="primary" data-action="confirm-consume" data-id="${benefit.id}">消費済みにする</button>
      <button type="button" class="ghost" data-action="close-dialog" autofocus>やめる</button>
    </dialog>
  `;
}

function render() {
  const titles = {
    home: APP_NAME,
    profile: "マイページ",
    map: "マップ",
    badges: "バッジ",
    items: "アイテム",
    benefits: "特典",
    scan: "読み取り",
    gacha: "受け取り",
  };
  document.title = view.name === "home" ? APP_NAME : `${titles[view.name]}｜${APP_NAME}`;
  document.body.classList.toggle("is-map", view.name === "map");
  if (view.name === "map") {
    root.innerHTML = mapHtml();
    return;
  }
  const main = view.name === "gacha"
    ? gachaHtml(view.result)
    : `<main class="page-${view.name}">${bodyHtml()}</main>`;
  root.innerHTML = `${view.name === "gacha" ? "" : headerHtml()}${main}${view.name === "gacha" ? "" : navHtml()}${dialogHtml()}`;
  const dialog = root.querySelector("dialog");
  if (!dialog) return;
  dialog.addEventListener("cancel", (event) => {
    event.preventDefault();
    view.dialog = null;
    render();
  });
  dialog.addEventListener("click", (event) => {
    if (event.target !== dialog) return;
    view.dialog = null;
    render();
  });
  dialog.showModal();
}

function show(name) {
  if (name === "map") {
    openMap();
    return;
  }
  view = { name };
  render();
  const main = root.querySelector("main");
  if (main) main.scrollTop = 0;
}

function onClick(event) {
  const button = event.target.closest("[data-action]");
  if (!button || button.disabled) return;
  const action = button.dataset.action;

  if (action === "go") {
    if (PAGES.has(button.dataset.view)) show(button.dataset.view);
    return;
  }
  if (action === "close-map") {
    closeMap();
    return;
  }
  if (action === "pick-place") {
    view = { ...view, place: button.dataset.place, message: null, hint: false };
    render();
    return;
  }
  if (action === "unpick") {
    view = { ...view, place: null, message: null, hint: false };
    render();
    return;
  }
  if (action === "route") {
    if (navigator.onLine) return;
    event.preventDefault();
    view = { ...view, message: "電波がないため、Googleマップを開けません。" };
    render();
    return;
  }
  if (action === "start-scan") {
    show("scan");
    return;
  }
  if (action === "choose-spot") {
    const result = Shingo.scan(state, button.dataset.spot, today());
    if (!result.ok) {
      const message = result.reason === "already-scanned"
        ? "この地点は今日すでに読み取っています。"
        : "地点を読み取れませんでした。";
      view = { name: "scan", message };
      render();
      return;
    }
    state = result.state;
    save();
    view = { name: "gacha", result };
    render();
    return;
  }
  if (action === "skip-gacha") {
    const stage = root.querySelector(".gacha");
    if (stage) stage.classList.add("is-skipped");
    return;
  }
  if (action === "close-gacha") {
    show("home");
    return;
  }
  if (action === "open-consume") {
    view = { ...view, dialog: { type: "consume", id: button.dataset.id } };
    render();
    return;
  }
  if (action === "confirm-consume") {
    const result = Shingo.consume(state, button.dataset.id, today());
    if (result.ok) {
      state = result.state;
      save();
    }
    view = { ...view, dialog: null };
    render();
    return;
  }
  if (action === "close-dialog") {
    view = { ...view, dialog: null };
    render();
    return;
  }
  if (action === "advance-day") {
    state = Shingo.advanceDay(state);
    save();
    render();
    return;
  }
  if (action === "arm-sato") {
    state = Shingo.armSato(state);
    save();
    render();
    return;
  }
  if (action === "clear-force") {
    state = { ...state, demoForceItemId: null };
    save();
    render();
    return;
  }
  if (action === "grant-all") {
    state = Shingo.grantAll(state, today());
    save();
    show("benefits");
    return;
  }
  if (action === "open-reset") {
    view = { ...view, dialog: { type: "reset" } };
    render();
    return;
  }
  if (action === "confirm-reset") {
    state = Shingo.createState();
    save();
    show("home");
  }
}

function init() {
  root = document.getElementById("app");
  root.addEventListener("click", onClick);
  /* 端末を横にしたら案内を消す */
  landscapeMq.addEventListener("change", () => {
    if (view.name === "map" && view.hint) {
      view = { ...view, hint: false };
      render();
    }
  });
  /* Android の戻る操作などで全画面が解除されたらマップを閉じる */
  document.addEventListener("fullscreenchange", () => {
    if (!document.fullscreenElement && view.name === "map" && view.fs) closeMap();
  });
  render();
}

init();
