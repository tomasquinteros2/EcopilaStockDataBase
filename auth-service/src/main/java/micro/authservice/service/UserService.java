package micro.authservice.service;

import micro.authservice.dto.UserDTO;
import micro.authservice.entity.Authority;
import micro.authservice.entity.Usuario;
import micro.authservice.repository.AuthorityRepository;
import micro.authservice.repository.UsuarioRepository;
import micro.authservice.security.AuthorityConstant; // Asegúrate que el path sea correcto
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@Transactional
public class UserService {

    private final Logger log = LoggerFactory.getLogger(UserService.class);
    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthorityRepository authorityRepository;

    public UserService(UsuarioRepository usuarioRepository, PasswordEncoder passwordEncoder, AuthorityRepository authorityRepository) {
        this.usuarioRepository = usuarioRepository;
        this.passwordEncoder = passwordEncoder;
        this.authorityRepository = authorityRepository;
    }

    public Optional<Usuario> getUserByUsername(String username) {
        return usuarioRepository.findByUsername(username.toLowerCase());
    }
    public Usuario getPendingUser(String username) {
        return usuarioRepository.findByUsername(username.toLowerCase())
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
    public Usuario activateUser(Usuario user) {
        user.setAccountVerified(true);
        Usuario activatedUser = usuarioRepository.save(user);
        log.info("User activated: {}", activatedUser.getUsername());
        return activatedUser;
    }
    public void savePendingUser(UserDTO userDTO, String totpSecret) {
        if (usuarioRepository.findByUsername(userDTO.getUsername().toLowerCase()).isPresent()) {
            throw new UsernameAlreadyUsedException();
        }

        Usuario newUser = new Usuario();
        String encryptedPassword = passwordEncoder.encode(userDTO.getPassword());
        newUser.setUsername(userDTO.getUsername().toLowerCase());
        newUser.setPassword(encryptedPassword);
        newUser.setTotpSecret(totpSecret);
        newUser.setTwoFactorEnabled(true);
        newUser.setAccountVerified(false);

        Set<Authority> authorities = new HashSet<>();
        if (userDTO.getAuthorities() == null || userDTO.getAuthorities().isEmpty()) {
            authorityRepository.findByName(AuthorityConstant.USER)
                    .ifPresentOrElse(authorities::add,
                            () -> { throw new AuthorityNotFoundException(AuthorityConstant.USER); });
        } else {
            authorities = userDTO.getAuthorities().stream()
                    .map(authorityString -> authorityRepository.findByName(authorityString)
                            .orElseThrow(() -> new AuthorityNotFoundException(authorityString)))
                    .collect(Collectors.toSet());
        }
        newUser.setAuthorities(authorities);
        usuarioRepository.save(newUser);
        log.debug("Saved pending user: {}", newUser.getUsername());
    }
    public Usuario registerUser(UserDTO userDTO) {
        if (usuarioRepository.findByUsername(userDTO.getUsername().toLowerCase()).isPresent()) {
            throw new UsernameAlreadyUsedException();
        }

        Usuario newUser = new Usuario();
        String encryptedPassword = passwordEncoder.encode(userDTO.getPassword());
        newUser.setUsername(userDTO.getUsername().toLowerCase());
        newUser.setPassword(encryptedPassword);

        Set<Authority> authorities = new HashSet<>();
        if (userDTO.getAuthorities() == null || userDTO.getAuthorities().isEmpty()) {
            // Asignar rol USER por defecto si no se especifican roles
            authorityRepository.findByName(AuthorityConstant.USER)
                    .ifPresentOrElse(authorities::add,
                            () -> { throw new AuthorityNotFoundException(AuthorityConstant.USER); });
        } else {
            authorities = userDTO.getAuthorities().stream()
                    .map(authorityString -> authorityRepository.findByName(authorityString)
                            .orElseThrow(() -> new AuthorityNotFoundException(authorityString)))
                    .collect(Collectors.toSet());
        }
        newUser.setAuthorities(authorities);
        usuarioRepository.save(newUser);
        log.debug("Created Information for User: {}", newUser);
        return newUser;
    }

    public static class UsernameAlreadyUsedException extends RuntimeException {
        public UsernameAlreadyUsedException() {
            super("Login name already used!");
        }
    }

    public static class AuthorityNotFoundException extends RuntimeException {
        public AuthorityNotFoundException(String authority) {
            super("Authority " + authority + " not found!");
        }
    }

}