;-------------------------------------------------------------
; NetLogo 6.3.0 model file
; Name: modelo_economico.nlogo
;-------------------------------------------------------------

;-------------------------------------------------------------
; DEFINICIÓN DE BREEDS Y VARIABLES
;-------------------------------------------------------------
breed [producers producer]
breed [consumers consumer]

producers-own [
  precio                ;; Precio al que vende cada unidad
  calidad               ;; Calidad del bien (escala 1..3)
  inventario            ;; Unidades disponibles para vender (acumulado)
  produccion_actual     ;; Unidades que produce cada tick
  ventas_previas        ;; Unidades vendidas en el tick anterior
  precio_base           ;; Precio mínimo permitido
  capacidad_max         ;; Límite máximo de producción por tick
]

consumers-own [
  necesidad             ;; Unidades que quiere comprar este tick
  tolerancia_precio     ;; Precio máximo dispuesto a pagar
  preferencia_calidad   ;; Nivel de calidad buscada
  necesidad_base        ;; Necesidad base para cada tick
]

globals [
  escenario             ;; "estabilidad", "inflacion", "recesion", "escasez"
  precio-medio          ;; Precio promedio de todos los productores (post-ajuste)
  produccion-total      ;; Suma de produccion_actual de todos los productores (post-ajuste)
  demanda-agregada      ;; Suma de necesidad de todos los consumidores al inicio del tick
  inventario-total      ;; Suma de inventario de todos los productores (post-compra)

  lista-precios         ;; Lista interna para calcular volatilidad (últimos 20 precios)

  ;; Variables para extracción de datos antes del ajuste
  precio_preajuste
  produccion_preajuste
  inventario_preajuste
  demanda_preajuste
]

;-------------------------------------------------------------
; PROCEDIMIENTO SETUP
;-------------------------------------------------------------
to setup
  clear-all

  ;; Inicializar escenario (puedes cambiar esta línea desde Interface o Python)
  set escenario "estabilidad"  ;; opciones: "estabilidad", "inflacion", "recesion", "escasez"

  ;; 1) Crear productores (entre 15 y 24 aleatorios)
  let num-producers 15 + random 10
  create-producers num-producers [
    set color red
    set shape "person"
    setxy random-xcor random-ycor

    set precio 5 + round random 10         ;; Precio inicial entre 5 y 15
    set calidad 1 + round random 3         ;; Calidad en {1,2,3}
    set produccion_actual 40 + round random 40 ;; Producción inicial entre 40 y 80
    set ventas_previas 0
    set inventario 0                       ;; Al inicio, no hay stock acumulado
    set precio_base 5
    set capacidad_max 100 + round random 50                  ;; Cada productor no puede producir más de 100 por tick
  ]

  ;; 2) Calcular precio-medio inicial
  if any? producers [
    set precio-medio mean [precio] of producers
  ] [
    set precio-medio 0
  ]

  ;; 3) Crear consumidores (entre 250 y 299 aleatorios)
  let num-consumers 250 + random 50
  create-consumers num-consumers [
    set color yellow
    set shape "person"
    setxy random-xcor random-ycor

    set necesidad_base 1 + round random 10   ;; Entre 1 y 10
    set necesidad necesidad_base            ;; Necesidad inicial
    set tolerancia_precio precio-medio + random precio-medio
    set preferencia_calidad 1 + round random 3 ;; Preferencia calidad entre 1 y 3
  ]

  ;; 4) Inicializar variables globales
  set produccion-total sum [produccion_actual] of producers
  set demanda-agregada sum [necesidad] of consumers
  set inventario-total sum [inventario] of producers

  set volatilidad-precio 0
  set lista-precios (list precio-medio)       ;; Lista inicial con un solo precio

  ;; 5) Variables de extracción iniciales
  set precio_preajuste precio-medio
  set produccion_preajuste produccion-total
  set inventario_preajuste inventario-total
  set demanda_preajuste demanda-agregada

  reset-ticks
end


