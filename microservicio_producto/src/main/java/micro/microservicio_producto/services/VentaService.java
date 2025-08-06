package micro.microservicio_producto.services;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.transaction.annotation.Transactional;
import micro.microservicio_producto.entities.DTO.*;
import micro.microservicio_producto.entities.*;
import micro.microservicio_producto.exceptions.BusinessLogicException;
import micro.microservicio_producto.repositories.ProductoRepository;
import micro.microservicio_producto.repositories.VentaArchivadaRepository;
import micro.microservicio_producto.repositories.VentaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;
@Service
public class VentaService {

    private static final Logger log = LoggerFactory.getLogger(VentaService.class);
    private static final Pattern FULL_FORMAT_PATTERN = Pattern.compile("^[a-zA-Z]{2}\\d{6}$");

    // Dependencias existentes
    private final ProductoService productoService;
    private final ComprobanteService comprobanteService;
    private final VentaRepository ventaRepository;
    private final ProductoRepository productoRepository;
    private final VentaArchivadaRepository ventaArchivadaRepository;

    // ✅ 1. AÑADIR ESTOS CAMPOS A LA CLASE
    private final ObjectMapper objectMapper;

    @Value("${app.storage.archive}")
    private String rutaArchivo;


    public VentaService(ProductoService productoService, ComprobanteService comprobanteService,
                        VentaRepository ventaRepository, ProductoRepository productoRepository,
                        VentaArchivadaRepository ventaArchivadaRepository) {
        this.productoService = productoService;
        this.comprobanteService = comprobanteService;
        this.ventaRepository = ventaRepository;
        this.productoRepository = productoRepository;
        // ✅ 2. INICIALIZAR EL ObjectMapper EN EL CONSTRUCTOR
        this.objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
        this.ventaArchivadaRepository = ventaArchivadaRepository;
    }

