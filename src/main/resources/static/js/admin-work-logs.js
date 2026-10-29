(() => {
  'use strict';
  const modal = document.getElementById('photoZoom');
  const image = document.getElementById('fullPhoto');
  modal.addEventListener('show.bs.modal', event => {
    const trigger = event.relatedTarget;
    const url = trigger?.dataset.image || '';
    if (!/^\/admin\/work-logs\/[0-9]+\/photo$/.test(url)) return;
    image.src = url;
    document.getElementById('photoTitle').textContent = trigger.dataset.caption || 'Ảnh cuối ngày';
  });
  modal.addEventListener('hidden.bs.modal', () => image.removeAttribute('src'));
})();