;-------------------------------------------------------------
; PROCEDIMIENTO GO
;-------------------------------------------------------------
to go

  ;; 2) Inducir dinámica macro según 'escenario'
  if escenario = "inflacion" [
    ;; Aumentar gradualmente el número de consumidores (2% más cada tick)
    let incremento round (count consumers * 0.02)
    create-consumers incremento [
      set color yellow
      set shape "person"
      setxy random-xcor random-ycor
      set necesidad_base 1 + round random 10
      set necesidad necesidad_base
      set tolerancia_precio precio-medio + random precio-medio
      set preferencia_calidad 1 + round random 3
    ]
  ]
  if escenario = "recesion" [
    ;; Reducir gradualmente el número de consumidores (2% menos cada tick)
    let a_remover round (count consumers * 0.02)
    if a_remover > 0 [
      ask n-of a_remover consumers [ die ]
    ]
  ]
  
  if escenario = "escasez" [
    ;; Limitar producción de todos los productores a un 50% de su capacidad
    ask producers [
      set capacidad_max round (capacidad_max * 0.05)
    ]
  ]
  ;; Si "estabilidad", no hacemos nada especial

  ;; 3) Fase de producción y acumulación de inventario:
  ask producers [
    set ventas_previas 0
    ;; Acumular inventario sobrante de ticks anteriores más nueva producción
    set inventario inventario + produccion_actual
  ]

  ;; 4) Calcular demanda-agregada inicial (antes de las compras)
  set demanda-agregada sum [necesidad] of consumers

  ;; 5) Almacenar estado PRE-AJUSTE para extracción de datos
  set precio_preajuste precio-medio
  set produccion_preajuste produccion-total
  set inventario_preajuste inventario-total
  set demanda_preajuste demanda-agregada

  ;; 6) Fase de compras: cada consumidor intenta cubrir su 'necesidad'
  ask consumers [
    while [ necesidad > 0 ] [
      let candidatos producers with [
        precio <= [tolerancia_precio] of myself
        and abs (calidad - [preferencia_calidad] of myself) <= 1
        and inventario >= 1
      ]
      ifelse any? candidatos [
        ;; Filtrar por radio ≤ 5
        let cercanos candidatos with [ distance myself <= 5 ]
        let elegido ifelse-value any? cercanos
          [ min-one-of cercanos [ precio ] ]       ;; Si hay cercanos, elegir al más barato
          [ min-one-of candidatos [ distance myself ] ] ;; Si no, elegir al más cercano

        ask elegido [
          set inventario inventario - 1
          set ventas_previas ventas_previas + 1
        ]
        set necesidad necesidad - 1
      ] [
        ;; Si no hay candidatos, terminamos el while para este consumidor
        set necesidad 0
      ]
    ]
  ]

  ;; 7) Recalcular producción total e inventario total tras compras
  set produccion-total sum [produccion_actual] of producers
  set inventario-total sum [inventario] of producers

  ;; 8) Ajuste de producción y precio para cada productor
  ask producers [
    let offered produccion_actual            ;; Oferta de este tick
    let sales ventas_previas                  ;; Ventas efectivas
    let leftover inventario                   ;; Inventario sobrante

    ;; 8.1) Ajustar producción:
    ifelse sales > offered [
      ;; Vendió más que produjo: subir producción al nivel de ventas, pero sin exceder capacidad_max
      let prod_nueva min list capacidad_max (round sales)
      set produccion_actual max list 1 prod_nueva
    ] [
      if leftover > 0 [
        ;; Quedó inventario: reducir producción suave según ratio_inventario
        let ratio_inventario leftover / (offered + leftover)  ;; Entre 0 y 1
        let coef (1 - 0.3 * ratio_inventario)                ;; Entre 0.7 y 1.0
        let prod_nueva round (produccion_actual * coef)
        set produccion_actual max list 1 prod_nueva
      ]
      ;; Si salió offered == sales y leftover = 0, producción se mantiene sin cambio
    ]

    ;; 8.2) Ajustar precio:
    if sales > offered [
      ;; Demanda > oferta → sube 10%, sin bajar de precio_base
      set precio max list precio_base (round (precio * 1.10))
    ] else if leftover > 0 [
      ;; Quedó inventario: bajar suavemente según ratio_inventario^0.7
      let ratio_inventario leftover / (offered + leftover)
      let factor_precio ratio_inventario ^ 0.7
      set precio max list precio_base (round (precio * factor_precio))
    ]
    ;; Si sales == offered (no hay leftover ni escasez), el precio no cambia

    ;; 8.3) Garantizar inventario no negativo
    set inventario max list 0 inventario
  ]

  ;; 9) Recalcular variables globales después del ajuste
  if any? producers [
    set precio-medio mean [precio] of producers
  ] [
    set precio-medio 0
  ]
  set produccion-total sum [produccion_actual] of producers
  set inventario-total sum [inventario] of producers

  ;; 11) Renovar necesidad y tolerancia de consumidores
  ask consumers [
    set necesidad max list 0 (necesidad_base + one-of [-2 -1 0 1 2])
    set tolerancia_precio precio-medio + random (precio-medio / 2)
  ]
  set demanda-agregada sum [necesidad] of consumers

  tick
end
