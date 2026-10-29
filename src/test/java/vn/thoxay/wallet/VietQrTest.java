package vn.thoxay.wallet;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.security.JwtUtil;
import java.util.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
@SpringBootTest @AutoConfigureMockMvc @Transactional
class VietQrTest {
 @Autowired MockMvc mvc;@Autowired ObjectMapper json;@Autowired UserRepository users;@Autowired JwtUtil jwt;@Autowired WalletRequestRepository requests;@Autowired BankSettingsAuditRepository audits;
 User worker,other,admin;
 @BeforeEach void setup(){worker=person("0982222211",Role.ROLE_WORKER);other=person("0982222212",Role.ROLE_CONTRACTOR);admin=person("0982222213",Role.ROLE_ADMIN);}
 @Test void qrIsDisabledUntilAdminExplicitlyConfiguresReceivingBank()throws Exception{
  mvc.perform(create("first-request")).andExpect(status().isConflict());assertThat(requests.count()).isZero();
  mvc.perform(put("/api/admin/wallet/bank-settings").header("Authorization",token(worker)).contentType("application/json").content(json.writeValueAsString(setupBody(-1,true)))) .andExpect(status().isForbidden());
  var unconfirmed=setupBody(-1,true);unconfirmed.put("confirmed",false);
  mvc.perform(put("/api/admin/wallet/bank-settings").header("Authorization",token(admin)).contentType("application/json").content(json.writeValueAsString(unconfirmed))).andExpect(status().isBadRequest());
  configure(-1,true);assertThat(audits.count()).isEqualTo(1);
 }
 @Test void creatingQrIsIdempotentAndDoesNotCreditBalance()throws Exception{
  configure(-1,true);long id=deposit("same-request-01");assertThat(deposit("same-request-01")).isEqualTo(id);
  mvc.perform(get("/api/wallet").header("Authorization",token(worker))).andExpect(jsonPath("$.mainBalance").value(0));
  assertThat(requests.count()).isEqualTo(1);
  mvc.perform(post("/api/wallet/deposits").header("Authorization",token(worker)).contentType("application/json").content("{\"amount\":200000,\"clientRequestId\":\"same-request-01\"}")).andExpect(status().isConflict());
  mvc.perform(get("/api/wallet/deposits/"+id).header("Authorization",token(other))).andExpect(status().isNotFound());
  var review=json.writeValueAsString(Map.of("decision","APPROVE","confirmed",true,"externalReference","QA-BANK-REF-001"));
  for(int i=0;i<2;i++)mvc.perform(post("/api/admin/wallet/requests/"+id+"/review").header("Authorization",token(admin)).contentType("application/json").content(review)).andExpect(status().isOk());
  mvc.perform(get("/api/wallet").header("Authorization",token(worker))).andExpect(jsonPath("$.mainBalance").value(100000));
 }
 @Test void bankEditsDoNotRewriteOldQrAndRejectStaleVersion()throws Exception{
  configure(-1,true);long id=deposit("snapshot-request");var original=requests.findById(id).orElseThrow();String payload=original.getQrPayload();
  var next=setupBody(0,true);next.put("accountNo","000009876543");next.put("accountName","QA NEW RECEIVER");
  mvc.perform(put("/api/admin/wallet/bank-settings").header("Authorization",token(admin)).contentType("application/json").content(json.writeValueAsString(next))).andExpect(status().isOk()).andExpect(jsonPath("$.version").value(1));
  mvc.perform(get("/api/wallet/deposits/"+id).header("Authorization",token(worker))).andExpect(jsonPath("$.accountNo").value("000001234567")).andExpect(jsonPath("$.payload").value(payload));
  mvc.perform(put("/api/admin/wallet/bank-settings").header("Authorization",token(admin)).contentType("application/json").content(json.writeValueAsString(setupBody(0,false)))).andExpect(status().isConflict());
  configure(1,false);mvc.perform(create("disabled-request")).andExpect(status().isConflict());
  assertThat(deposit("snapshot-request")).isEqualTo(id);
 }
 @Test void webAdminCanConfigureAndDisableReceivingBankWithCsrf()throws Exception{
  var auth=user(admin.getPhoneNumber()).roles("ADMIN");
  mvc.perform(post("/admin/wallet/bank-settings").with(auth).with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf()).param("enabled","true").param("bankBin","970436").param("bankName","QA Bank").param("accountNo","000001234567").param("accountName","QA RECEIVER").param("version","-1").param("confirmed","true"))
   .andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/admin/wallet/bank-settings"));
  mvc.perform(get("/api/admin/wallet/bank-settings").header("Authorization",token(admin))).andExpect(jsonPath("$.enabled").value(true));
  mvc.perform(post("/admin/wallet/bank-settings").with(auth).with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf()).param("enabled","false").param("bankBin","970436").param("bankName","QA Bank").param("accountNo","000001234567").param("accountName","QA RECEIVER").param("version","0"))
   .andExpect(status().is3xxRedirection());
  mvc.perform(get("/api/admin/wallet/bank-settings").header("Authorization",token(admin))).andExpect(jsonPath("$.enabled").value(false));
 }
 @Test void adminCanSeeConfigAndReceivingSnapshotInReconciliation()throws Exception{
  configure(-1,true);long id=deposit("admin-page-req");
  mvc.perform(get("/admin/wallet/bank-settings").with(user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(status().isOk()).andExpect(content().string(org.hamcrest.Matchers.containsString("000001234567")));
  mvc.perform(get("/admin/wallet").with(user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(status().isOk()).andExpect(content().string(org.hamcrest.Matchers.containsString(requests.findById(id).orElseThrow().getDepositReference())));
 }
 @Test void payloadUsesNapasAccountTransferAndValidatesProtocolLimits(){
  // CRC-16/CCITT-FALSE published check value, independent from payment data.
  assertThat(VietQrPayload.crc("123456789")).isEqualTo(0x29B1);
  String sample="00020101021138540010A00000072701240006970407011096020919960208QRIBFTTA53037045802VN630434A0";
  assertThat(VietQrPayload.crc(sample.substring(0,sample.length()-4))).isEqualTo(0x34A0);
  String qr=VietQrPayload.build("970436","000001234567",100000,"TXQA12345");
  // Golden QA vector independently decoded with @viet-qr/core 1.4.0.
  assertThat(qr).isEqualTo("00020101021238560010A0000007270126000697043601120000012345670208QRIBFTTA530370454061000005802VN62130809TXQA1234563041385");var fields=parse(qr);assertThat(fields.get("00")).isEqualTo("01");assertThat(fields.get("01")).isEqualTo("12");assertThat(fields.get("53")).isEqualTo("704");assertThat(fields.get("54")).isEqualTo("100000");assertThat(fields.get("58")).isEqualTo("VN");assertThat(parse(fields.get("62")).get("08")).isEqualTo("TXQA12345");var merchant=parse(fields.get("38"));assertThat(merchant.get("00")).isEqualTo("A000000727");assertThat(merchant.get("02")).isEqualTo("QRIBFTTA");assertThat(parse(merchant.get("01"))).containsEntry("00","970436").containsEntry("01","000001234567");
  org.assertj.core.api.Assertions.assertThatThrownBy(()->VietQrPayload.build("970436","A".repeat(20),1000,"TX1")).isInstanceOf(IllegalArgumentException.class);
 }
 Map<String,String> parse(String text){var out=new LinkedHashMap<String,String>();for(int i=0;i<text.length();){String id=text.substring(i,i+2);int length=Integer.parseInt(text.substring(i+2,i+4));out.put(id,text.substring(i+4,i+4+length));i+=4+length;}return out;}
 Map<String,Object> setupBody(long version,boolean enabled){return new HashMap<>(Map.of("enabled",enabled,"bankBin","970436","bankName","QA Vietcombank","accountNo","000001234567","accountName","QA RECEIVING ACCOUNT","version",version,"confirmed",true));}
 void configure(long version,boolean enabled)throws Exception{mvc.perform(put("/api/admin/wallet/bank-settings").header("Authorization",token(admin)).contentType("application/json").content(json.writeValueAsString(setupBody(version,enabled)))).andExpect(status().isOk());}
 org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder create(String clientId)throws Exception{return post("/api/wallet/deposits").header("Authorization",token(worker)).contentType("application/json").content(json.writeValueAsString(Map.of("amount",100000,"clientRequestId",clientId)));}
 long deposit(String clientId)throws Exception{var r=mvc.perform(create(clientId)).andExpect(status().isOk()).andReturn();return json.readTree(r.getResponse().getContentAsString()).get("requestId").asLong();}
 User person(String phone,Role role){var u=new User();u.setPhoneNumber(phone);u.setFullName("QA");u.setPassword("hash");u.setRole(role);return users.saveAndFlush(u);}
 String token(User u){return "Bearer "+jwt.generateToken(u.getPhoneNumber());}
}
