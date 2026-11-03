# modificado por Deilany Fuentes Barquero

ruta_csv <- "data/Estadisticas.csv" #datos descargados el 15 de octubre del OIJ
fecha_descarga <- "15 de octubre de 2026"

# Fechas clave de la serie
inicio <- as.Date("2015-01-01")  # 2006-2013 casi sin registros; 2014 incompleto
fin_mes <- as.Date("2026-06-01")  # último mes completo disponible
fin_fecha <- as.Date("2026-06-30")  # último día con datos
quiebre <- as.Date("2022-10-01")  # primer mes del nivel alto (Bai-Perron)
ini_2026  <- as.Date("2026-01-01")  # inicio del tercer nivel

# Parámetros de simulación y semilla (parte 2)
nsim <- 20000
set.seed(2026)

# URL del mapa de provincias (geoBoundaries, parte 2)
url_mapa <- paste0("https://media.githubusercontent.com/media/wmgeolab/geoBoundaries/",
                   "main/releaseData/gbOpen/CRI/ADM1/geoBoundaries-CRI-ADM1_simplified.geojson")

