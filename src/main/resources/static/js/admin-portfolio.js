(() => {
  'use strict';
  const modal = document.getElementById('photoZoom');
  const image = document.getElementById('fullPhoto');
  modal.addEventListener('show.bs.modal', event => {
    const trigger = event.relatedTarget;
    const url = trigger?.dataset.image || '';
    if (!/^\/admin\/portfolio\/photos\/[a-f0-9-]{36}$/.test(url)) return;
    image.src = url;
    document.getElementById('photoTitle').textContent = trigger.dataset.caption || 'Ảnh tay nghề';
  });
  modal.addEventListener('hidden.bs.modal', () => image.removeAttribute('src'));
})();
