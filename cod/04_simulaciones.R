source("config/config.R")
source("cod/00_paquetes.R")
source("cod/02_funciones_formato.R")

#rutas
mensual <- readRDS(ruta_mensual)$mensual
homicidios <- readRDS(ruta_limpio)
modelo_tres_niveles <- readRDS(ruta_modelo)$modelo_tres_niveles

# simulacion: incertidumbre de los coeficientes (normal multivariada) 
coef_simulados <- matrix(rnorm(nsim * 3), ncol = 3) %*% chol(vcov(modelo_tres_niveles)) +
  matrix(coef(modelo_tres_niveles), nsim, 3, byrow = TRUE)
tasas_simuladas <- list("A: nivel alto"    = exp(coef_simulados[, 1] + coef_simulados[, 2]),
                        "B: nivel de 2026" = exp(coef_simulados[, 1] + coef_simulados[, 2] + coef_simulados[, 3]),
                        "C: nivel previo"  = exp(coef_simulados[, 1]))

# cuantiles de un nivel de confianza dado
cuantiles <- function(x, nivel = 0.95) {
  quantile(x, c((1 - nivel) / 2, 0.5, 1 - (1 - nivel) / 2), names = FALSE)
}


# analisis estadistico  a 12 y 24 meses por escenario (rango de 95%)
esc_tab <- imap(tasas_simuladas, function(tasa, nombre) {
  total_12m <- cuantiles(rpois(nsim, 12 * tasa)); total_24m <- cuantiles(rpois(nsim, 24 * tasa))
  tibble(escenario = nombre, nivel = mean(tasa), lo12 = total_12m[1], med12 = total_12m[2], hi12 = total_12m[3],
         lo24 = total_24m[1], med24 = total_24m[2], hi24 = total_24m[3])
}) |> list_rbind()

# trayectoria mensual (mediana y rango de 95%)
meses_futuros <- seq(fin_mes %m+% months(1), by = "month", length.out = 24)
esc_mes <- imap(tasas_simuladas, function(l, nombre) {
  q <- cuantiles(rpois(nsim, l))
  tibble(escenario = nombre, mes = meses_futuros, lo = q[1], med = q[2], hi = q[3])
}) |> list_rbind()

# sensibilidad al nivel de confianza (80, 90, 95 y 99%), total a 12 meses
sens_nivel <- map(c(0.80, 0.90, 0.95, 0.99), function(nivel_cofianza) {
  imap(tasas_simuladas, function(tasa, nombre) {
    q <- cuantiles(rpois(nsim, 12 * tasa), nivel_cofianza)
    tibble(nivel_conf = nivel_cofianza, escenario = nombre, lo = q[1], hi = q[3], ancho = q[3] - q[1])
  }) |> list_rbind()
}) |> list_rbind()

# sensibilidad del salto (cortes de la serie y fecha del quiebre)
razon_salto <- function(dat, fecha_q) {
  datos_salto <- mutate(dat, s = as.integer(mes >= fecha_q))
  unname(exp(coef(glm(homicidios ~ s, family = poisson, data = datos_salto))["s"]))
}
sens_salto <- tribble(
  ~escenario, ~datos_hasta, ~fecha_q,
  "Serie completa",as.Date("2026-06-01"), quiebre,
  "Sin 2026", as.Date("2025-12-01"), quiebre,
  "Hasta sep 2025", as.Date("2025-09-01"), quiebre,
  "Hasta jun 2025", as.Date("2025-06-01"), quiebre,
  "Quiebre un mes antes", as.Date("2026-06-01"), as.Date("2022-09-01"),
  "Quiebre un mes después", as.Date("2026-06-01"), as.Date("2022-11-01")
) |>
  mutate(razon = pmap_dbl(list(datos_hasta, fecha_q),
                          \(hasta, fecha) razon_salto(filter(mensual, mes <= hasta), fecha)))

# proyección desagregada por provincia (composición de los últimos 24 meses) 
prov_24 <- homicidios |>
  filter(Fecha >= (fin_fecha %m-% months(24)) + 1) |>
  count(clave = prov_clave(Provincia)) |>
  filter(!is.na(clave), clave != "")

# total simulado a 12 meses repartido con Dirichlet (incertidumbre de la composición) + multinomial
repartir <- function(tasa, n_sim = 5000) {
  total_simulado <- rpois(n_sim, 12 * tasa[seq_len(n_sim)])
  gamma_simulada <- matrix(rgamma(n_sim * nrow(prov_24), shape = prov_24$n), n_sim, byrow = TRUE)
  proporciones <- gamma_simulada / rowSums(gamma_simulada)
  reparto_simulado <- t(sapply(seq_len(n_sim), \(i) rmultinom(1, total_simulado[i], proporciones[i, ])))
  colnames(reparto_simulado) <- prov_24$clave
  as_tibble(reparto_simulado) |>
    pivot_longer(everything(), names_to = "clave", values_to = "n") |>
    group_by(clave) |>
    summarise(lo = quantile(n, 0.025), med = median(n), hi = quantile(n, 0.975), .groups = "drop")
}

desagregada <- imap(tasas_simuladas[c("A: nivel alto", "B: nivel de 2026")],
                    \(tasa, nombre) mutate(repartir(tasa), escenario = nombre)) |>
  list_rbind() |>
  mutate(provincia = nom_prov(clave))

# guardado 
saveRDS(list(tasas_simuladas_medio = map_dbl(tasas_simuladas, mean), esc_tab = esc_tab, esc_mes = esc_mes,
             sens_nivel = sens_nivel, sens_salto = sens_salto, desagregada = desagregada),
        "data/simulaciones.rds")

