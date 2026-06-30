window.RECEIPT_APP_SUPABASE = {
  url: "https://mzueulhlyuyicwwgjpww.supabase.co",
  anonKey: "sb_publishable_Bm_Du48iTUZqsHhMH1N7tg_scBCQ1Lp"
};

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
