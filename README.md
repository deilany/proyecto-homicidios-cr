# Proyeccion de homicidios en Costa Rica (OIJ, 2015-2026)

Proyecto Individual del curso Herramientas de Datos
** Autora:** Deilany Fuentes Barquero

## Descripcion

  Proyección actuarial del número de homicidios en Costa Rica a 12 y 24 meses,
a partir de la serie mensual del Organismo de Investigación Judicial (OIJ) 
entre enero de 2015 y junio de 2026. 
  Se usa una regresión de Poisson con cambios de nivel (detectados con una 
prueba de quiebres estructurales) y escenarios simulados.


**Objetivo.** Proyectar el nivel y el volumen de homicidios entre julio de 2026 y junio de 2027 (y hasta junio de 2028) para determinar si el incremento observado desde 2022 se mantiene.

## Estructura del repositorio

```
├── Individual_Fuentes.Rproj                          Proyecto de RStudio
├── Individual_Fuentes_HerramientasDatosI_2026.qmd    Informe en Quarto (genera el PDF)
├── README.md
├── .gitignore
├── config/
│   └── config.R             Rutas, fechas clave, semilla y parámetros
├── cod/
│   ├── 00_paquetes.R        Carga de paquetes
│   ├── 01_limpieza_datos.R        Lectura y depuración del CSV; serie mensual
│   ├── 02_funciones_formato.R         Funciones de formato y nombres de provincia
│   ├── 03_modelo_poisson.R          Quiebre estructural, modelos Poisson y validación
│   ├── 04_simulaciones.R      Simulación de escenarios y sensibilidades
│   ├── 05_analisis_exploratorio.R    Análisis exploratorio (períodos, subdelito, provincias)
│   └── 06_graficos.R         Funciones que construyen las figuras
├── data/
│   └── Estadisticas.csv     Datos crudos del OIJ [incluido / ver sección Datos]
└── info/
    ├── referencias.bib      Bibliografía
    ├── apa.csl              Estilo APA 7
    └── cri_provincias.geojson   Mapa de provincias (se descarga solo)
```

Los archivos `data/*.rds` son resultados intermedios que generan los scripts; no se suben al repositorio.

## Requisitos

- R versión  4.6.1 (2026-06-24 ucrt) y Quarto 1.9.28, con una distribución de LaTeX para generar el PDF.
- Paquetes de R: `readr`, `dplyr`, `tidyr`, `purrr`, `stringr`, `tibble`, `ggplot2`, `lubridate`, `strucchange`, `forecast`, `knitr`, `sf`.

## Cómo reproducir

1. Abrir `Individual_Fuentes.Rproj` en RStudio (así las rutas relativas parten de la raíz).
2. Colocar `Estadisticas.csv` en `data/`.
3. Ejecutar los scripts en este orden: `cod/01_limpieza_datos.R`, `cod/03_modelo_poisson.R`, `cod/04_simulaciones.R` y `cod/05_analisis_exploratorio.R`. Los scripts `00_paquetes.R`, `02_funciones_formato.R` y `06_graficos.R` los carga el resto del código.
4. Renderizar el informe:
   ```
   quarto render Individual_Fuentes_HerramientasDatosI_2026.qmd --to pdf
   ```
   Si faltan los `.rds`, el informe ejecuta los scripts por su cuenta. La primera vez que se corre `05_exploratorio.R` se descarga el mapa de provincias, por lo que se necesita internet.

## Datos

- **Fuente:** Organismo de Investigación Judicial (OIJ), Poder Judicial de Costa Rica. Estadísticas policiales: homicidios. https://pjenlinea3.poder-judicial.go.cr/estadisticasoij/
- **Fecha de descarga:** 15 de octubre de 2026.
- **Cobertura:** el archivo trae registros desde 2006, pero antes de 2015 hay muy pocos y 2014 parece incompleto; se analiza de enero de 2015 a junio de 2026.
- **Unidad:** una fila por víctima de homicidio. Se trabaja con conteos, no con tasas por 100.000 habitantes, por falta de datos de población.
- El OIJ actualiza los datos a diario, por lo que las cifras recientes podrían cambiar.
- Mapa de provincias: geoBoundaries (Runfola et al., 2020).

## Resultados principales

- Hasta septiembre de 2022, el promedio fue de unos 48 homicidios al mes; desde octubre de 2022, de unos 73 (cerca de 50 % más); en el primer semestre de 2026, de unos 61.
- Proyección a 12 meses (julio de 2026 a junio de 2027): entre 581 y 875 homicidios según el escenario (rango de 95 %).
- El modelo supone que no ocurre un nuevo cambio de nivel, por lo que es menos confiable a 24 meses que a 12.

## Limitaciones

- Modelo descriptivo: no explica las causas del cambio ni evalúa políticas.
- El nivel de 2026 se apoya en solo seis meses y el OIJ sigue depurando registros.
- Sin población, no se calculan tasas.

## Referencias

Las referencias completas están en `info/referencias.bib` y en el informe.