const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
function fixture() {
  const badge = {textContent:'5',hidden:false,hasAttribute:name=>name==='data-hide-zero'};
  const number = {textContent:'5',hidden:false,hasAttribute:()=>false};
  const sos = {textContent:'2'};
  const classes = {};
  const banner = {hidden:false,classList:{toggle:(name,value)=>{classes[name]=value;}}};
  const document = {hidden:false,querySelectorAll:key=>key==='[data-incident-count]'?[badge,number]:[sos],getElementById:()=>banner,addEventListener:()=>{}};
  let refresh, calls = 0, result = {open:4,sos:1}, fail = false;
  const context = vm.createContext({document,setInterval:callback=>{refresh=callback;},fetch:async()=>{calls++;if(fail)throw new Error('offline');return {ok:true,headers:{get:()=> 'application/json'},json:async()=>result};}});
  vm.runInContext(fs.readFileSync(path.join(__dirname,'../../src/main/resources/static/js/admin-incidents.js'),'utf8'),context);
  return {document,badge,number,sos,banner,classes,refresh:()=>refresh(),calls:()=>calls,setResult:value=>{result=value;},offline:()=>{fail=true;}};
}
test('SOS alert retains confirmed counts offline and pauses polling in hidden tabs',async()=>{
  const view=fixture();await view.refresh();assert.equal(view.badge.textContent,'4');assert.equal(view.sos.textContent,'1');assert.equal(view.classes['alert-danger'],true);
  view.offline();await view.refresh();assert.equal(view.badge.textContent,'4');assert.equal(view.banner.hidden,false);
  const calls=view.calls();view.document.hidden=true;await view.refresh();assert.equal(view.calls(),calls);
});
test('SOS alert ignores malformed counts and displays zero totals without a badge',async()=>{
  const view=fixture();view.setResult({open:-1,sos:0});await view.refresh();assert.equal(view.badge.textContent,'5');
  view.setResult({open:0,sos:0});await view.refresh();assert.equal(view.badge.hidden,true);assert.equal(view.number.hidden,false);assert.equal(view.number.textContent,'0');assert.equal(view.banner.hidden,true);
});
