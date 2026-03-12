(function () {
  const modeValues = ["light", "dark"];

  function getStorageKey() {
    const explicitBase = document.documentElement.getAttribute("data-site-baseurl");
    const pathParts = window.location.pathname.split("/").filter(Boolean);
    const inferredBase = pathParts.length > 0 ? "/" + pathParts[0] : "";
    const base = explicitBase || inferredBase;
    return "azure-training-site-theme:" + base;
  }

  function safeGetStoredMode() {
    try {
      return window.localStorage.getItem(getStorageKey());
    } catch (error) {
      return null;
    }
  }

  function safeSetStoredMode(mode) {
    try {
      window.localStorage.setItem(getStorageKey(), mode);
    } catch (error) {
      // Ignore storage failures and keep mode for current page session.
    }
  }

  function getSystemTheme() {
    if (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches) {
      return "dark";
    }
    return "light";
  }

  function getInitialMode() {
    const stored = safeGetStoredMode();
    if (modeValues.includes(stored)) {
      return stored;
    }
    return getSystemTheme();
  }

  function applyMode(mode) {
    const theme = mode;
    document.documentElement.setAttribute("data-theme", theme);
    document.documentElement.setAttribute("data-theme-mode", mode);
    safeSetStoredMode(mode);

    const button = document.querySelector(".theme-toggle");
    if (!button) {
      return;
    }

    const isDark = theme === "dark";
    const label = isDark ? "Dark mode" : "Light mode";
    const nextLabel = isDark ? "Switch to light mode" : "Switch to dark mode";

    button.setAttribute("aria-label", nextLabel);
    button.setAttribute("title", nextLabel);
    button.setAttribute("aria-pressed", String(isDark));

    const textNode = button.querySelector(".theme-toggle-text");
    const iconNode = button.querySelector(".theme-toggle-icon");

    if (textNode) {
      textNode.textContent = label;
    }

    if (iconNode) {
      iconNode.textContent = isDark ? "◐" : "☀";
    }
  }

  function mountToggle() {
    if (document.querySelector(".theme-toggle")) {
      return;
    }

    if (!document.body) {
      window.requestAnimationFrame(mountToggle);
      return;
    }

    const button = document.createElement("button");
    button.type = "button";
    button.className = "theme-toggle";
    button.setAttribute("aria-pressed", "false");
    button.innerHTML = '<span class="theme-toggle-icon" aria-hidden="true">☀</span><span class="theme-toggle-text">Light mode</span>';
    button.addEventListener("click", function () {
      const currentMode = document.documentElement.getAttribute("data-theme-mode") === "dark" ? "dark" : "light";
      applyMode(currentMode === "dark" ? "light" : "dark");
    });
    document.body.appendChild(button);
  }

  function listenToSystemThemeChanges() {
    if (!window.matchMedia) {
      return;
    }

    const media = window.matchMedia("(prefers-color-scheme: dark)");
    const onChange = function () {
      const storedMode = safeGetStoredMode();
      if (storedMode !== "dark" && storedMode !== "light") {
        applyMode(getSystemTheme());
      }
    };

    if (typeof media.addEventListener === "function") {
      media.addEventListener("change", onChange);
    } else if (typeof media.addListener === "function") {
      media.addListener(onChange);
    }
  }

  function initThemeToggle() {
    applyMode(getInitialMode());
    mountToggle();
    applyMode(getInitialMode());
    listenToSystemThemeChanges();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initThemeToggle, { once: true });
  } else {
    initThemeToggle();
  }
})();
