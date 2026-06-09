/* NutriVault Marketing Website — app.js */

// ===== NAVBAR SCROLL =====
const navbar = document.getElementById('navbar');
const scrollThreshold = 20;
window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > scrollThreshold);
}, { passive: true });

// ===== MOBILE MENU =====
const hamburger = document.getElementById('hamburger');
const mobileMenu = document.getElementById('mobile-menu');
let menuOpen = false;

hamburger.addEventListener('click', () => {
  menuOpen = !menuOpen;
  hamburger.setAttribute('aria-expanded', menuOpen);
  mobileMenu.classList.toggle('open', menuOpen);
  mobileMenu.setAttribute('aria-hidden', !menuOpen);
  hamburger.innerHTML = menuOpen
    ? '<span class="material-symbols-outlined">close</span>'
    : '<span class="material-symbols-outlined">menu</span>';
});

// Close mobile menu when clicking a link
document.querySelectorAll('.mobile-link, .mobile-cta').forEach(link => {
  link.addEventListener('click', () => {
    menuOpen = false;
    mobileMenu.classList.remove('open');
    mobileMenu.setAttribute('aria-hidden', 'true');
    hamburger.setAttribute('aria-expanded', 'false');
    hamburger.innerHTML = '<span class="material-symbols-outlined">menu</span>';
  });
});

// ===== HERO SCREENSHOT ROTATOR =====
const screens = document.querySelectorAll('.screen-img');
const dots    = document.querySelectorAll('.dot');
let currentScreen = 0;
let autoRotate;

function showScreen(index) {
  screens.forEach((s, i) => {
    s.classList.toggle('active', i === index);
    if (i === index) { s.style.position = 'relative'; }
    else { s.style.position = 'absolute'; }
  });
  dots.forEach((d, i) => d.classList.toggle('active', i === index));
  currentScreen = index;
}

function startAutoRotate() {
  autoRotate = setInterval(() => {
    showScreen((currentScreen + 1) % screens.length);
  }, 3000);
}

dots.forEach(dot => {
  dot.addEventListener('click', () => {
    clearInterval(autoRotate);
    showScreen(parseInt(dot.dataset.screen));
    startAutoRotate();
  });
});

// Init
showScreen(0);
startAutoRotate();

// ===== STAT COUNTER ANIMATION =====
function animateCounter(el) {
  const target = parseInt(el.dataset.target);
  const isDecimal = el.dataset.decimal === '1';
  const duration = 2000;
  const step = 16;
  const steps = duration / step;
  let current = 0;
  const increment = target / steps;

  const timer = setInterval(() => {
    current = Math.min(current + increment, target);
    if (isDecimal) {
      el.textContent = (current / 10).toFixed(1);
    } else if (target >= 1000) {
      el.textContent = (current >= 1000)
        ? (current / 1000).toFixed(current < 10000 ? 0 : 0) + 'K'
        : Math.floor(current).toString();
      // For 500K+
      if (target === 500000) el.textContent = Math.floor(current / 1000) + 'K';
    } else {
      el.textContent = Math.floor(current);
    }
    if (current >= target) clearInterval(timer);
  }, step);
}

// ===== REVEAL ON SCROLL (IntersectionObserver) =====
const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const el = entry.target;
      const delay = getComputedStyle(el).getPropertyValue('--delay') || '0ms';
      setTimeout(() => el.classList.add('visible'), parseInt(delay));
      revealObserver.unobserve(el);

      // Trigger stat counters when stats bar is visible
      if (el.classList.contains('stats-bar') || el.closest('.stats-bar')) {
        document.querySelectorAll('.stat-value[data-target]').forEach(animateCounter);
      }
    }
  });
}, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });

document.querySelectorAll('.reveal').forEach(el => revealObserver.observe(el));

// Also observe stats-bar itself for counter trigger
const statsBar = document.querySelector('.stats-bar');
if (statsBar) {
  const statsObserver = new IntersectionObserver((entries) => {
    if (entries[0].isIntersecting) {
      document.querySelectorAll('.stat-value[data-target]').forEach(animateCounter);
      statsObserver.disconnect();
    }
  }, { threshold: 0.4 });
  statsObserver.observe(statsBar);
}

// ===== FAQ ACCORDION =====
document.querySelectorAll('.faq-question').forEach(btn => {
  btn.addEventListener('click', () => {
    const expanded = btn.getAttribute('aria-expanded') === 'true';
    // Close all
    document.querySelectorAll('.faq-question').forEach(b => {
      b.setAttribute('aria-expanded', 'false');
    });
    document.querySelectorAll('.faq-answer').forEach(a => a.classList.remove('open'));
    // Open clicked if it was closed
    if (!expanded) {
      btn.setAttribute('aria-expanded', 'true');
      const answerId = btn.id.replace('faq-q', 'faq-a');
      const answer = document.getElementById(answerId);
      if (answer) answer.classList.add('open');
    }
  });
});

// ===== SMOOTH NAV LINK ACTIVE STATE =====
const sections = document.querySelectorAll('section[id]');
const navLinks = document.querySelectorAll('.nav-link');

const sectionObserver = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const id = entry.target.getAttribute('id');
      navLinks.forEach(link => {
        link.classList.toggle(
          'active-nav',
          link.getAttribute('href') === `#${id}`
        );
        link.style.color = link.classList.contains('active-nav') ? '#C8F135' : '';
      });
    }
  });
}, { rootMargin: '-50% 0px -50% 0px' });

sections.forEach(s => sectionObserver.observe(s));

// ===== GOOGLE PLAY BUTTON PLACEHOLDER =====
// When Play Store URL is live, replace '#download' with actual URL
const PLAY_STORE_URL = '#download'; // Update this when approved
document.querySelectorAll('#hero-play-btn, #footer-play-btn, #download-play-btn').forEach(btn => {
  if (btn.tagName === 'A' && btn.id === 'download-play-btn') {
    btn.href = PLAY_STORE_URL;
  }
});

// ===== INIT =====
window.addEventListener('DOMContentLoaded', () => {
  // Add scrolled class immediately if page loads mid-scroll
  if (window.scrollY > scrollThreshold) navbar.classList.add('scrolled');
  console.log('🥗 NutriVault website initialized. Built with Advanced AI + Stitch.');
});
