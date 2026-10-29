package vn.thoxay;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.security.JwtUtil;
import vn.thoxay.media.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.*;
import java.nio.charset.StandardCharsets;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
@SpringBootTest @AutoConfigureMockMvc @Transactional
class PortfolioPhotosTest {
 @Autowired MockMvc mvc;@Autowired ObjectMapper json;@Autowired UserRepository users;@Autowired JwtUtil jwt;@Autowired PortfolioRepository photos;
 User worker,owner,other,admin;
 @BeforeEach void setup(){worker=create("0984444411",Role.ROLE_WORKER);owner=create("0984444412",Role.ROLE_CONTRACTOR);other=create("0984444413",Role.ROLE_CONTRACTOR);admin=create("0984444414",Role.ROLE_ADMIN);}
 @Test void uploadedPhotoIsSanitizedBoundedAndRequiresAuthentication()throws Exception{
  String id=upload(worker);var image=mvc.perform(get("/api/portfolio/photos/"+id).header("Authorization",token(owner))).andExpect(status().isOk()).andExpect(content().contentType("image/jpeg")).andExpect(header().string("Cache-Control","no-store")).andReturn().getResponse().getContentAsByteArray();
  var decoded=javax.imageio.ImageIO.read(new ByteArrayInputStream(image));assertThat(decoded.getWidth()).isEqualTo(1800);assertThat(decoded.getHeight()).isEqualTo(900);assertThat(image.length).isLessThanOrEqualTo(2097152);assertThat(new String(image,StandardCharsets.ISO_8859_1)).doesNotContain("QA-GPS-SECRET");
  mvc.perform(get("/api/portfolio/photos/"+id)).andExpect(status().isUnauthorized());
  mvc.perform(get("/api/users/"+worker.getId()+"/portfolio").header("Authorization",token(owner))).andExpect(jsonPath("$[0].caption").value("Xây tô QA"));
  mvc.perform(delete("/api/users/me/portfolio/"+id).header("Authorization",token(owner))).andExpect(status().isNotFound());
  mvc.perform(delete("/api/users/me/portfolio/"+id).header("Authorization",token(worker))).andExpect(status().isOk());
  mvc.perform(get("/api/portfolio/photos/"+id).header("Authorization",token(owner))).andExpect(status().isNotFound());
 }
 @Test void contractorPortfolioIsPrivateAndAdminCanInspectWithSession()throws Exception{
  String id=upload(owner);mvc.perform(get("/api/portfolio/photos/"+id).header("Authorization",token(other))).andExpect(status().isNotFound());
  mvc.perform(get("/admin/users/"+owner.getId()+"/portfolio").with(user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(status().isOk()).andExpect(content().string(org.hamcrest.Matchers.containsString("Xây tô QA")));
  mvc.perform(get("/admin/portfolio/photos/"+id).with(user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(status().isOk());
  mvc.perform(get("/admin/portfolio/photos/"+id).with(user(owner.getPhoneNumber()).roles("CONTRACTOR"))).andExpect(status().isForbidden());
 }
 @Test void fakeOversizedAndTinyImagesCannotBeStored()throws Exception{
  mvc.perform(multipart("/api/users/me/portfolio").file(new MockMultipartFile("photo","fake.jpg","image/jpeg","<svg/>".getBytes())).header("Authorization",token(worker))).andExpect(status().isBadRequest());
  mvc.perform(multipart("/api/users/me/portfolio").file(new MockMultipartFile("photo","large.jpg","image/jpeg",new byte[5242881])).header("Authorization",token(worker))).andExpect(status().isPayloadTooLarge());
  var bytes=new ByteArrayOutputStream();javax.imageio.ImageIO.write(new BufferedImage(10,10,BufferedImage.TYPE_INT_RGB),"png",bytes);
  mvc.perform(multipart("/api/users/me/portfolio").file(new MockMultipartFile("photo",bytes.toByteArray())).header("Authorization",token(worker))).andExpect(status().isBadRequest());assertThat(photos.countByOwnerId(worker.getId())).isZero();
 }
 @Test void quotaAndBlockedOwnerAreEnforced()throws Exception{
  String id=null;for(int i=0;i<12;i++)id=upload(worker);
  mvc.perform(multipart("/api/users/me/portfolio").file(file()).header("Authorization",token(worker))).andExpect(status().isConflict());assertThat(photos.countByOwnerId(worker.getId())).isEqualTo(12);
  worker.setActive(false);users.saveAndFlush(worker);
  mvc.perform(get("/api/portfolio/photos/"+id).header("Authorization",token(owner))).andExpect(status().isNotFound());
  mvc.perform(get("/api/portfolio/photos/"+id).header("Authorization",token(worker))).andExpect(status().isForbidden());
 }
 String upload(User user)throws Exception{var r=mvc.perform(multipart("/api/users/me/portfolio").file(file()).param("caption","Xây tô QA").header("Authorization",token(user))).andExpect(status().isOk()).andReturn();return json.readTree(r.getResponse().getContentAsString()).get("id").asText();}
 MockMultipartFile file()throws Exception{var image=new BufferedImage(2000,1000,BufferedImage.TYPE_INT_RGB);var g=image.createGraphics();g.setColor(Color.BLUE);g.fillRect(0,0,2000,1000);g.dispose();var out=new ByteArrayOutputStream();javax.imageio.ImageIO.write(image,"jpeg",out);out.write("QA-GPS-SECRET".getBytes(StandardCharsets.UTF_8));return new MockMultipartFile("photo","work.jpg","image/jpeg",out.toByteArray());}
 User create(String phone,Role role){var u=new User();u.setPhoneNumber(phone);u.setFullName("QA");u.setPassword("hash");u.setRole(role);return users.saveAndFlush(u);}
 String token(User u){return "Bearer "+jwt.generateToken(u.getPhoneNumber());}
}
