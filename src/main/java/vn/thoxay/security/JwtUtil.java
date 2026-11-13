package vn.thoxay.security;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import javax.crypto.SecretKey;
import java.util.Date;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class JwtUtil {
    private final SecretKey key;
    private final long expirationMs;
    public JwtUtil(@Value("${app.jwt.secret}") String secret,
                   @Value("${app.jwt.expiration-ms}") long expirationMs) {
        key = Keys.hmacShaKeyFor(Decoders.BASE64.decode(secret));
        this.expirationMs = expirationMs;
    }
    public String generateToken(String phone) {
        return generateToken(phone, 0);
    }
    public String generateToken(String phone, long version) {
        return generateToken(phone, version, null);
    }
    public String generateToken(String phone, long version, Long userId) {
        return Jwts.builder().subject(phone).claim("sv", version).claim("uid", userId).issuedAt(new Date())
            .expiration(new Date(System.currentTimeMillis() + expirationMs)).signWith(key).compact();
    }
    public String extractPhone(String token) {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload().getSubject();
    }
    public long expiresInSeconds() { return expirationMs / 1000; }
    public long securityVersion(String token) {
        Number version = Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload().get("sv", Number.class);
        return version == null ? 0 : version.longValue();
    }
    public boolean belongsTo(String token, Long userId) {
        Number id = Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload().get("uid", Number.class);
        return id == null || id.longValue() == userId;
    }
}
