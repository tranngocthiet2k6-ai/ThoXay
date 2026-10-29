const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function element(extra = {}) {
  return { value: '', textContent: '', hidden: false, dataset: {}, style: {}, listeners: {},
    addEventListener(name, callback) { this.listeners[name] = callback; },
    getAttribute(name) { return this[name] || null; },
    removeAttribute(name) { delete this[name]; }, ...extra };
}
function view(withLightbox = false) {
  const rows = [
    element({ textContent: 'Nguyễn Văn Đức 0900000001', dataset: { filterState: 'PENDING', filterActive: 'ACTIVE' } }),
    element({ textContent: 'Trần An 0900000002', dataset: { filterState: 'VERIFIED', filterActive: 'LOCKED' } }),
  ];
  const search = element(), state = element({ dataset: { filterSelect: 'filterState' } });
  const active = element({ dataset: { filterSelect: 'filterActive' } });
  const count = element(), empty = element(), clear = element();
  const controls = { '[data-filter-search]': search, '[data-filter-count]': count,
    '[data-filter-empty]': empty, '[data-filter-clear]': clear };
  const panel = { querySelector: key => controls[key],
    querySelectorAll: key => key === '[data-filter-row]' ? rows : [state, active] };
  const ids = new Map();
  for (const id of ['kyc-modal','kyc-zoom-image','kyc-zoom-title','kyc-zoom-range','kyc-zoom-level','kyc-zoom-in','kyc-zoom-out','kyc-zoom-close']) ids.set(id, element());
  const dialog = element({ open: false, showModal() { this.open = true; }, close() { this.open = false; this.listeners.close?.(); } });
  if (withLightbox) ids.set('kyc-lightbox', dialog);
  const face = element({ hidden: true, src: '/admin/kyc/images/example', alt: 'Ảnh mặt trước CCCD' });
  vm.runInNewContext(fs.readFileSync(path.resolve(__dirname, '../../src/main/resources/static/js/admin-ui.js'), 'utf8'), {
    document: { getElementById: id => ids.get(id),
      querySelectorAll: key => key === '[data-filter-panel]' ? [panel] : [face] },
  });
  return { rows, search, state, active, count, empty, clear, face, dialog, get: id => ids.get(id) };
}
test('Vietnamese search and multiple status filters combine, and reset restores rendered rows', () => {
  const v = view();
  v.search.value = 'nguyen duc'; v.search.listeners.input();
  assert.deepEqual(v.rows.map(r => r.hidden), [false, true]);
  v.state.value = 'VERIFIED'; v.state.listeners.change();
  assert.deepEqual(v.rows.map(r => r.hidden), [true, true]);
  assert.equal(v.empty.hidden, false);
  assert.match(v.count.textContent, /0 \/ 2/);
  v.clear.listeners.click();
  assert.deepEqual(v.rows.map(r => r.hidden), [false, false]);
  v.active.value = 'LOCKED'; v.active.listeners.change();
  assert.deepEqual(v.rows.map(r => r.hidden), [true, false]);
});
test('lightbox only opens visible loaded faces, supports keyboard and clears private URLs on parent close', () => {
  const v = view(true);
  v.face.listeners.click(); assert.equal(v.dialog.open, false);
  v.face.hidden = false;
  let prevented = false;
  v.face.listeners.keydown({ key: 'Enter', preventDefault() { prevented = true; } });
  assert.equal(prevented, true); assert.equal(v.dialog.open, true);
  assert.equal(v.get('kyc-zoom-image').src, v.face.src);
  let stopped = false;
  v.dialog.listeners.keydown({ key: 'Escape', stopPropagation() { stopped = true; } });
  assert.equal(stopped, true);
  v.get('kyc-zoom-range').value = '3'; v.get('kyc-zoom-range').listeners.input();
  assert.equal(v.get('kyc-zoom-image').style.width, '300%');
  v.get('kyc-modal').listeners['hide.bs.modal']();
  assert.equal(v.dialog.open, false);
  assert.equal(v.get('kyc-zoom-image').src, undefined);
  assert.equal(v.get('kyc-zoom-level').textContent, '100%');
});
test('lightbox zoom stays bounded and native dialog close clears the image', () => {
  const v = view(true); v.face.hidden = false; v.face.listeners.click();
  v.get('kyc-zoom-range').value = '99'; v.get('kyc-zoom-range').listeners.input();
  assert.equal(v.get('kyc-zoom-range').value, '4');
  v.dialog.close(); assert.equal(v.get('kyc-zoom-image').src, undefined);
});
