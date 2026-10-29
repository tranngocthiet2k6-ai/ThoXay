package vn.thoxay.admin;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.media.PortfolioService;
import java.util.UUID;
@Controller @RequiredArgsConstructor @PreAuthorize("hasRole('ADMIN')")
public class PortfolioAdminController {
 private final PortfolioService service;
 @GetMapping("/admin/users/{id}/portfolio") public String portfolio(@PathVariable Long id,Model model){model.addAttribute("photos",service.list(id));return "admin-portfolio";}
 @GetMapping("/admin/portfolio/photos/{id}") public ResponseEntity<byte[]> photo(@PathVariable UUID id){return ResponseEntity.ok().contentType(MediaType.IMAGE_JPEG).cacheControl(CacheControl.noStore()).header("X-Content-Type-Options","nosniff").body(service.read(id));}
}
