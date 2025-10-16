-- =================================================================
-- CONSULTAS DE ANÁLISE - PROJETO DE ANÁLISE DE PIB GLOBAL
-- =================================================================
-- Este arquivo contém uma série de consultas SQL para extrair
-- insights do conjunto de dados de PIB per capita mundial.
-- As consultas variam de simples seleções a análises complexas
-- com funções de janela e subconsultas.
-- =================================================================


-- Consulta 1: JOIN Simples e Filtragem
-- Objetivo: Listar países com PIB per capita superior a US$ 50.000 em 2020.
-- Conceitos: INNER JOIN, WHERE.
SELECT
  C.country_name,
  C.region,
  G.gdp_per_capita
FROM
  GDP_Per_Capita AS G
INNER JOIN
  Countries AS C ON G.country_code = C.country_code
WHERE
  G.year = 2020 AND G.gdp_per_capita > 50000
ORDER BY
  G.gdp_per_capita DESC;


-- Consulta 2: Agregação com GROUP BY
-- Objetivo: Calcular a média do PIB per capita por região (continente) no ano de 2020.
-- Conceitos: INNER JOIN, AVG(), GROUP BY, AS (alias).
SELECT
  C.region AS continente,
  AVG(G.gdp_per_capita) AS media_pib_per_capita
FROM
  GDP_Per_Capita AS G
INNER JOIN
  Countries AS C ON G.country_code = C.country_code
WHERE
  G.year = 2020
GROUP BY
  C.region
ORDER BY
  media_pib_per_capita DESC;


-- Consulta 3: Subconsulta na Cláusula WHERE
-- Objetivo: Identificar os países cujo PIB per capita em 2020 estava acima da média mundial no mesmo ano.
-- Conceitos: Subconsulta, JOIN.
SELECT
  C.country_name,
  G.gdp_per_capita
FROM
  GDP_Per_Capita AS G
INNER JOIN
  Countries AS C ON G.country_code = C.country_code
WHERE
  G.year = 2020
  AND G.gdp_per_capita > (
    SELECT AVG(gdp_per_capita)
    FROM GDP_Per_Capita
    WHERE year = 2020
  )
ORDER BY
  G.gdp_per_capita DESC;


-- Consulta 4: Funções de Janela (Window Functions) - RANK
-- Objetivo: Criar um ranking dos países por PIB per capita dentro de cada região no ano de 2022.
-- Conceitos: RANK(), OVER(), PARTITION BY.
SELECT
  C.region,
  C.country_name,
  G.gdp_per_capita,
  RANK() OVER (PARTITION BY C.region ORDER BY G.gdp_per_capita DESC) AS rank_na_regiao
FROM
  GDP_Per_Capita AS G
INNER JOIN
  Countries AS C ON C.country_code = G.country_code
WHERE
  G.year = 2022 AND G.gdp_per_capita > 0; -- Exclui países sem dados para um ranking mais limpo


-- Consulta 5: Funções de Janela (Window Functions) - LAG
-- Objetivo: Calcular a variação percentual do PIB per capita de um ano para o outro para o Brasil.
-- Conceitos: LAG(), OVER(), PARTITION BY, NULLIF para evitar divisão por zero.
SELECT
  C.country_name,
  G.year,
  G.gdp_per_capita,
  LAG(G.gdp_per_capita, 1) OVER (PARTITION BY G.country_code ORDER BY G.year) AS pib_ano_anterior,
  (
    (G.gdp_per_capita - LAG(G.gdp_per_capita, 1) OVER (PARTITION BY G.country_code ORDER BY G.year))
    /
    NULLIF(LAG(G.gdp_per_capita, 1) OVER (PARTITION BY G.country_code ORDER BY G.year), 0)
  ) * 100 AS variacao_percentual_anual
FROM
  GDP_Per_Capita AS G
JOIN
  Countries AS C ON G.country_code = C.country_code
WHERE C.country_name = 'BRAZIL'; -- Filtrando para um país específico para facilitar a análise