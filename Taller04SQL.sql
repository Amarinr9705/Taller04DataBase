USE Monedas

;WITH ConteoPaises AS (
    SELECT 
        m.Id,
        COUNT(p.Id) AS TotalPaises
    FROM Moneda m
    LEFT JOIN Pais p ON p.IdMoneda = m.Id
    GROUP BY m.Id
),

UltimoCambio AS (
    SELECT 
        IdMoneda,
        MAX(Fecha) AS UltimaFecha
    FROM CambioMoneda
    GROUP BY IdMoneda
),

ValorUltimo AS (
    SELECT 
        c.IdMoneda,
        c.Cambio AS UltimoCambio
    FROM CambioMoneda c
    INNER JOIN UltimoCambio u 
        ON c.IdMoneda = u.IdMoneda
       AND c.Fecha = u.UltimaFecha
),

Promedio30Dias AS (
    SELECT 
        c.IdMoneda,
        AVG(c.Cambio) AS Promedio30Dias
    FROM CambioMoneda c
    WHERE c.Fecha >= DATEADD(DAY, -30, GETDATE())
    GROUP BY c.IdMoneda
),

VolatilidadDatos AS (
    SELECT 
        m.Id AS IdMoneda,
        STDEV(CASE WHEN c.Fecha >= DATEADD(DAY, -30, GETDATE()) THEN c.Cambio END) AS Desv30Dias,
        STDEV(c.Cambio) AS DesvTotal
    FROM Moneda m
    LEFT JOIN CambioMoneda c ON c.IdMoneda = m.Id
    GROUP BY m.Id
),

Volatilidad AS (
    SELECT 
        IdMoneda,
        CASE 
            WHEN Desv30Dias IS NOT NULL THEN 
                CASE 
                    WHEN Desv30Dias > 0.10 THEN 'Alta'
                    WHEN Desv30Dias >= 0.05 THEN 'Media'
                    ELSE 'Estable'
                END
            WHEN DesvTotal IS NOT NULL THEN 
                CASE 
                    WHEN DesvTotal > 0.10 THEN 'Alta'
                    WHEN DesvTotal >= 0.05 THEN 'Media'
                    ELSE 'Estable'
                END
            ELSE 'Estable'
        END AS Volatilidad
    FROM VolatilidadDatos
)

SELECT 
    m.Id,
    m.Moneda,
    m.Sigla,
    ISNULL(cp.TotalPaises, 0) AS TotalPaises,
    uc.UltimaFecha,
    v.UltimoCambio,
    p30.Promedio30Dias,
    vol.Volatilidad,
    RANK() OVER (ORDER BY ISNULL(cp.TotalPaises, 0) DESC) AS RankingUso
FROM Moneda m
LEFT JOIN ConteoPaises cp        ON cp.Id = m.Id
LEFT JOIN UltimoCambio uc        ON uc.IdMoneda = m.Id
LEFT JOIN ValorUltimo v          ON v.IdMoneda = m.Id
LEFT JOIN Promedio30Dias p30     ON p30.IdMoneda = m.Id
LEFT JOIN Volatilidad vol        ON vol.IdMoneda = m.Id
ORDER BY TotalPaises DESC, m.Id;

