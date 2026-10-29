(() => {
  'use strict';
  let busy = false;
  const refresh = async () => {
    if (busy || document.hidden) return;
    busy = true;
    try {
      const response = await fetch('/admin/incidents/counts', {credentials:'same-origin',headers:{Accept:'application/json'}});
      if (!response.ok || !response.headers.get('content-type')?.includes('application/json')) return;
      const counts = await response.json();
      if (!Number.isSafeInteger(counts.open) || !Number.isSafeInteger(counts.sos) || counts.open < 0 || counts.sos < 0) return;
      document.querySelectorAll('[data-incident-count]').forEach(node => {node.textContent = String(counts.open);node.hidden = counts.open === 0 && node.hasAttribute('data-hide-zero');});
      document.querySelectorAll('[data-incident-sos]').forEach(node => {node.textContent = String(counts.sos);});
      const banner = document.getElementById('incident-banner');
      if (banner) {banner.hidden = counts.open === 0;banner.classList.toggle('alert-danger',counts.sos > 0);banner.classList.toggle('alert-warning',counts.sos === 0);}
    } catch { /* Retain the last confirmed counts while offline. */ }
    finally {busy = false;}
  };
  setInterval(refresh, 20000);
  document.addEventListener('visibilitychange', () => {if (!document.hidden) refresh();});
})();
