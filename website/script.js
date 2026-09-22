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

// Scroll-reveal: fade/slide cards in as they enter the viewport. Skipped for
// prefers-reduced-motion (cards stay visible via the CSS media query either way).
document.addEventListener("DOMContentLoaded", () => {
  const targets = document.querySelectorAll(".card, .screen-item, .creator-card, .price-card");
  if (!targets.length) return;
  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  document.body.classList.add("reveal-ready");

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    },
    { threshold: 0.15, rootMargin: "0px 0px -40px 0px" }
  );

  targets.forEach((el) => observer.observe(el));
});
