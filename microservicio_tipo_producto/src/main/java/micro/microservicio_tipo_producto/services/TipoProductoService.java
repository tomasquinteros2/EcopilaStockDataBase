package micro.microservicio_tipo_producto.services;

import jakarta.transaction.Transactional;
import micro.microservicio_tipo_producto.entities.TipoProducto;
import micro.microservicio_tipo_producto.exceptions.BusinessLogicException;
import micro.microservicio_tipo_producto.exceptions.ResourceNotFoundException;
import micro.microservicio_tipo_producto.repositories.TipoProductoRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.stereotype.Service;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class TipoProductoService {

    private static final Logger log = LoggerFactory.getLogger(TipoProductoService.class);


    private final TipoProductoRepository tipoProductoRepository;

    private final ObjectMapper objectMapper;

    public TipoProductoService(TipoProductoRepository tipoProductoRepository) {
        this.tipoProductoRepository = tipoProductoRepository;
        this.objectMapper = new ObjectMapper();
    }
    @Cacheable("tiposProducto")
    public List<TipoProducto> findAll() {
        log.info("Buscando todos los tipos de producto.");
        return tipoProductoRepository.findAll();
    }

    @Cacheable(value = "tipoProducto", key = "#id")
    public TipoProducto findById(Long id) {
        log.info("Buscando tipo de producto con ID: {}", id);
        return tipoProductoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Tipo de producto no encontrado con ID: " + id));
    }

    @CacheEvict(value = "tiposProducto", allEntries = true)
    @Transactional
    public TipoProducto save(TipoProducto tipoProducto) {
        log.info("Guardando nuevo tipo de producto: {}", tipoProducto);
        if (tipoProducto.getNombre() == null || tipoProducto.getNombre().trim().isEmpty()) {
            throw new BusinessLogicException("El nombre del tipo de producto es obligatorio.");
        }
        Optional<TipoProducto> existingTipo = tipoProductoRepository.findByNombre(tipoProducto.getNombre());
        if (existingTipo.isPresent()) {
            throw new BusinessLogicException("Ya existe un tipo de producto con el nombre: " + tipoProducto.getNombre());
        }
        TipoProducto tipoGuardado = tipoProductoRepository.save(tipoProducto);

        return tipoGuardado;
    }

    @CachePut(value = "tipoProducto", key = "#id")
    @CacheEvict(value = "tiposProducto", allEntries = true)
    @Transactional
    public TipoProducto update(Long id, TipoProducto tipoProductoDetails) {
        log.info("Actualizando tipo de producto con ID: {}", id);
        TipoProducto tipoExistente = findById(id);

        if (tipoProductoDetails.getNombre() == null || tipoProductoDetails.getNombre().trim().isEmpty()) {
            throw new BusinessLogicException("El nombre del tipo de producto es obligatorio para la actualización.");
        }

        Optional<TipoProducto> existingWithName = tipoProductoRepository.findByNombre(tipoProductoDetails.getNombre());
        if (existingWithName.isPresent() && !existingWithName.get().getId().equals(id)) {
            throw new BusinessLogicException("Ya existe otro tipo de producto con el nombre: " + tipoProductoDetails.getNombre());
        }

        tipoExistente.setNombre(tipoProductoDetails.getNombre());

        TipoProducto tipoActualizado = tipoProductoRepository.save(tipoExistente);

        return tipoActualizado;
    }

    @Caching(evict = {
            @CacheEvict(value = "tipoProducto", key = "#id"),
            @CacheEvict(value = "tiposProducto", allEntries = true)
    })
    @Transactional
    public void delete(Long id) {
        log.info("Eliminando tipo de producto con ID: {}", id);
        if (!tipoProductoRepository.existsById(id)) {
            throw new ResourceNotFoundException("Tipo de producto no encontrado con ID: " + id);
        }
        tipoProductoRepository.deleteById(id);
        log.info("Tipo de producto con ID {} eliminado correctamente.", id);
    }
}