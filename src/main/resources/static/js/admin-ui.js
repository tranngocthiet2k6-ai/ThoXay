'use strict';

(() => {
  const fold = value => value.toLocaleLowerCase('vi').normalize('NFD')
    .replace(/\p{M}/gu, '').replace(/đ/g, 'd');
  for (const panel of document.querySelectorAll('[data-filter-panel]')) {
    const search = panel.querySelector('[data-filter-search]');
    const selects = [...panel.querySelectorAll('[data-filter-select]')];
    const rows = [...panel.querySelectorAll('[data-filter-row]')];
    const count = panel.querySelector('[data-filter-count]');
    const empty = panel.querySelector('[data-filter-empty]');
    const update = () => {
      const terms = fold(search?.value || '').trim().split(/\s+/).filter(Boolean);
      let visible = 0;
      for (const row of rows) {
        const match = terms.every(term => fold(row.textContent).includes(term)) &&
          selects.every(select => !select.value || row.dataset[select.dataset.filterSelect] === select.value);
        row.hidden = !match;
        if (match) visible++;
      }
      if (count) count.textContent = `Hiển thị ${visible} / ${rows.length} kết quả trên trang này`;
      if (empty) empty.hidden = visible > 0 || rows.length === 0;
    };
    search?.addEventListener('input', update);
    selects.forEach(select => select.addEventListener('change', update));
    panel.querySelector('[data-filter-clear]')?.addEventListener('click', () => {
      if (search) search.value = '';
      selects.forEach(select => { select.value = ''; });
      update();
    });
    update();
  }

  const dialog = document.getElementById('kyc-lightbox');
  if (!dialog) return;
  const image = document.getElementById('kyc-zoom-image');
  const title = document.getElementById('kyc-zoom-title');
  const range = document.getElementById('kyc-zoom-range');
  const level = document.getElementById('kyc-zoom-level');
  const zoom = value => {
    const scale = Math.min(4, Math.max(1, Number(value) || 1));
    range.value = String(scale);
    image.style.width = `${scale * 100}%`;
    level.textContent = `${Math.round(scale * 100)}%`;
  };
  const reset = () => { image.removeAttribute('src'); zoom(1); };
  const close = () => { if (dialog.open) dialog.close(); reset(); };
  for (const source of document.querySelectorAll('.kyc-image')) {
    const open = () => {
      if (source.hidden || !source.getAttribute('src')) return;
      title.textContent = `Phóng to ${source.alt.toLocaleLowerCase('vi')}`;
      image.alt = source.alt;
      image.src = source.getAttribute('src');
      zoom(1);
      if (!dialog.open) dialog.showModal();
    };
    source.addEventListener('click', open);
    source.addEventListener('keydown', event => {
      if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); open(); }
    });
  }
  range.addEventListener('input', () => zoom(range.value));
  document.getElementById('kyc-zoom-in').addEventListener('click', () => zoom(Number(range.value) + .25));
  document.getElementById('kyc-zoom-out').addEventListener('click', () => zoom(Number(range.value) - .25));
  document.getElementById('kyc-zoom-close').addEventListener('click', close);
  dialog.addEventListener('close', reset);
  // Escape closes the native lightbox, without also dismissing Bootstrap's
  // enclosing KYC review and losing the administrator's place.
  dialog.addEventListener('keydown', event => {
    if (event.key === 'Escape') event.stopPropagation();
  });
  document.getElementById('kyc-modal').addEventListener('hide.bs.modal', close);
  document.getElementById('kyc-modal').addEventListener('show.bs.modal', close);
})();
