package micro.authservice.service;

import de.taimos.totp.TOTP;
import org.apache.commons.codec.binary.Base32;
import org.apache.commons.codec.binary.Hex;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;

@Service
public class TwoFactorAuthService {

    public String generateTOTPSecret() {
        SecureRandom random = new SecureRandom();
        byte[] bytes = new byte[20];
        random.nextBytes(bytes);
        Base32 base32 = new Base32();
        return base32.encodeToString(bytes);
    }

    public String generateQRCodeURL(String username, String secret) {
        return String.format(
                "otpauth://totp/EcopilaStock:%s?secret=%s&issuer=EcopilaStock",
                username, secret
        );
    }

    public boolean verifyTOTPCode(String secret, String code) {
        try {
            Base32 base32 = new Base32();
            byte[] bytes = base32.decode(secret);
            String hexKey = Hex.encodeHexString(bytes);
            String generatedCode = TOTP.getOTP(hexKey);
            return generatedCode.equals(code);
        } catch (Exception e) {
            return false;
        }
    }
}
