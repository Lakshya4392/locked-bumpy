{{flutter_js}}
{{flutter_build_config}}

// SharedPreferences keeps a separate in-memory copy in each Flutter tab.
// Reopen on a privacy change in another tab so an old nursery cannot remain visible.
let reopening = false;
function reopenPrivately() {
  if (reopening) return;
  reopening = true;
  document.documentElement.style.visibility = "hidden";
  window.location.reload();
}

window.addEventListener("storage", (event) => {
  if (event.storageArea !== window.localStorage) return;
  const pause = event.key === "flutter.is_paused" && event.newValue === "true";
  const erase = event.key === "flutter.erase_in_progress" || event.key === null;
  if (pause || erase) reopenPrivately();
});

// A browser can restore a frozen document after an erasure in another tab.
window.addEventListener("pageshow", (event) => {
  if (event.persisted) reopenPrivately();
});

const opening = document.getElementById("opening");
const status = document.getElementById("opening-status");
const retry = document.getElementById("opening-retry");

function showRetry(message) {
  if (opening.isConnected) {
    status.textContent = message;
    retry.hidden = false;
  }
}

const slowStart = window.setTimeout(
  () => showRetry("Little Bumpy is taking a little longer to open."),
  15000,
);
window.addEventListener("flutter-first-frame", () => {
  window.clearTimeout(slowStart);
  opening.remove();
}, { once: true });

function openingFailed() {
  window.clearTimeout(slowStart);
  showRetry("Little Bumpy couldn’t open.");
}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: new URL("canvaskit/", document.baseURI).href,
    fontFallbackBaseUrl: new URL("fonts/", document.baseURI).href,
  },
}).catch(openingFailed);
