# modificado por Deilany Fuentes

source("config/config.R")
source("cod/00_paquetes.R")

# lectura del CSV del OIJ 
# desface con el titulo de columnas, se omite el primer nombre 
# al ser un titulo en lugar de nombre de variable
datos <- read_csv( ruta_csv, skip = 1,
                   col_names = c("Delito", "SubDelito", "Fecha", "Hora", "Victima", "SubVictima",
                                 "Edad", "Sexo", "Nacionalidad", "Provincia", "Canton", "Distrito"),
                   col_types = cols(.default = col_character())
)

# formato de fecha
datos <- datos |>
  mutate(Fecha = ymd(Fecha))

#formato de la Ñ
datos <- datos |>
  mutate(SubDelito = str_replace_all(SubDelito, "&#209;", "Ñ"))

#guardamos tamaño y rango del archivo en crudo 
resumen_crudo <- list(n_total = nrow(datos),
                      rango = range(datos$Fecha, na.rm = TRUE))

# homicidios dentro del período de análisis, con etiqueta de nivel
homicidios <- datos |>
  filter(Fecha >= inicio, Fecha <= fin_fecha) |>
  mutate(periodo = case_when(Fecha < quiebre ~ "1_antes",
                             Fecha < ini_2026 ~ "2_alto",
                             TRUE ~ "3_2026"))

# serie mensual completa (meses sin registros cuentan como cero)
mensual <- homicidios |>
  mutate(mes = floor_date(Fecha, "month")) |>
  count(mes, name = "homicidios") |>
  complete(mes = seq(inicio, fin_mes, by = "month"), fill = list(homicidios = 0)) |>
  mutate(t = row_number(),
         mes_f = factor(month(mes)),
         salto = as.integer(mes >= quiebre),
         baja = as.integer(mes >= ini_2026),
         covid = as.integer(mes >= as.Date("2020-03-01") & mes <= as.Date("2021-12-01")),
         periodo = case_when(mes < quiebre ~ "1_antes", mes < ini_2026 ~ "2_alto", TRUE ~ "3_2026"))

# resumen por período (meses y promedio mensual), reutilizado por el informe
promedios <- mensual |>
  group_by(periodo) |>
  summarise(meses = n(),
            promedio = mean(homicidios),
            .groups = "drop")


# guardado de resultados intermedios
saveRDS(homicidios, ruta_limpio)
saveRDS(list(mensual = mensual, promedios = promedios, crudo = resumen_crudo), ruta_mensual)
