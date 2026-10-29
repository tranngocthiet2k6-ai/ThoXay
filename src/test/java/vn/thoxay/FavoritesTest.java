package vn.thoxay;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.JwtUtil;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.assertj.core.api.Assertions.assertThat;
@SpringBootTest @AutoConfigureMockMvc @Transactional
class FavoritesTest {
 @Autowired MockMvc mvc; @Autowired UserRepository users; @Autowired JobRepository jobs; @Autowired JwtUtil jwt;
 @Autowired vn.thoxay.favorites.SavedJobRepository savedJobs;
 @Autowired vn.thoxay.favorites.SavedWorkerRepository savedWorkers;
 User worker,other,owner;Job job;
 @BeforeEach void setup(){worker=user("0986666611",Role.ROLE_WORKER);other=user("0986666612",Role.ROLE_WORKER);owner=user("0986666613",Role.ROLE_CONTRACTOR);job=new Job();job.setContractor(owner);job.setTitle("Việc QA");job.setAddress("QA");job.setJobType("Thợ chính");job.setSalaryPerDay(500000);job.setRequiredWorkers(1);jobs.saveAndFlush(job);}
 @Test void jobSavedListIsPrivateIdempotentAndDoesNotExposePhone()throws Exception{
  String path="/api/users/me/saved/jobs/"+job.getId();
  for(int i=0;i<2;i++)mvc.perform(put(path).header("Authorization",token(worker))).andExpect(status().isOk());
  assertThat(savedJobs.countByOwnerId(worker.getId())).isEqualTo(1);
  mvc.perform(get("/api/users/me/saved/jobs").header("Authorization",token(worker))).andExpect(jsonPath("$.length()").value(1)).andExpect(jsonPath("$[0].contractorPhone").isEmpty());
  mvc.perform(get("/api/users/me/saved/jobs").header("Authorization",token(other))).andExpect(jsonPath("$.length()").value(0));
  mvc.perform(delete(path).header("Authorization",token(other))).andExpect(status().isOk());
  assertThat(savedJobs.countByOwnerId(worker.getId())).isEqualTo(1);
  for(int i=0;i<2;i++)mvc.perform(delete(path).header("Authorization",token(worker))).andExpect(status().isOk());
  assertThat(savedJobs.countByOwnerId(worker.getId())).isZero();
 }
 @Test void favoritesEnforceRolesAndHideBlockedAccounts()throws Exception{
  mvc.perform(put("/api/users/me/saved/jobs/"+job.getId()).header("Authorization",token(owner))).andExpect(status().isForbidden());
  mvc.perform(put("/api/users/me/saved/workers/"+owner.getId()).header("Authorization",token(owner))).andExpect(status().isNotFound());
  mvc.perform(put("/api/users/me/saved/workers/"+worker.getId()).header("Authorization",token(owner))).andExpect(status().isOk());
  mvc.perform(put("/api/users/me/saved/workers/"+worker.getId()).header("Authorization",token(owner))).andExpect(status().isOk());
  assertThat(savedWorkers.countByOwnerId(owner.getId())).isEqualTo(1);
  mvc.perform(get("/api/users/me/saved/workers").header("Authorization",token(worker))).andExpect(status().isForbidden());
  worker.setActive(false);users.saveAndFlush(worker);
  mvc.perform(get("/api/users/me/saved/workers").header("Authorization",token(owner))).andExpect(jsonPath("$.length()").value(0));
  mvc.perform(put("/api/users/me/saved/jobs/999999").header("Authorization",token(other))).andExpect(status().isNotFound());
 }
 @Test void deletingJobCascadesOnlyItsBookmarks()throws Exception{
  mvc.perform(put("/api/users/me/saved/jobs/"+job.getId()).header("Authorization",token(worker))).andExpect(status().isOk());
  jobs.delete(job);jobs.flush();assertThat(savedJobs.countByOwnerId(worker.getId())).isZero();
 }
 User user(String phone,Role role){var u=new User();u.setPhoneNumber(phone);u.setPassword("hash");u.setFullName("QA");u.setRole(role);return users.saveAndFlush(u);}
 String token(User user){return "Bearer "+jwt.generateToken(user.getPhoneNumber());}
}
