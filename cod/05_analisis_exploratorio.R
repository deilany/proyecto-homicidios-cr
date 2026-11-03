source("config/config.R")
source("cod/00_paquetes.R")
source("cod/02_funciones_formato.R")

mensual <- readRDS(ruta_mensual)$mensual
homicidios <- readRDS(ruta_limpio)

etiquetas_per <- c("1_antes" = "Ene 2015 - sep 2022", "2_alto" = "Oct 2022 - dic 2025",
                   "3_2026" = "Ene - jun 2026")

# resumen por período
tab_periodos <- mensual |>
  group_by(periodo) |>
  summarise(Meses = n(), Promedio = mean(homicidios), Minimo = min(homicidios),
            Maximo = max(homicidios), .groups = "drop") |>
  mutate(Periodo = etiquetas_per[periodo], .before = 1) |>
  select(-periodo)

meses_per <- count(mensual, periodo) # meses por periodo
n_periodos <- set_names(meses_per$n, meses_per$periodo)
promedio_periodo <- mensual |> group_by(periodo) |> summarise(m = mean(homicidios)) |> tibble::deframe()

# resumen por subdelito: ajuste de cuentas frente al resto y otros como: femicidio, riñas, no determinado, violencia dómestica...
homicidios <- homicidios |>
  mutate(grupo = if_else(str_detect(str_to_upper(SubDelito), "AJUSTE"),
                         "Ajuste de cuentas/venganza", "Otros subdelitos"))

meses_anio <- mensual |> count(anio = year(mes), name = "meses")
sub_anual <- homicidios |>
  count(anio = year(Fecha), grupo) |>
  left_join(meses_anio, by = "anio") |>
  mutate(prom = n / meses,
         etiqueta = if_else(anio == 2026, "2026*", as.character(anio)))

sub_periodo <- homicidios |>
  count(periodo, grupo) |>
  mutate(prom = n / n_periodos[periodo]) |>
  select(periodo, grupo, prom) |>
  pivot_wider(names_from = grupo, values_from = prom)

aumento_total <- promedio_periodo[["2_alto"]] - promedio_periodo[["1_antes"]]
ac_antes <- sub_periodo[["Ajuste de cuentas/venganza"]][sub_periodo$periodo == "1_antes"]
ac_alto  <- sub_periodo[["Ajuste de cuentas/venganza"]][sub_periodo$periodo == "2_alto"]
ot_antes <- sub_periodo[["Otros subdelitos"]][sub_periodo$periodo == "1_antes"]
ot_alto  <- sub_periodo[["Otros subdelitos"]][sub_periodo$periodo == "2_alto"]
subdelito <- list(ac_antes = ac_antes, ac_alto = ac_alto, ot_antes = ot_antes, ot_alto = ot_alto,
                  aporte_ac = (ac_alto - ac_antes) / aumento_total)

# promedio mensual antes y durante el nivel alto por provincia
prov_df <- homicidios |>
  mutate(clave = prov_clave(Provincia)) |>
  filter(periodo %in% c("1_antes", "2_alto")) |>
  count(clave, periodo) |>
  mutate(prom = n / n_periodos[periodo],
         Periodo = if_else(periodo == "1_antes", "Antes (ene 2015 - sep 2022)",
                           "Nivel alto (oct 2022 - dic 2025)"))

# cambio por provincia, prueba de Poisson de dos tasas y aporte al aumento total
prov_cambio <- prov_df |>
  select(clave, periodo, n) |>
  pivot_wider(names_from = periodo, values_from = n, values_fill = 0) |>
  mutate(prom_antes = `1_antes` / n_periodos[["1_antes"]],
         prom_alto  = `2_alto`  / n_periodos[["2_alto"]],
         razon = prom_alto / prom_antes,
         p = map2_dbl(`2_alto`, `1_antes`, \(a, b)
                      poisson.test(c(a, b), c(n_periodos[["2_alto"]], n_periodos[["1_antes"]]))$p.value),
         aporte = (prom_alto - prom_antes) / aumento_total,
         provincia = nom_prov(clave)) |>
  arrange(desc(aporte))

# maps de provincia
if (!file.exists(ruta_mapa)) {
  download.file(url_mapa, ruta_mapa, mode = "wb", quiet = TRUE)
}
mapa <- st_read(ruta_mapa, quiet = TRUE) |>
  mutate(clave = prov_clave(shapeName))
prov_sin_match <- setdiff(unique(prov_dfclave),mapaclave)  # control: debería ser solo "sin dato"

saveRDS(list(tab_periodos = tab_periodos, n_per = n_periodos, m_per = promedio_periodo, sub_anual = sub_anual,
             subdelito = subdelito, prov_df = prov_df, prov_cambio = prov_cambio,
             mapa = mapa, prov_sin_match = prov_sin_match),
        "data/analisis_exploratorio.rds")
