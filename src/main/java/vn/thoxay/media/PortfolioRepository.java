package vn.thoxay.media;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;
public interface PortfolioRepository extends JpaRepository<PortfolioPhoto,UUID> {
 @Query("select new vn.thoxay.media.PhotoSummary(p.id,p.caption,p.createdAt) from PortfolioPhoto p where p.owner.id=:id order by p.createdAt desc,p.id desc")
 List<PhotoSummary> summaries(@Param("id")Long ownerId);
 long countByOwnerId(Long ownerId);
 @Query("select p.owner.id from PortfolioPhoto p where p.id=:id") Optional<Long> ownerId(@Param("id")UUID id);
}
