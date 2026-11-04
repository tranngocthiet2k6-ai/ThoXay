/** Capture actual localhost DEMO UI; never contacts production or publishes credentials. */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';

const runtime = 'C:/Users/thiet/AppData/Local/OpenAI/Codex/runtimes/cua_node';
const bin = fs.readdirSync(runtime).map(d => path.join(runtime,d,'bin/node.exe'))
  .find(p => fs.existsSync(path.join(path.dirname(p),'node_modules/playwright')));
const {chromium} = createRequire(bin)('playwright');
const password = fs.readFileSync('.local/demo/access.md','utf8').match(/`([^`]+)`/)[1];
const output = '.local/commercial/captured';
fs.mkdirSync(output,{recursive:true});
const names = [
  'Thợ Xây - Đăng nhập & Vai trò', 'Thợ Xây · Tìm việc', 'Thợ Xây - Chi tiết việc',
  'Thợ Xây - Việc của tôi & Chấm công', 'Thợ Xây · Ví tiền', 'Thợ Xây - Nạp ví VietQR',
  'Thợ Xây · Hồ sơ', 'Thợ Xây - Trò chuyện', 'Thợ Xây - Bảng xếp hạng',
  'Chủ thầu - Đăng việc', 'Chủ thầu - Tạo công trình mới', 'Chủ thầu - Duyệt thợ',
  'Chủ thầu - Nghiệm thu', 'Chủ thầu - Ví & Quỹ lương', 'Chủ thầu - Hồ sơ & Thợ ruột',
  'Chủ thầu - Trò chuyện & Cam kết', '17 - Phiếu cam kết nhận việc',
  '18 - Radar GPS & QR chấm công', '19 - Trung tâm thông báo & SOS',
  '20 - Web Admin Control Center',
];
const captures=[];const errors=[];
const browser=await chromium.launch({headless:true,executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe'});
async function shot(page,index){
  await page.mouse.move(1,1);await page.waitForTimeout(1400);
  const file=names[index-1]+'.png';await page.screenshot({path:path.join(output,file)});
  const bytes=fs.readFileSync(path.join(output,file));
  captures.push({file,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),bytes:bytes.length,
    source:'Actual localhost DEMO UI',brand:'Thợ Xây',brandLogoSha256:crypto.createHash('sha256').update(fs.readFileSync('branding/logo_thoxay_transparent.png')).digest('hex'),viewport:page.viewportSize(),capturedAt:new Date().toISOString()});
  console.log(`Captured ${index}: ${names[index-1]}`);
}
async function semantics(page){await page.locator('flt-semantics-placeholder').waitFor({state:'attached'});await page.locator('flt-semantics-placeholder').evaluate(n=>n.click());}
try {
  const auth=await browser.newPage({viewport:{width:390,height:1100}});
  await auth.goto('http://127.0.0.1:3008');await semantics(auth);await auth.getByRole('button',{name:'Đăng nhập',exact:true}).waitFor();await shot(auth,1);await auth.goto('about:blank');
  for(const role of ['worker','contractor']){
    const res=await fetch('http://127.0.0.1:18083/api/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({phoneNumber:role==='worker'?'000106000003':'000106000001',password})});
    assert.equal(res.status,200);const session=await res.json();
    const context=await browser.newContext({viewport:{width:390,height:1100},permissions:['geolocation'],geolocation:{latitude:10.801815,longitude:106.714,accuracy:8}});
    await context.addInitScript(s=>{
      if(location.origin==='http://127.0.0.1:3008')localStorage.setItem('flutter.thoxay.session',JSON.stringify(JSON.stringify(s)));
    },session);
    const page=await context.newPage();page.setDefaultTimeout(20000);page.on('pageerror',e=>errors.push(e.message));
    page.on('console',m=>{if(/RenderFlex overflowed|EXCEPTION CAUGHT BY WIDGETS|EXCEPTION CAUGHT BY RENDERING/.test(m.text()))errors.push(m.text());});
    async function home(){await page.goto('http://127.0.0.1:3008');await semantics(page);await page.getByRole('tab',{name:/Hồ sơ/}).waitFor();await page.waitForTimeout(1000);}
    async function chat(){await home();await page.getByRole('button',{name:'Tin nhắn',exact:true}).click();await page.getByText(/Nhà phố ven sông/).first().click();await page.waitForTimeout(600);}
    await home();await shot(page,role==='worker'?2:10);
    if(role==='worker'){
      assert.equal(await page.getByRole('button',{name:'Ứng tuyển ngay',exact:true}).count(),0);
      await page.getByRole('button',{name:'Xem chi tiết',exact:true}).first().click();
      await page.getByRole('button',{name:'Ứng tuyển ngay',exact:true}).waitFor();await shot(page,3);
      await home();await page.getByRole('tab',{name:'Việc của tôi',exact:true}).click();await page.getByRole('button',{name:'Chấm công & ảnh cuối ngày',exact:true}).first().click();await shot(page,4);
      await page.getByRole('button',{name:'Radar GPS & QR toàn màn hình',exact:true}).click();await page.waitForTimeout(1800);
      assert.match(await page.locator('body').ariaSnapshot(),/Cách 35m/);await shot(page,18);
      await chat();await shot(page,8);await page.getByText(/Xem phiếu cam kết/).click();await page.getByRole('heading',{name:'Phiếu cam kết nhận việc'}).waitFor();
      assert.match(await page.locator('body').ariaSnapshot(),/Đã xác nhận bởi 2 bên/);await shot(page,17);
      await home();await page.getByRole('button',{name:/^Thông báo/}).first().click();await page.getByRole('button',{name:'Trung tâm hỗ trợ & SOS',exact:true}).click();await shot(page,19);
    }else{
      await page.getByRole('button',{name:'Đăng công trình mới',exact:true}).first().click();await shot(page,11);
      await home();await page.getByRole('textbox').first().fill('Tuyển thợ bảo vệ');await page.waitForTimeout(500);await page.getByRole('button',{name:'Duyệt thợ',exact:true}).first().click();await shot(page,12);
      await home();
      await page.getByRole('button',{name:'Xem chi tiết',exact:true}).first().click();
      await page.getByRole('button',{name:'Chấm công & nghiệm thu',exact:true}).first().click();
      await page.getByRole('button',{name:/2026-11-/}).first().click();
      await page.getByRole('button',{name:/^1,.*tháng 11|^Chủ Nhật, ngày 1 tháng 11|^Sunday, November 1/}).first().click();
      await page.getByRole('button',{name:/^OK$|^Chọn$/}).last().click();await shot(page,13);
      await chat();await shot(page,16);
    }
    await home();await page.getByRole('tab',{name:'Ví tiền',exact:true}).click();await page.waitForTimeout(700);
    await shot(page,role==='worker'?5:14);
    if(role==='worker'){
      await page.getByRole('button',{name:'Nạp VietQR',exact:true}).click();
      await page.getByRole('checkbox',{name:/200[.,]000/}).click();
      await page.getByRole('button',{name:'Tạo QR nạp tiền',exact:true}).click();
      await page.getByRole('button',{name:'Sao chép Ngân hàng',exact:true}).waitFor();
      assert.match(await page.locator('body').ariaSnapshot(),/KHÔNG CHUYỂN TIỀN/);
      await shot(page,6);
    }
    await home();await page.getByRole('tab',{name:/Hồ sơ/}).click();await page.waitForTimeout(800);await shot(page,role==='worker'?7:15);
    if(role==='worker'){
      await page.getByText('Thông tin và tiện ích hồ sơ',{exact:true}).click();await page.getByRole('button',{name:'Bảng xếp hạng thợ',exact:true}).click();await shot(page,9);
    }
    await page.setViewportSize({width:1440,height:1000});await home();
    await page.screenshot({path:`.local/commercial/desktop-${role}.png`});
    await page.goto('about:blank');
  }
  const admin=await browser.newPage({viewport:{width:1440,height:1300}});
  await admin.goto('http://127.0.0.1:18083/admin/login');await admin.locator('#phoneNumber').fill('000106000000');await admin.locator('#password').fill(password);await admin.getByRole('button',{name:'Đăng nhập',exact:true}).click();await admin.getByRole('heading',{name:'Control Center',exact:true}).waitFor();
  assert.equal(await admin.locator('.kpi-orbit').count(),4);await shot(admin,20);await admin.goto('about:blank');
  assert.deepEqual(errors,[]);assert.equal(captures.length,20);
  fs.writeFileSync(path.join(output,'manifest.json'),JSON.stringify(captures,null,2)+'\n');
  if(process.argv.includes('--publish')){
    const destination='docs/figma_screens';const backup='.local/commercial/original-reference';fs.mkdirSync(backup,{recursive:true});
    for(const file of fs.readdirSync(destination).filter(f=>f.endsWith('.png')))if(!fs.existsSync(path.join(backup,file)))fs.copyFileSync(path.join(destination,file),path.join(backup,file));
    for(const {file} of captures)fs.copyFileSync(path.join(output,file),path.join(destination,file));
    fs.copyFileSync(path.join(output,'manifest.json'),path.join(destination,'manifest.json'));
  }
  console.log('20 actual DEMO screens; no uncaught page errors. GPS is browser-simulated for QA; no production mutation.');
}finally{await browser.close();}
