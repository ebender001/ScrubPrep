// Mobile nav toggle — shared across every page. No-ops safely if the markup
// (nav-toggle button / site-nav) isn't present on a given page.
document.addEventListener("DOMContentLoaded", () => {
  const toggle = document.querySelector(".nav-toggle");
  const nav = document.querySelector("nav.site-nav");
  if (!toggle || !nav) return;

  toggle.addEventListener("click", () => {
    const isOpen = nav.classList.toggle("open");
    toggle.setAttribute("aria-expanded", String(isOpen));
  });

  nav.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", () => {
      nav.classList.remove("open");
      toggle.setAttribute("aria-expanded", "false");
    });
  });
});

// Hero jumbotron: cycle through background videos, one after another.
// Skipped entirely for prefers-reduced-motion — the poster frame stays put.
document.addEventListener("DOMContentLoaded", () => {
  const heroVideo = document.querySelector(".hero-video-bg");
  if (!heroVideo) return;
  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  const sources = [
    "assets/videos/hero-1.mp4",
    "assets/videos/hero-2.mp4",
    "assets/videos/hero-3.mp4",
    "assets/videos/hero-4.mp4",
  ];
  let index = 0;

  heroVideo.addEventListener("ended", () => {
    index = (index + 1) % sources.length;
    heroVideo.src = sources[index];
    heroVideo.play().catch(() => {});
  });

  heroVideo.play().catch(() => {});
});
