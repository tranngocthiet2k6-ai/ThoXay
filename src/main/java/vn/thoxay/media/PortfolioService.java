package vn.thoxay.media;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.HttpStatus;
import vn.thoxay.entity.*;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.security.CurrentUser;
import vn.thoxay.exception.ApiException;
import java.util.*;
@Service @RequiredArgsConstructor
public class PortfolioService {
 private final PortfolioRepository photos;
 private final UserRepository users;
 private final CurrentUser current;
 private final ImageSanitizer sanitizer;
 @Transactional(readOnly=true) public List<PhotoSummary> list(Long ownerId){visible(ownerId);return photos.summaries(ownerId);}
 @Transactional public PhotoSummary upload(MultipartFile file,String caption){var u=current.get();if(u.getRole()==Role.ROLE_ADMIN)throw new ApiException(HttpStatus.FORBIDDEN,"Admin không có hồ sơ tay nghề");var content=sanitizer.project(file);users.findLockedById(u.getId()).orElseThrow();if(photos.countByOwnerId(u.getId())>=12)throw new ApiException(HttpStatus.CONFLICT,"Mỗi hồ sơ tối đa 12 ảnh; hãy xóa ảnh cũ trước");var p=new PortfolioPhoto();p.setOwner(u);p.setContent(content);p.setCaption(caption.strip());photos.saveAndFlush(p);return new PhotoSummary(p.getId(),p.getCaption(),p.getCreatedAt());}
 @Transactional(readOnly=true) public byte[] read(UUID id){var ownerId=photos.ownerId(id).orElseThrow(this::missing);visible(ownerId);return photos.findById(id).orElseThrow(this::missing).getContent();}
 @Transactional public void delete(UUID id){var u=current.get();users.findLockedById(u.getId()).orElseThrow();if(!photos.ownerId(id).orElseThrow(this::missing).equals(u.getId()))throw missing();photos.deleteById(id);}
 private void visible(Long id){var u=current.get();var owner=users.findById(id).orElseThrow(this::missing);if((!owner.isActive()&&u.getRole()!=Role.ROLE_ADMIN)||owner.getRole()==Role.ROLE_ADMIN)throw missing();if(!u.getId().equals(id)&&owner.getRole()!=Role.ROLE_WORKER&&u.getRole()!=Role.ROLE_ADMIN)throw missing();}
 private ApiException missing(){return new ApiException(HttpStatus.NOT_FOUND,"Không tìm thấy ảnh hồ sơ");}
}
