# numero con coma decimal y punto de miles
fmt_dec <- function(x, d = 1) {
  format(round(x, d), decimal.mark = ",", nsmall = d, big.mark = ".", trim = TRUE)
}

# entero con punto de miles
fmt_entero <- function(x) {
  format(round(x), big.mark = ".", decimal.mark = ",", trim = TRUE)
}

# valor p con formato "p < 0,001" o "p = 0,152" (con_p = FALSE devuelve solo "< 0,001")
fmt_p <- function(p, con_p = TRUE) {
  txt <- if_else(p < 0.001, "< 0,001", str_c(if (con_p) "= " else "", format(round(p, 3), decimal.mark = ",")))
  if (con_p) str_c("p ", txt) else str_remove(txt, "^= ")
}

# nombre de mes en español a partir de su número (1-12)
nombre_mes <- function(m) {
  c("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
    "septiembre", "octubre", "noviembre", "diciembre")[m]
}

# clave de provincia: mayusculas, sin tildes ni prefijo "provincia " (para unir datos y mapa)
prov_clave <- function(x) {
  x |>
    as.character() |>
    str_remove("^Provincia ") |>
    str_trim() |>
    str_replace_all(c("Á" = "A", "É" = "E", "Í" = "I", "Ó" = "O", "Ú" = "U", "Ü" = "U", "Ñ" = "N",
                      "á" = "a", "é" = "e", "í" = "i", "ó" = "o", "ú" = "u", "ü" = "u", "ñ" = "n")) |>
    str_to_upper()
}

# nombre de provincia legible a partir de la clave
nom_prov <- function(x) {
  r <- str_to_title(x)
  r[r == "San Jose"] <- "San José"
  r[r == "Limon"]    <- "Limón"
  r
}