    @Transactional
    public VentaResponseDTO registrarVentaCompleta(VentaRequestDTO ventaRequest) {
        // 1. Descontar stock
        List<ProductoDTO> productosVendidos = ventaRequest.getItems();
        productoService.descontarProductos(productosVendidos);
        // 2. Generar un nuevo número de comprobante
        String numeroComprobante = comprobanteService.generarNumeroComprobanteUnico();
        // 3. Crear y guardar la entidad Venta
        Venta nuevaVenta = new Venta();
        nuevaVenta.setNumeroComprobante(numeroComprobante);
        nuevaVenta.setFechaVenta(LocalDateTime.now());

        BigDecimal totalVenta = BigDecimal.ZERO;
        for (ProductoDTO dto : productosVendidos) {
            Producto producto = productoRepository.findById(dto.getId())
                    .orElseThrow(() -> new BusinessLogicException("Producto no encontrado para la venta con ID: " + dto.getId()));

            VentaItem item = new VentaItem();
            item.setProductoId(producto.getId());
            item.setProductoDescripcion(producto.getDescripcion());
            item.setCantidad(dto.getCantidad());
            item.setPrecioUnitario(producto.getPrecio_publico());
            item.setVenta(nuevaVenta);

            nuevaVenta.getItems().add(item);
            totalVenta = totalVenta.add(producto.getPrecio_publico().multiply(new BigDecimal(dto.getCantidad())));
        }
        nuevaVenta.setTotalVenta(totalVenta);
        Venta ventaGuardada = ventaRepository.save(nuevaVenta);
        return mapToVentaResponseDTO(ventaGuardada);
    }
    @Transactional(readOnly = true)
    public List<VentaResponseDTO> findAllVentas() {
        return ventaRepository.findAllByOrderByFechaVentaDesc()
                .stream()
                .map(this::mapToVentaResponseDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public Optional<VentaResponseDTO> buscarComprobantePorNumero(String numero) {
        if (numero == null || numero.trim().isEmpty()) {
            return Optional.empty();
        }

        String numeroLower = numero.toLowerCase().trim();
        Matcher matcher = FULL_FORMAT_PATTERN.matcher(numeroLower);
        log.info("Buscando venta por parte numérica que termine en: {}", numeroLower);
        // --- CASO 1: El usuario introdujo el formato completo (ej: "cu000005") ---
        if (matcher.matches()) {
            log.info("Buscando venta por formato completo: {}", numeroLower);
            // Primero busca en la tabla "caliente" (ventas recientes)
            return ventaRepository.findByNumeroComprobante(numeroLower)
                    .map(this::mapToVentaResponseDTO)
                    // Si no la encuentra, busca en la tabla "fría" (ventas archivadas)
                    .or(() -> buscarYConvertirVentaArchivada(numeroLower));
        }

        // --- CASO 2: El usuario introdujo solo el número (ej: "5") ---
        try {
            long num = Long.parseLong(numero);
            String parteNumerica = String.format("%06d", num);
            log.info("Buscando venta por parte numérica que termine en: {}", parteNumerica);


            // Si no está en la BD, buscar en el sistema de archivos por el sufijo
            return ventaRepository.findByNumeroComprobanteEndingWith(parteNumerica)
                    .map(this::mapToVentaResponseDTO)
                    .or(() -> buscarYConvertirVentaArchivadaPorSufijo(parteNumerica));

        } catch (NumberFormatException e) {
            log.error("La entrada '{}' no es un número válido ni un formato de comprobante completo.", numero);
        }

        return Optional.empty();
    }

    /**
     * Busca una venta archivada por su número de comprobante completo y la convierte a una entidad Venta.
     */
    private Optional<VentaResponseDTO> buscarYConvertirVentaArchivada(String numeroCompleto) {
        log.warn("Comprobante {} no encontrado en la tabla principal. Buscando en archivo...", numeroCompleto);
        return ventaArchivadaRepository.findByNumeroComprobante(numeroCompleto)
                .map(this::convertirArchivadaAVenta)
                .map(this::mapToVentaResponseDTO);
    }

    /**
     * Busca una venta archivada por el sufijo de su número de comprobante y la convierte a una entidad Venta.
     */
    private Optional<VentaResponseDTO> buscarYConvertirVentaArchivadaPorSufijo(String sufijo) {
        log.warn("Comprobante con sufijo {} no encontrado en la tabla principal. Buscando en archivo...", sufijo);
        return ventaArchivadaRepository.findByNumeroComprobanteEndingWith(sufijo)
                .map(this::convertirArchivadaAVenta)
                .map(this::mapToVentaResponseDTO);
    }

    /**
     * Convierte una entidad de VentaArchivada a una entidad Venta para poder ser devuelta por la API.
     */
    private Venta convertirArchivadaAVenta(VentaArchivada archivada) {
        Venta venta = new Venta();
        venta.setId(archivada.getId());
        venta.setNumeroComprobante(archivada.getNumeroComprobante());
        venta.setFechaVenta(archivada.getFechaVenta());
        venta.setTotalVenta(archivada.getTotalVenta());

        List<VentaItem> items = archivada.getItems().stream()
                .map(itemArchivado -> {
                    VentaItem item = new VentaItem();
                    item.setId(itemArchivado.getId());
                    item.setProductoId(itemArchivado.getProductoId());
                    item.setProductoDescripcion(itemArchivado.getProductoDescripcion());
                    item.setCantidad(itemArchivado.getCantidad());
                    item.setPrecioUnitario(itemArchivado.getPrecioUnitario());
                    item.setVenta(venta);
                    return item;
                }).collect(Collectors.toList());
        venta.setItems(items);
        return venta;
    }

    // --- Métodos Mapeadores a DTO ---

    private VentaResponseDTO mapToVentaResponseDTO(Venta venta) {
        VentaResponseDTO dto = new VentaResponseDTO();
        dto.setId(venta.getId());
        dto.setNumeroComprobante(venta.getNumeroComprobante());
        dto.setFechaVenta(venta.getFechaVenta());
        dto.setTotalVenta(venta.getTotalVenta());
        dto.setItems(venta.getItems().stream()
                .map(this::mapToVentaItemResponseDTO)
                .collect(Collectors.toList()));
        return dto;
    }

    private VentaItemResponseDTO mapToVentaItemResponseDTO(VentaItem item) {
        VentaItemResponseDTO itemDTO = new VentaItemResponseDTO();
        itemDTO.setId(item.getId());
        itemDTO.setProductoDescripcion(item.getProductoDescripcion());
        itemDTO.setCantidad(item.getCantidad());
        itemDTO.setPrecioUnitario(item.getPrecioUnitario());
        return itemDTO;
    }

}