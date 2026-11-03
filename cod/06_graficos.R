tema_informe <- theme_minimal(base_size = 10) + theme(legend.position = "bottom")

# Fig. 1: serie mensual con el promedio de cada período rotulado directamente
g_serie <- function(mensual) {
  etiquetas <- c("1_antes" = "Ene 2015 - Sep 2022",
                 "2_alto"  = "Oct 2022 - Dic 2025",
                 "3_2026"  = "2026")
  colores <- c("1_antes" = "#4f4957", "2_alto" = "#d50000", "3_2026" = "#1800AD")
  
  # Un registro por período: dónde empieza, dónde termina, promedio y altura del rótulo
  periodos <- mensual |>
    group_by(periodo) |>
    summarise(inicio_p = min(mes), maximo = max(homicidios),
              promedio = mean(homicidios), fin_p = max(mes), .groups = "drop") |>
    arrange(inicio_p) |>
    mutate(fin_p = coalesce(lead(inicio_p), fin_p),   # el tramo llega hasta el siguiente
           centro = inicio_p + (fin_p - inicio_p) / 2,
           y_numero = maximo + 0.11 * max(mensual$homicidios),
           y_nombre = maximo + 0.05 * max(mensual$homicidios))
  
  ggplot(mensual, aes(mes, homicidios)) +
    geom_line(color = "grey35", linewidth = 0.4) +
    geom_vline(xintercept = c(quiebre, ini_2026), linetype = "dashed", color = "grey45") +
    geom_segment(data = periodos,
                 aes(x = inicio_p, xend = fin_p, y = promedio, yend = promedio, color = periodo),
                 linewidth = 1.1) +
    geom_text(data = periodos,
              aes(x = centro, y = y_numero, label = fmt_dec(promedio), color = periodo),
              fontface = "bold", size = 2.8) +
    geom_text(data = periodos,
              aes(x = centro, y = y_nombre, label = etiquetas[periodo], color = periodo),
              size = 2.1) +
    scale_color_manual(values = colores, guide = "none") +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y",
                 expand = expansion(mult = c(0.01, 0.05))) +
    coord_cartesian(ylim = c(0, 1.2 * max(mensual$homicidios))) +
    labs(x = NULL, y = "Homicidios por mes") +
    theme_minimal(base_size = 10) +
    theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
          axis.line = element_line(color = "grey30"))
}

# Fig. 2: mapa por provincia (antes y nivel alto); sin la Isla del Coco
g_mapa <- function(mapa, prov_df) {
  niveles_p <- c("Antes (ene 2015 - sep 2022)", "Nivel alto (oct 2022 - dic 2025)")
  mapa_df <- prov_df |>
    select(clave, prom, Periodo) |>
    inner_join(mapa, by = "clave") |>
    st_as_sf() |>
    mutate(Periodo = factor(Periodo, levels = niveles_p),
           etiqueta = as.character(round(prom)))
  ggplot(mapa_df) +
    geom_sf(aes(fill = prom), color = "white", linewidth = 0.3) +
    geom_sf_text(aes(label = etiqueta), size = 2.6) +
    coord_sf(xlim = c(-86.0, -82.5), ylim = c(8.0, 11.3), expand = FALSE) +
    facet_wrap(~ Periodo) +
    scale_fill_gradient(low = "#fee8c8", high = "#b30000", name = "Prom. mensual") +
    theme_void(base_size = 9) + theme(legend.position = "right")
}

# Fig. 3: promedio mensual por año según subdelito
g_subdelito <- function(sub_anual) {
  ggplot(sub_anual, aes(etiqueta, prom, fill = grupo)) +
    geom_col(width = 0.75) +
    scale_fill_manual(values = c("Ajuste de cuentas/venganza" = "#B22222",
                                 "Otros subdelitos" = "grey65")) +
    labs(x = NULL, y = "Promedio mensual", fill = NULL) +
    tema_informe
}

# Fig. 4: serie desde 2021 y escenarios (mediana y rango de 95%)
g_escenarios <- function(mensual, esc_mes) {
  cols <- c("A: nivel alto" = "#0072B2", "B: nivel de 2026" = "#D55E00", "C: nivel previo" = "#009E73")
  ggplot() +
    geom_line(data = filter(mensual, mes >= as.Date("2021-01-01")),
              aes(mes, homicidios), color = "grey40", linewidth = 0.4) +
    geom_ribbon(data = esc_mes, aes(mes, ymin = lo, ymax = hi, fill = escenario), alpha = 0.15) +
    geom_line(data = esc_mes, aes(mes, med, color = escenario), linewidth = 0.9, linetype = "dashed") +
    geom_vline( xintercept = as.Date("2026-07-01"), linetype = "dashed", color = "grey55",linewidth = 0.5 ) +
    scale_color_manual(values = cols) + scale_fill_manual(values = cols) +
    labs(x = NULL, y = "Homicidios por mes", color = NULL, fill = NULL) +
    tema_informe
}

# Fig. A1: proyección a 12 meses por provincia (mediana y rango de 95%)
g_desagregada <- function(desagregada) {
  ggplot(desagregada, aes(reorder(provincia, med), med, color = escenario)) +
    geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(width = 0.6),
                    size = 0.7, linewidth = 0.7) +
    scale_color_manual(values = c("A: nivel alto" = "#0072B2", "B: nivel de 2026" = "#D55E00")) +
    coord_flip() +
    labs(x = NULL, y = "Homicidios proyectados a 12 meses", color = NULL) +
    tema_informe
}

