'use strict';

(() => {
  const modal = document.getElementById('kyc-modal');
  if (!modal) return;
  const form = document.getElementById('kyc-verify-form');
  const button = document.getElementById('kyc-verify-button');
  const reviewStatus = document.getElementById('kyc-review-status');
  const faces = ['front', 'back'];
  let generation = 0;
  let verified = false;
  let present = {};
  let loaded = {};

  function updateReview() {
    const complete = faces.every(face => present[face]);
    const ready = complete && faces.every(face => loaded[face]);
    button.disabled = verified || !ready;
    button.textContent = verified ? 'Đã xác thực danh tính' : 'Xác thực danh tính';
    reviewStatus.textContent = verified ? 'Hồ sơ này đã được xác thực đủ hai mặt CCCD.'
      : !complete ? 'Chưa đủ ảnh mặt trước và mặt sau. Tài khoản chưa thể được xác thực.'
      : !ready ? 'Đang kiểm tra tải ảnh. Chỉ xác thực khi đã xem rõ cả hai mặt CCCD.'
      : 'Đã tải đủ hai ảnh. Hãy đối chiếu thông tin trước khi xác thực danh tính.';
  }

  function clearImages() {
    for (const face of faces) {
      const image = document.getElementById(`kyc-${face}-image`);
      image.onload = null;
      image.onerror = null;
      image.hidden = true;
      image.removeAttribute('src');
    }
  }

  modal.addEventListener('show.bs.modal', event => {
    const trigger = event.relatedTarget;
    if (!trigger) { event.preventDefault(); return; }
    generation++;
    const activeGeneration = generation;
    clearImages();
    verified = trigger.dataset.verified === 'true';
    present = {};
    loaded = {};
    document.getElementById('kyc-modal-title').textContent = `Kiểm tra CCCD — ${trigger.dataset.userName || ''}`;
    form.action = trigger.dataset.verifyUrl;

    for (const face of faces) {
      const image = document.getElementById(`kyc-${face}-image`);
      const status = document.getElementById(`kyc-${face}-status`);
      const url = trigger.dataset[`${face}Image`] || '';
      const label = face === 'front' ? 'mặt trước' : 'mặt sau';
      present[face] = /^https:\/\/[^\s]+$/.test(url);
      loaded[face] = false;
      document.getElementById(`kyc-${face}-snapshot`).value = url;
      status.hidden = false;
      status.textContent = present[face] ? `Đang tải ảnh ${label} CCCD…` : `Chưa cập nhật ảnh ${label} CCCD.`;
      if (!present[face]) continue;
      image.onload = () => {
        if (generation !== activeGeneration) return;
        loaded[face] = true;
        image.hidden = false;
        status.hidden = true;
        updateReview();
      };
      image.onerror = () => {
        if (generation !== activeGeneration) return;
        loaded[face] = false;
        image.hidden = true;
        status.hidden = false;
        status.textContent = `Không tải được ảnh ${label}. Vui lòng kiểm tra liên kết HTTPS.`;
        updateReview();
      };
      image.src = url;
    }
    updateReview();
  });

  modal.addEventListener('hidden.bs.modal', () => {
    generation++;
    clearImages();
    button.disabled = true;
    for (const face of faces) document.getElementById(`kyc-${face}-snapshot`).value = '';
  });

  form.addEventListener('submit', event => {
    if (button.disabled || verified || !faces.every(face => present[face] && loaded[face])) {
      event.preventDefault();
      return;
    }
    button.disabled = true;
    button.textContent = 'Đang xác thực…';
  });
})();
