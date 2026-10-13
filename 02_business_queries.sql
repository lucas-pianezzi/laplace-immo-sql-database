-- =====================================================================
-- LAPLACE IMMO - BUSINESS QUERIES & ANALYTICS (SQLITE)
-- =====================================================================

-- Query 1: Total number of apartments sold in H1 2020
SELECT COUNT(*) AS total_apartments_sold
FROM MUTATION m
JOIN BIEN b USING(id_bien)
JOIN TYPE_BIEN t USING(code_type_local)
WHERE t.libelle_type_local = 'Appartement'
  AND m.valeur_fonciere > 0
  AND SUBSTR(m.date_mutation, 1, 4) = '2020'
  AND SUBSTR(m.date_mutation, 6, 2) BETWEEN '01' AND '06';

-- Query 2: Apartment sales breakdown by region (H1 2020)
SELECT 
    r.nom_region AS region,
    COUNT(m.id_mutation) AS sales_count
FROM MUTATION m
JOIN BIEN b USING(id_bien)
JOIN TYPE_BIEN t USING(code_type_local)
JOIN COMMUNE c USING(code_insee)
JOIN DEPARTEMENT d USING(code_departement)
JOIN REGION r USING(code_region)
WHERE t.libelle_type_local = 'Appartement'
  AND m.valeur_fonciere > 0
  AND SUBSTR(m.date_mutation, 1, 4) = '2020'
  AND SUBSTR(m.date_mutation, 6, 2) BETWEEN '01' AND '06'
GROUP BY r.code_region, r.nom_region
ORDER BY sales_count DESC;

-- Query 3: Apartment sales distribution by number of rooms
SELECT 
    b.nombre_pieces AS room_count,
    COUNT(m.id_mutation) AS sales_count,
    ROUND(COUNT(m.id_mutation) * 100.0 / SUM(COUNT(m.id_mutation)) OVER (), 2) AS percentage_share
FROM MUTATION m
JOIN BIEN b USING(id_bien)
JOIN TYPE_BIEN t USING(code_type_local)
WHERE t.libelle_type_local = 'Appartement'
  AND m.valeur_fonciere > 0
GROUP BY b.nombre_pieces
ORDER BY b.nombre_pieces;

-- Query 4: Top 10 departments by average price per square meter
SELECT 
    d.code_departement AS department_code,
    d.nom_departement AS department_name,
    ROUND(AVG(m.valeur_fonciere / b.surface_carrez_1er_lot), 2) AS avg_price_per_sqm
FROM MUTATION m
JOIN BIEN b USING(id_bien)
JOIN TYPE_BIEN t USING(code_type_local)
JOIN COMMUNE c USING(code_insee)
JOIN DEPARTEMENT d USING(code_departement)
WHERE m.valeur_fonciere > 0 
  AND b.surface_carrez_1er_lot > 0
GROUP BY d.code_departement, d.nom_departement
ORDER BY avg_price_per_sqm DESC
LIMIT 10;

-- Query 5: Average price per square meter for houses in Île-de-France
SELECT 
    t.libelle_type_local AS property_type,
    ROUND(AVG(m.valeur_fonciere / b.surface_carrez_1er_lot), 2) AS avg_price_per_sqm
FROM MUTATION m
JOIN BIEN b USING(id_bien)
JOIN TYPE_BIEN t USING(code_type_local)
JOIN COMMUNE c USING(code_insee)
JOIN DEPARTEMENT d USING(code_departement)
JOIN REGION r USING(code_region)
WHERE t.libelle_type_local = 'Maison'
  AND r.code_region = '11'
  AND m.valeur_fonciere > 0
  AND b.surface_carrez_1er_lot > 0;

-- Query 6: Top 10 most expensive apartments sold
SELECT 
    b.id_bien AS property_id,
    r.nom_region AS region,
    b.surface_carrez_1er_lot AS sqm_area,
    m.valeur_fonciere AS sale_price
FROM MUTATION m
JOIN BIEN b USING(id_bien)
JOIN TYPE_BIEN t USING(code_type_local)
JOIN COMMUNE c USING(code_insee)
JOIN DEPARTEMENT d USING(code_departement)
JOIN REGION r USING(code_region)
WHERE t.libelle_type_local = 'Appartement'
  AND m.valeur_fonciere > 0
  AND b.surface_carrez_1er_lot > 0
ORDER BY m.valeur_fonciere DESC
LIMIT 10;

-- Query 7: Sales growth rate between Q1 and Q2 2020
WITH QuarterlySummary AS (
    SELECT 
        COUNT(CASE WHEN SUBSTR(date_mutation, 6, 2) IN ('01', '02', '03') THEN 1 END) AS q1_sales,
        COUNT(CASE WHEN SUBSTR(date_mutation, 6, 2) IN ('04', '05', '06') THEN 1 END) AS q2_sales
    FROM MUTATION
)
SELECT 
    q1_sales,
    q2_sales,
    ROUND(((q2_sales - q1_sales) * 100.0) / q1_sales, 2) || '%' AS growth_rate
