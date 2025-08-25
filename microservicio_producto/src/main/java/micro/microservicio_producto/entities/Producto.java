package micro.microservicio_producto.entities;

import com.fasterxml.jackson.annotation.*;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Entity
@Getter
@Setter
@ToString(exclude = {"productosRelacionados", "relacionadoCon"})
@JsonIdentityInfo(
        generator = ObjectIdGenerators.PropertyGenerator.class,
        property = "id"
)
public class Producto {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "producto_seq")
    @SequenceGenerator(
            name = "producto_seq",
            sequenceName = "producto_id_seq",
            allocationSize = 1
    )
    private Long id;

    @Column(nullable = true, unique = true)
    private String codigo_producto;

    @Column
    private String descripcion;

    @Column
    private int cantidad;

    // --- CAMPOS MONETARIOS CON BIGDECIMAL ---
    @Column(precision = 19, scale = 4)
    private BigDecimal iva;

    @Column(precision = 19, scale = 4)
    private BigDecimal precio_publico;

    @Column(precision = 19, scale = 4)
    private BigDecimal resto;

    @Column(precision = 19, scale = 4)
    private BigDecimal precio_sin_redondear;

    @Column(precision = 19, scale = 4)
    private BigDecimal precio_publico_us;

    @Column(precision = 19, scale = 4)
    private BigDecimal porcentaje_ganancia;

    @Column(precision = 19, scale = 4,nullable = true)
    private BigDecimal costo_dolares;

    @Column(precision = 19, scale = 4,nullable = false)
    private BigDecimal costo_pesos;

    @Column(precision = 19, scale = 4)
    private BigDecimal precio_sin_iva;
    // --- FIN CAMPOS MONETARIOS --- //

    @Column(nullable = false)
    @ColumnDefault("false")
    private boolean costoFijo;

    @Column
    private LocalDate fecha_ingreso;

    @Column
    private Long proveedorId;

    @Column
    private Long tipoProductoId;

    @ManyToMany(cascade = {CascadeType.PERSIST, CascadeType.MERGE})
    @JoinTable(
            name = "productos_relacionados",
            joinColumns = @JoinColumn(name = "producto_id"),
            inverseJoinColumns = @JoinColumn(name = "producto_relacionado_id")
    )
    @OnDelete(action = OnDeleteAction.CASCADE)
    @JsonBackReference
    private Set<Producto> productosRelacionados = new HashSet<>();

    @JsonIgnore
    @ManyToMany(mappedBy = "productosRelacionados")
    private Set<Producto> relacionadoCon = new HashSet<>();

    @PrePersist
    public void generarCodigoSiNulo() {
        if (this.codigo_producto == null || this.codigo_producto.trim().isEmpty()) {
            // Genera un código único usando un prefijo y los primeros 8 caracteres de un UUID.
            // Ejemplo de resultado: "PROD-550E8400"
            this.codigo_producto = "PROD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        }
    }

    @JsonProperty("productosRelacionadosIds")
    public List<Long> getProductosRelacionadosIds() {
        if (productosRelacionados == null) {
            return List.of();
        }
        return productosRelacionados.stream()
                .map(Producto::getId)
                .collect(Collectors.toList());
    }

    public void agregarRelacion(Producto producto) {
        this.productosRelacionados.add(producto);
        producto.getProductosRelacionados().add(this);
    }

    public void eliminarRelacion(Producto producto) {
        this.productosRelacionados.remove(producto);
        producto.getProductosRelacionados().remove(this);
    }

}
