package micro.microservicio_tipo_producto;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableFeignClients
@EnableDiscoveryClient
@SpringBootApplication
@EnableScheduling
@EnableCaching
public class MicroservicioTipoProductoApplication {

    public static void main(String[] args) {
        SpringApplication.run(MicroservicioTipoProductoApplication.class, args);
    }

}
