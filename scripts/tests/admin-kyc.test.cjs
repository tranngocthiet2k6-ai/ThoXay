const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function view() {
  const elements = new Map();
  const get = id => {
    if (!elements.has(id)) {
      elements.set(id, { hidden: false, disabled: true, textContent: '', value: '',
        listeners: {}, addEventListener(name, callback) { this.listeners[name] = callback; },
        removeAttribute(name) { delete this[name]; } });
    }
    return elements.get(id);
  };
  vm.runInNewContext(fs.readFileSync(path.resolve(__dirname, '../../src/main/resources/static/js/admin-kyc.js'), 'utf8'),
    { document: { getElementById: get } });
  const show = (overrides = {}) => get('kyc-modal').listeners['show.bs.modal']({ relatedTarget: { dataset: {
    userName: 'KYC fixture', verified: 'false', frontImage: 'https://example.com/front.png',
    backImage: 'https://example.com/back.png', verifyUrl: '/admin/users/7/verify', ...overrides,
  } } });
  return { get, show };
}

test('approval requires both loaded faces and submits their exact snapshots', () => {
  const { get, show } = view(); show();
  assert.equal(get('kyc-verify-button').disabled, true);
  get('kyc-front-image').onload();
  assert.equal(get('kyc-verify-button').disabled, true);
  get('kyc-back-image').onload();
  assert.equal(get('kyc-verify-button').disabled, false);
  assert.equal(get('kyc-front-snapshot').value, 'https://example.com/front.png');
  assert.equal(get('kyc-back-snapshot').value, 'https://example.com/back.png');
  assert.equal(get('kyc-verify-form').action, '/admin/users/7/verify');
  let prevented = false;
  get('kyc-verify-form').listeners.submit({ preventDefault() { prevented = true; } });
  assert.equal(prevented, false);
  assert.equal(get('kyc-verify-button').disabled, true);
});

test('missing and failed images keep approval disabled', () => {
  const { get, show } = view(); show({ backImage: '' });
  get('kyc-front-image').onload();
  assert.equal(get('kyc-verify-button').disabled, true);
  assert.match(get('kyc-back-status').textContent, /Chưa cập nhật/);
  show(); get('kyc-front-image').onload(); get('kyc-back-image').onerror();
  assert.equal(get('kyc-verify-button').disabled, true);
  assert.equal(get('kyc-back-image').hidden, true);
  assert.match(get('kyc-back-status').textContent, /Không tải được/);
});

test('switching people ignores old image loads and closing clears private image URLs', () => {
  const { get, show } = view(); show();
  const previousFrontLoad = get('kyc-front-image').onload;
  show({ userName: 'Other user', frontImage: 'https://example.com/other-front.png' });
  previousFrontLoad(); get('kyc-back-image').onload();
  assert.equal(get('kyc-verify-button').disabled, true);
  get('kyc-front-image').onload();
  assert.equal(get('kyc-verify-button').disabled, false);
  get('kyc-modal').listeners['hidden.bs.modal']();
  assert.equal(get('kyc-front-image').src, undefined);
  assert.equal(get('kyc-back-image').src, undefined);
  assert.equal(get('kyc-front-snapshot').value, '');
  assert.equal(get('kyc-back-snapshot').value, '');
  assert.equal(get('kyc-verify-button').disabled, true);
});

test('already verified and not-ready submissions are blocked', () => {
  const { get, show } = view(); show({ verified: 'true' });
  get('kyc-front-image').onload(); get('kyc-back-image').onload();
  assert.equal(get('kyc-verify-button').disabled, true);
  let prevented = false;
  get('kyc-verify-form').listeners.submit({ preventDefault() { prevented = true; } });
  assert.equal(prevented, true);
  show(); prevented = false;
  get('kyc-verify-form').listeners.submit({ preventDefault() { prevented = true; } });
  assert.equal(prevented, true);
});
