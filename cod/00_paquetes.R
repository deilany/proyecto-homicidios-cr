# carga de paquetes del proyecto  
#modificado por Deilany Fuentes
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr)   # núcleo tidyverse
  library(purrr); library(stringr); library(tibble); library(ggplot2)
  library(lubridate) # manejo de fechas
  library(strucchange) # quiebres estructurales (Bai-Perron)
  library(forecast) # ETS y auto.arima para comparar
  library(knitr) # tablas en el informe
  library(sf) # mapa por provincia 
})