FROM QuarterlySummary;

-- Query 8: Regional ranking by average price/sqm for 4+ room apartments
SELECT 
    r.nom_region AS region,
    COUNT(m.id_mutation) AS sales_count,
    ROUND(AVG(m.valeur_fonciere / b.surface_carrez_1er_lot), 2) AS avg_price_per_sqm
FROM MUTATION m
JOIN BIEN b USING(id_bien)
JOIN TYPE_BIEN t USING(code_type_local)
JOIN COMMUNE c USING(code_insee)
JOIN DEPARTEMENT d USING(code_departement)
JOIN REGION r USING(code_region)
WHERE t.libelle_type_local = 'Appartement'
  AND b.nombre_pieces > 4
  AND b.surface_carrez_1er_lot > 0
  AND m.valeur_fonciere > 0
GROUP BY r.code_region, r.nom_region
ORDER BY avg_price_per_sqm DESC;

-- Query 9: Municipalities with at least 50 transactions in Q1
SELECT 
    c.code_insee AS insee_code,
    c.nom_commune AS municipality,
    COUNT(m.id_mutation) AS sales_count
FROM MUTATION m
JOIN BIEN b USING(id_bien)
JOIN COMMUNE c USING(code_insee)
WHERE SUBSTR(m.date_mutation, 6, 2) IN ('01', '02', '03')
  AND m.valeur_fonciere > 0
GROUP BY c.code_insee, c.nom_commune
HAVING COUNT(m.id_mutation) >= 50
ORDER BY sales_count DESC;

-- Query 10: Percentage price/sqm difference between 2-room and 3-room apartments
WITH UnitPrices AS (
    SELECT 
        AVG(CASE WHEN b.nombre_pieces = 2 THEN m.valeur_fonciere / b.surface_carrez_1er_lot END) AS avg_sqm_t2,
        AVG(CASE WHEN b.nombre_pieces = 3 THEN m.valeur_fonciere / b.surface_carrez_1er_lot END) AS avg_sqm_t3
    FROM MUTATION m
    JOIN BIEN b USING(id_bien)
    JOIN TYPE_BIEN t USING(code_type_local)
    WHERE t.libelle_type_local = 'Appartement'
      AND b.surface_carrez_1er_lot > 0
      AND m.valeur_fonciere > 0
)
SELECT 
    ROUND(avg_sqm_t2, 2) AS avg_sqm_t2_eur,
    ROUND(avg_sqm_t3, 2) AS avg_sqm_t3_eur,
    ROUND(((avg_sqm_t3 - avg_sqm_t2) * 100.0) / avg_sqm_t2, 2) || '%' AS price_difference_pct
FROM UnitPrices;

-- Query 11: Top 3 municipalities by average value across selected departments (Window Function)
WITH RankedMunicipalities AS (
    SELECT 
        d.code_departement AS department_code,
        c.nom_commune AS municipality,
        ROUND(AVG(m.valeur_fonciere), 2) AS avg_property_value,
        ROW_NUMBER() OVER (
            PARTITION BY d.code_departement 
            ORDER BY AVG(m.valeur_fonciere) DESC
        ) AS ranking
    FROM MUTATION m
    JOIN BIEN b USING(id_bien)
    JOIN COMMUNE c USING(code_insee)
    JOIN DEPARTEMENT d USING(code_departement)
    WHERE d.code_departement IN ('6', '13', '33', '59', '69')
      AND m.valeur_fonciere > 0
    GROUP BY d.code_departement, c.code_insee, c.nom_commune
)
SELECT department_code, municipality, avg_property_value
FROM RankedMunicipalities
WHERE ranking <= 3
ORDER BY department_code ASC, avg_property_value DESC;

-- Query 12: Top 20 municipalities by transactions per 1,000 residents (>10,000 pop.)
SELECT 
    c.code_insee AS insee_code,
    c.nom_commune AS municipality,
    c.population_municipale AS population,
    COUNT(m.id_mutation) AS total_sales,
    ROUND((COUNT(m.id_mutation) * 1000.0) / c.population_municipale, 2) AS sales_per_1000_residents
FROM MUTATION m
JOIN BIEN b USING(id_bien)
JOIN COMMUNE c USING(code_insee)
WHERE c.population_municipale > 10000
  AND m.valeur_fonciere > 0
GROUP BY c.code_insee, c.nom_commune, c.population_municipale
ORDER BY sales_per_1000_residents DESC
LIMIT 20;