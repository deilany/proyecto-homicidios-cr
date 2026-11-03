source("config/config.R")
source("cod/00_paquetes.R")
source("cod/02_funciones_formato.R")

mensual <- readRDS(ruta_mensual)$mensual

# detección del cambio de nivel (Bai-Perron)
serie_ts <- ts(mensual$homicidios, start = c(2015, 1), frequency = 12) # serie mensual 
quiebres_bp <- breakpoints(serie_ts ~ 1, h = 0.15) # h = 0,15 indica tramos de al menos 20 meses
quiebres_optimo <- breakpoints(quiebres_bp) # número de quiebres elegido por BIC
n_quiebres <- if (all(is.na(quiebres_optimo$breakpoints))) 0 else length(quiebres_optimo$breakpoints)

mes_quiebre <- "(no se detectó)"
if (n_quiebres >= 1) {
  fecha_quiebre_decimal <- breakdates(quiebres_bp, breaks = n_quiebres)[1]  # año decimal del ultimo mes del tramo previo
  mes_quiebre <- paste(nombre_mes(floor((fecha_quiebre_decimal - floor(fecha_quiebre_decimal)) * 12 + 0.5) + 1), floor(fecha_quiebre_decimal))
}

# modelos de regresion de Poisson
modelo_dos_niveles <- glm(homicidios ~ salto, family = poisson, data = mensual) # dos niveles
modelo_tres_niveles <- glm(homicidios ~ salto + baja, family = poisson, data = mensual) # modelo final
modelo_tendencia <- glm(homicidios ~ salto + t, family = poisson, data = mensual)  # mas efecto tendencia
modelo_estacional <- glm(homicidios ~ salto + mes_f, family = poisson, data = mensual) # mas efecto estacionalidad
modelo_covid <- glm(homicidios ~ salto + covid, family = poisson, data = mensual) # mas efecto COVID-19

# razones, niveles y diagnosticos del modelo final
coeficientes <- coef(modelo_tres_niveles)
razones_ic95 <- exp(confint(modelo_tres_niveles)) # IC 95% por verosimilitud perfilada
niveles <- c(pre = unname(exp(coeficientes[1])), alto = unname(exp(coeficientes[1] + coeficientes[2])), baja = unname(exp(coeficientes[1] + coeficientes[2] + coeficientes[3])))
razones <- tibble(termino = c("salto", "baja"),
                  razon = unname(exp(coeficientes[2:3])),
                  ic_inf = unname(razones_ic95[c("salto", "baja"), 1]),
                  ic_sup = unname(razones_ic95[c("salto", "baja"), 2]))
diagnosticos <- list(
  sobredispersion = sum(residuals(modelo_tres_niveles, type = "pearson")^2) / modelo_tres_niveles$df.residual,
  p_tendencia = anova(modelo_dos_niveles, modelo_tendencia, test = "Chisq")$`Pr(>Chi)`[2],
  p_estacional = anova(modelo_dos_niveles, modelo_estacional, test = "Chisq")$`Pr(>Chi)`[2],
  rr_covid = unname(exp(coef(modelo_covid)["covid"])),
  aic_2niveles = AIC(modelo_dos_niveles),
  aic_3niveles = AIC(modelo_tres_niveles),
  p_ljung_box  = Box.test(residuals(modelo_tres_niveles, type = "pearson"), lag = 12, type = "Ljung-Box")$p.value
)

# validacion fuera de muestra con 2026
datos_hasta_2025 <- filter(mensual, mes <= as.Date("2025-12-01")) # ajuste solo hasta dic-2025
modelo_hasta_2025 <- glm(homicidios ~ salto, family = poisson, data = datos_hasta_2025)
nivel_esperado_2026 <- unname(exp(sum(coef(modelo_hasta_2025)))) # nivel esperado para 2026
meses_2026 <- sum(mensual$mes >= ini_2026)
homicidios_2026 <- sum(mensual$homicidios[mensual$mes >= ini_2026])
validacion <- list(pred = nivel_esperado_2026, obs = homicidios_2026, esperado = meses_2026 * nivel_esperado_2026,
                   p = poisson.test(homicidios_2026, T = meses_2026, r = nivel_esperado_2026)$p.value)

# comparacion con ETS, SARIMA y promedios (origen móvil, 6 meses)
origenes <- seq(as.Date("2023-12-01"), as.Date("2025-12-01"), by = "month")

evaluar_origen <- function(origen) {
  entrenamiento <- filter(mensual, mes <= origen)  # datos disponibles en el origen
  prueba <- filter(mensual, mes > origen, mes <= origen %m+% months(6))  # 6 meses a predecir
  modelo_poisson <- glm(homicidios ~ salto, family = poisson, data = entrenamiento)
  serie_entrenamiento <- ts(entrenamiento$homicidios, frequency = 12)
  tibble(origen = origen,
         real = prueba$homicidios,
         pred_poisson = exp(sum(coef(modelo_poisson))),
         pred_ets = as.numeric(forecast(ets(serie_entrenamiento, model = "ANN"), h = 6)$mean),
         pred_arima = as.numeric(forecast(auto.arima(serie_entrenamiento, seasonal = TRUE), h = 6)$mean),
         pred_prom12 = mean(tail(entrenamiento$homicidios, 12)),
         pred_prom24 = mean(tail(entrenamiento$homicidios, 24)),
         pred_historico = mean(entrenamiento$homicidios))
}

evaluacion_origenes <- bind_rows(lapply(origenes, evaluar_origen))

# error absoluto medio (MAE) por método
mae_metodos <- evaluacion_origenes |>
  summarise(across(starts_with("pred_"), ~ mean(abs(real - .x)))) |>
  pivot_longer(everything(), names_to = "metodo", names_prefix = "pred_", values_to = "mae") |>
  arrange(mae)

# guardado
saveRDS(list(bp = quiebres_bp, n_quiebres = n_quiebres, mes_quiebre = mes_quiebre,
             modelo_tres_niveles = modelo_tres_niveles, niveles = niveles, razones = razones,
             diagnosticos = diagnosticos, validacion = validacion,
             evaluacion_origenes = evaluacion_origenes, mae_metodos = mae_metodos),
        ruta_modelo)

