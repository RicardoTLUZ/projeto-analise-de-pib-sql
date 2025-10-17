# Projeto: Análise de PIB per Capita (Intermediário)

**Descrição curta**
Análise de séries históricas de PIB per capita por país usando um fluxo ETL simples (Python → CSV → PostgreSQL) e consultas SQL para gerar insights
---

## Estrutura do repositório

```
README.md
processar_csv.py            # script Python que gera countries.csv e gdp_per_capita.csv
pib_per_capita_countries_dataset.csv  # dataset original (raw)
countries.csv
gdp_per_capita.csv
ddl.sql                    # criações de tabelas
queries.sql                # consultas de exemplo
```

---

## Ferramentas usadas

* Python (pandas) — ETL/transformação
* PostgreSQL — armazenamento e análise
* pgAdmin 4 
---

## ETL (Resumo)

1. **Extração:** leitura do arquivo `pib_per_capita_countries_dataset.csv` com `pandas.read_csv()`.
2. **Transformação:** separar metadados de países e séries temporais (normalização):

   * `countries.csv`: `country_code`, `country_name`, `region`, `sub_region`, `intermediate_region`
   * `gdp_per_capita.csv`: `country_code`, `year`, `gdp_per_capita`, `gdp_variation`
   * remover duplicatas por `country_code` na tabela de países.
   * Observação: Os arquivos Countries e gdp_per_capita já estão nesse repositório se você já quiser importar pro pgadmin
3. **Carga:** salvar os dois CSVs e importar para o PostgreSQL (ex.: `
   \copy Countries FROM 'countries.csv' CSV HEADER;`)

> **Script usado**: `processar_csv.py` (já incluso)

```python
import pandas as pd

df = pd.read_csv('pib_per_capita_countries_dataset.csv')

countries_df = df[['country_code','country_name','region','sub_region','intermediate_region']].drop_duplicates(subset=['country_code'])
gdp_df = df[['country_code','year','gdp_per_capita','gdp_variation']]

countries_df.to_csv('countries.csv', index=False)
gdp_df.to_csv('gdp_per_capita.csv', index=False)
```

---

## DDL (criação das tabelas)

```sql
-- ddl.sql
CREATE TABLE Countries (
  country_code CHAR(3) PRIMARY KEY,
  country_name TEXT NOT NULL,
  region TEXT,
  sub_region TEXT,
  intermediate_region TEXT
);

CREATE TABLE GDP_Per_Capita (
  country_code CHAR(3) REFERENCES Countries(country_code),
  year INT NOT NULL,
  gdp_per_capita NUMERIC,
  gdp_variation NUMERIC,
  PRIMARY KEY(country_code, year)
);
```

---

## Como importar os dados no pgadmin4

* Clique com o botão direito na tabela → Import/Export → selecione o CSV, marque *Header*, ajuste delimitador e importe.

---

## Consultas principais (exemplos com explicação)

As queries abaixo demonstram análises típicas: filtros, agregações, funções de janela e subconsultas.

### 1) Países com PIB per capita > US$ 50.000 (ano 2020)

```sql
SELECT
  C.country_name,
  C.region,
  G.gdp_per_capita
FROM GDP_Per_Capita G
INNER JOIN Countries C ON G.country_code = C.country_code
WHERE G.year = 2020
  AND G.gdp_per_capita > 50000
ORDER BY G.gdp_per_capita DESC;
```

**Objetivo:** identificar as nações mais ricas por pessoa em 2020.

---

### 2) Média de PIB por continente (ano 2020)

```sql
SELECT
  C.region AS continente,
  AVG(G.gdp_per_capita) AS media_pib_per_capita
FROM GDP_Per_Capita G
INNER JOIN Countries C ON G.country_code = C.country_code
WHERE G.year = 2020
GROUP BY C.region
ORDER BY media_pib_per_capita DESC;
```

**Objetivo:** visão macro por região.

---

### 3) Países acima da média mundial (ano 2020)

```sql
SELECT
  C.country_name,
  G.gdp_per_capita
FROM GDP_Per_Capita G
INNER JOIN Countries C ON G.country_code = C.country_code
WHERE G.year = 2020
  AND G.gdp_per_capita > (
    SELECT AVG(gdp_per_capita)
    FROM GDP_Per_Capita
    WHERE year = 2020
  )
ORDER BY G.gdp_per_capita DESC;
```

**Objetivo:** filtrar países que performaram acima da média global.

---

### 4) Ranking por região (ano 2022)

```sql
SELECT
  C.region,
  C.country_name,
  G.gdp_per_capita,
  RANK() OVER (PARTITION BY C.region ORDER BY G.gdp_per_capita DESC) AS rank_na_regiao
FROM GDP_Per_Capita G
INNER JOIN Countries C ON C.country_code = G.country_code
WHERE G.year = 2022
  AND G.gdp_per_capita IS NOT NULL
  AND G.gdp_per_capita > 0;
```

**Objetivo:** entender a posição relativa dos países dentro de cada região.
