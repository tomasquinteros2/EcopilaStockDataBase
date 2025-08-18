package micro.microservicio_producto.controllers;

import jakarta.servlet.http.HttpServletRequest;
import micro.microservicio_producto.entities.DTO.ProductoDTO;
import micro.microservicio_producto.entities.DTO.ProductoRelacionadoDTO;
import micro.microservicio_producto.entities.DTO.ProductoRelacionadoResultadoDTO;
import micro.microservicio_producto.entities.Producto;
import micro.microservicio_producto.feignClients.ProveedorClient;
import micro.microservicio_producto.services.ProductoService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/productos")
public class ProductoController {

    private final Logger log = LoggerFactory.getLogger( ProductoController.class );

    private final ProductoService productoService;

    public ProductoController(ProductoService productoService) {
        this.productoService = productoService;
    }

    @GetMapping("")
    public List<Producto> getAll(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Long proveedorId,
            @RequestParam(required = false) Long tipoId
    ) {

        return productoService.findAllFiltered(search, proveedorId, tipoId);
    }
    @GetMapping("/byDesc/{desc}")
    public ResponseEntity<List<Producto>> getProductosByDesc(@PathVariable String desc) { // CAMBIO: Eliminar 'throws Exception'
        List<Producto> resultado = productoService.findByDesc(desc);
        return ResponseEntity.ok(resultado);
    }
    @GetMapping("/{id}")
    public ResponseEntity<Producto> getProductoById(@PathVariable Long id) { // CAMBIO: Eliminar 'throws Exception'
        Producto producto = productoService.findById(id);
        return ResponseEntity.ok(producto);
    }
    @GetMapping("/bytipo-producto/{id}")
    public ResponseEntity<List<Producto>> getProductoByTipoProducto(@PathVariable Long id) { // CAMBIO: Eliminar 'throws Exception'
        List<Producto> resultado = productoService.findByTipoProducto(id); // Antes: findByTipoProducto
        return ResponseEntity.ok(resultado);
    }

    @PostMapping("")
    public ResponseEntity<Producto> createProducto(@RequestBody Producto entity) { // CAMBIO: Eliminar 'throws Exception'
        Producto nuevoProducto = productoService.save(entity);
        return ResponseEntity.status(HttpStatus.CREATED).body(nuevoProducto);
    }

    @PostMapping("/cargar-masivo")
    public ResponseEntity<?> cargarArchivo(@RequestBody List<Producto> productos){
        log.info("Iniciando carga masiva de {} productos", productos.size());
        try {
            productoService.saveAllProducts(productos);
            return ResponseEntity.ok().body("Carga masiva procesada con éxito.");
        } catch (Exception e) {
            log.error("Error durante la carga masiva de productos: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("{\"error\":\"Error. No se pudo procesar la carga masiva.\"}");
        }
    }
    @PutMapping("/{id}")
    public ResponseEntity<Producto> updateProducto(@PathVariable Long id, @RequestBody Producto productoDetails) {
        log.info("Actualizando producto ID: {}", id);
        Producto updatedProducto = productoService.update(id, productoDetails);
        return ResponseEntity.ok(updatedProducto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteProducto(@PathVariable Long id) {
        productoService.delete(id);
        return ResponseEntity.noContent().build();
    }
    @PutMapping("/descontar")
    public ResponseEntity<String> descontarProductos(@RequestBody List<ProductoDTO> productos) {
        productoService.descontarProductos(productos);
        return ResponseEntity.ok("Productos descontados correctamente");
    }

    @PostMapping("/relaciones")
    public ResponseEntity<String> agregarRelacion(@RequestBody ProductoRelacionadoDTO dto) {
        productoService.agregarRelacion(dto);
        return ResponseEntity.ok("Relación agregada exitosamente");
    }
    @DeleteMapping("/relaciones")
    public ResponseEntity<Void> eliminarRelacion(@RequestBody ProductoRelacionadoDTO dto) {
        productoService.eliminarRelacion(dto);
        return ResponseEntity.noContent().build();
    }
    @GetMapping("/{id}/relacionados")
    public ResponseEntity<List<ProductoRelacionadoResultadoDTO>> getRelacionados(@PathVariable Long id) {
        List<ProductoRelacionadoResultadoDTO> resultado = productoService.obtenerRelacionadosConProveedor(id);
        return ResponseEntity.ok(resultado);
    }
}