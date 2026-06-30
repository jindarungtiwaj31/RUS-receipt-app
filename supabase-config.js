window.RECEIPT_APP_SUPABASE = {
  url: "https://mzueulhlyuyicwwgjpww.supabase.co",
  anonKey: "sb_publishable_Bm_Du48iTUZqsHhMH1N7tg_scBCQ1Lp"
};

// User login rule:
// User can enter the system with only a 4-digit code created by Admin.
// No default/demo User code should be available before Admin creates it.
window.RECEIPT_APP_REQUIRE_ADMIN_CREATED_USER = true;

(function removeDefaultDemoUserCode() {
  const key = "rus_receipt_v5";
  const isDemoUser = (u) => u && u.code === "1001" && u.name === "เจ้าหน้าที่รับเงิน";

  function cleanStateData(data) {
    if (!data || !Array.isArray(data.users)) return { data, changed: false };
    const users = data.users.filter((u) => !isDemoUser(u));
    const changed = users.length !== data.users.length;
    return changed ? { data: { ...data, users }, changed } : { data, changed: false };
  }

  try {
    const raw = localStorage.getItem(key);
    if (!raw) {
      localStorage.setItem(key, JSON.stringify({ users: [] }));
    } else {
      const result = cleanStateData(JSON.parse(raw));
      if (result.changed) localStorage.setItem(key, JSON.stringify(result.data));
    }
  } catch (err) {
    console.warn("Cannot clean local default user", err);
  }

  async function cleanRemoteState() {
    const cfg = window.RECEIPT_APP_SUPABASE || {};
    if (!cfg.url || !cfg.anonKey || !window.supabase) return;

    try {
      const client = window.supabase.createClient(cfg.url, cfg.anonKey);
      const res = await client.from("app_state").select("data").eq("id", "main").single();
      if (res.error || !res.data || !res.data.data) return;

      const result = cleanStateData(res.data.data);
      if (result.changed) {
        await client.from("app_state").upsert({ id: "main", data: result.data });
      }
    } catch (err) {
      console.warn("Cannot clean remote default user", err);
    }
  }

  window.addEventListener("load", () => setTimeout(cleanRemoteState, 800));
})();

// Receipt print assets
// Loaded here because index.html already imports this file before the app code.
window.RECEIPT_APP_ASSETS = {
  garuda: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Emblem_of_Thailand.svg/250px-Emblem_of_Thailand.svg.png",
  watermark: "https://www.xzyx.org/wp-content/uploads/2024/07/rmutsb-logo-1.png"
};

(function applyReceiptLogos() {
  const assets = window.RECEIPT_APP_ASSETS || {};
  const garuda = assets.garuda;
  const watermark = assets.watermark;
  if (!garuda || !watermark) return;

  const style = document.createElement("style");
  style.id = "receipt-logo-assets";
  style.textContent = `
    .logo {
      background: #fff url("${watermark}") center/82% auto no-repeat !important;
      color: transparent !important;
      text-indent: -9999px !important;
      overflow: hidden !important;
    }

    .garuda {
      background: transparent url("${garuda}") center/contain no-repeat !important;
      border: 0 !important;
      color: transparent !important;
      text-indent: -9999px !important;
      overflow: hidden !important;
    }

    .wm {
      inset: 64mm 0 0 !important;
      height: 70mm !important;
      background: transparent url("${watermark}") center top/50mm auto no-repeat !important;
      opacity: .085 !important;
      color: transparent !important;
      text-indent: -9999px !important;
      overflow: hidden !important;
      z-index: 0 !important;
    }

    .page .rhead,
    .page p,
    .page .rtab,
    .page .right {
      position: relative;
      z-index: 1;
    }
  `;

  if (document.head) document.head.appendChild(style);
  else document.addEventListener("DOMContentLoaded", () => document.head.appendChild(style));
})();
