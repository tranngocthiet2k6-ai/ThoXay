package vn.thoxay.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.scheduling.CommitmentService;

@Controller @RequiredArgsConstructor
public class CommitmentAdminController {
    private final CommitmentService commitments;
    private final vn.thoxay.crew.CrewService crews;
    @GetMapping("/admin/jobs/{id}/commitments") @PreAuthorize("hasRole('ADMIN')")
    public String list(@PathVariable Long id,Model model) {
        model.addAttribute("documents",commitments.adminByJob(id));
        model.addAttribute("crews",crews.byJob(id));
        return "admin-commitments";
    }
}
