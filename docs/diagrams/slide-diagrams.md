# Sơ đồ rút gọn cho trình chiếu

Các hình này chỉ rút gọn phạm vi trình bày; báo cáo chính giữ đủ 30 bảng và toàn bộ chức năng.

<!-- diagram:slide-use-case -->
```mermaid
flowchart LR
 worker["Thợ"] --> work["Tìm việc và thực hiện ca"]
 owner["Chủ thầu"] --> hire["Tuyển dụng và nghiệm thu"]
 admin["Admin"] --> review["KYC và đối soát"]
 classDef labor fill:#fff1e8,stroke:#EA580C,color:#0F172A
 classDef business fill:#ecfdf5,stroke:#059669,color:#0F172A
 classDef control fill:#e2e8f0,stroke:#0F172A,color:#0F172A
 class worker,work labor
 class owner,hire business
 class admin,review control
```

<!-- diagram:slide-architecture -->
```mermaid
flowchart LR
 web["Flutter Web trên Vercel"] --> api["Spring Boot trên Render"]
 apk["Flutter APK"] --> api
 admin["Thymeleaf Admin"] --> api
 api --> database[("PostgreSQL 17")]
```

<!-- diagram:slide-erd -->
```mermaid
erDiagram
 direction LR
 users ||--o{ jobs : contractor_id
 jobs ||--o{ job_applications : job_id
 users ||--o{ job_applications : worker_id
 users {
  bigint id PK
  varchar role
 }
 jobs {
  bigint id PK
  bigint contractor_id FK
  varchar status
 }
 job_applications {
  bigint id PK
  bigint job_id FK
  bigint worker_id FK
 }
```
