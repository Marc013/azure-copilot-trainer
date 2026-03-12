(function () {
  const storageKey = "azure-training-site-theme";

  function getPreferredTheme() {
    const stored = window.localStorage.getItem(storageKey);
    if (stored === "dark" || stored === "light") {
      return stored;
    }

    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }

  function applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    window.localStorage.setItem(storageKey, theme);

    const button = document.querySelector(".theme-toggle");
    if (!button) {
      return;
    }

    const label = theme === "dark" ? "Dark mode" : "Light mode";
    const nextLabel = theme === "dark" ? "Switch to light mode" : "Switch to dark mode";
    const icon = theme === "dark" ? "Moon" : "Sun";

    button.setAttribute("aria-label", nextLabel);
    button.setAttribute("title", nextLabel);
    button.querySelector(".theme-toggle-text").textContent = label;
    button.querySelector(".theme-toggle-icon").textContent = icon === "Moon" ? "◐" : "☀";
  }

  function mountToggle() {
    if (document.querySelector(".theme-toggle")) {
      return;
    }

    const button = document.createElement("button");
    button.type = "button";
    button.className = "theme-toggle";
    button.innerHTML = '<span class="theme-toggle-icon" aria-hidden="true">☀</span><span class="theme-toggle-text">Light mode</span>';
    button.addEventListener("click", function () {
      const current = document.documentElement.getAttribute("data-theme") === "dark" ? "dark" : "light";
      applyTheme(current === "dark" ? "light" : "dark");
    });
    document.body.appendChild(button);
  }

  document.addEventListener("DOMContentLoaded", function () {
    mountToggle();
    applyTheme(getPreferredTheme());
  });
})();
