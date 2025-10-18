package micro.authservice.controller;

import jakarta.validation.Valid;
import micro.authservice.dto.JwtTokenDTO;
import micro.authservice.dto.LoginDTO;
import micro.authservice.dto.UserDTO;
import micro.authservice.entity.Usuario;
import micro.authservice.security.jwt.TokenProvider;
import micro.authservice.service.TwoFactorAuthService;
import micro.authservice.service.UserService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final TokenProvider tokenProvider;
    private final AuthenticationManager authenticationManager;
    private final UserService userService;
    private final TwoFactorAuthService twoFactorAuthService;

    public AuthController(TokenProvider tokenProvider,TwoFactorAuthService twoFactorAuthService, AuthenticationManager authenticationManager, UserService userService) {
        this.twoFactorAuthService = twoFactorAuthService;
        this.tokenProvider = tokenProvider;
        this.authenticationManager = authenticationManager;
        this.userService = userService;
    }

    @PostMapping("/login")
    public ResponseEntity<JwtTokenDTO> authorize(@Valid @RequestBody LoginDTO loginDTO) {
        UsernamePasswordAuthenticationToken authenticationToken =
                new UsernamePasswordAuthenticationToken(loginDTO.getUsername(), loginDTO.getPassword());

        Authentication authentication = authenticationManager.authenticate(authenticationToken);
        SecurityContextHolder.getContext().setAuthentication(authentication);

        String jwt = tokenProvider.createToken(authentication, false);

        HttpHeaders httpHeaders = new HttpHeaders();
        httpHeaders.add(HttpHeaders.AUTHORIZATION, "Bearer " + jwt);

        return new ResponseEntity<>(new JwtTokenDTO(jwt), httpHeaders, HttpStatus.OK);
    }

    @PostMapping("/register/init")
    public ResponseEntity<Map<String, String>> initiateRegistration(@Valid @RequestBody UserDTO userDTO) {
        String secret = twoFactorAuthService.generateTOTPSecret();
        String qrCodeUrl = twoFactorAuthService.generateQRCodeURL(userDTO.getUsername(), secret);

        userService.savePendingUser(userDTO, secret);

        Map<String, String> response = new HashMap<>();
        response.put("qrCodeUrl", qrCodeUrl);
        response.put("secret", secret);
        response.put("message", "Escanea el QR con Google Authenticator");

        return ResponseEntity.ok(response);
    }
    @PostMapping("/register/verify")
    public ResponseEntity<?> verifyAndCompleteRegistration(
            @RequestParam String username,
            @RequestParam("code") String verificationCode
    ) {
        try {
            Usuario pendingUser = userService.getPendingUser(username);

            if (!pendingUser.isTwoFactorEnabled()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "2FA not enabled for this user"));
            }

            if (twoFactorAuthService.verifyTOTPCode(pendingUser.getTotpSecret(), verificationCode)) {
                Usuario activatedUser = userService.activateUser(pendingUser);
                return ResponseEntity.ok(Map.of(
                        "message", "Usuario registrado exitosamente",
                        "username", activatedUser.getUsername(),
                        "twoFactorEnabled", true
                ));
            }

            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Código de verificación inválido"));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", e.getMessage()));
        }
    }
}