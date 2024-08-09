# 12/06/2024
# Dat Duong - RFM Project

SELECT *
FROM customer_transaction;
SELECT *
FROM customer_registered;

SELECT COUNT(*) FROM customer_transaction CT JOIN customer_registered CR ON CT.CustomerID = CR.ID WHERE CustomerID != 0;

SELECT
# Calculate recency, frequency, monetary:
CREATE TABLE IF NOT EXISTS cus_rfm AS (SELECT CustomerID,
                                              Contract,
                                              LocationID,
                                              BranchCode,
                                              Status,
                                              DATEDIFF('2022-09-01', MAX(Purchase_Date)) AS recency,
                                              ROUND(1.00 * COUNT(DISTINCT Purchase_Date) /
                                                    TIMESTAMPDIFF(YEAR, created_date, '2022/09/01'),
                                                    2)                                   AS frequency,
                                              ROUND(1.00 * SUM(GMV) /
                                                    TIMESTAMPDIFF(YEAR, created_date, '2022/09/01'),
                                                    2)                                   AS monetary
                                       FROM customer_transaction CT
                                                JOIN customer_registered CR
                                                     ON CT.CustomerID = CR.ID
                                       WHERE CustomerID != 0
                                       GROUP BY CustomerID, created_date);

CREATE TABLE IF NOT EXISTS rfm_calculation AS (SELECT *,
                                                      ROW_NUMBER() over (ORDER BY recency)   AS rn_recency,
                                                      ROW_NUMBER() over (ORDER BY frequency) AS rn_frequency,
                                                      ROW_NUMBER() over (ORDER BY monetary)  AS rn_monetary
                                               FROM cus_rfm);

CREATE TABLE IF NOT EXISTS rfm AS (SELECT *,
                                          CASE
                                              WHEN rn_recency >= (SELECT MIN(rn_recency) FROM rfm_calculation) AND
                                                   rn_recency < (SELECT COUNT(rn_recency) * 0.25 FROM rfm_calculation)
                                                  THEN '4'
                                              WHEN rn_recency >=
                                                   (SELECT COUNT(rn_recency * 0.25) FROM rfm_calculation) AND
                                                   rn_recency < (SELECT COUNT(rn_recency) * 0.5 FROM rfm_calculation)
                                                  THEN '3'
                                              WHEN rn_recency >=
                                                   (SELECT COUNT(rn_recency * 0.5) FROM rfm_calculation) AND
                                                   rn_recency < (SELECT COUNT(rn_recency) * 0.75 FROM rfm_calculation)
                                                  THEN '2'
                                              ELSE '1'
                                              END AS R,
                                          CASE
                                              WHEN rn_frequency >= (SELECT MIN(rn_frequency) FROM rfm_calculation) AND
                                                   rn_frequency <
                                                   (SELECT COUNT(rn_frequency) * 0.25 FROM rfm_calculation) THEN '1'
                                              WHEN rn_frequency >=
                                                   (SELECT COUNT(rn_frequency * 0.25) FROM rfm_calculation) AND
                                                   rn_frequency <
                                                   (SELECT COUNT(rn_frequency) * 0.5 FROM rfm_calculation) THEN '2'
                                              WHEN rn_frequency >=
                                                   (SELECT COUNT(rn_frequency * 0.5) FROM rfm_calculation) AND
                                                   rn_frequency <
                                                   (SELECT COUNT(rn_frequency) * 0.75 FROM rfm_calculation) THEN '3'
                                              ELSE '4'
                                              END AS F,
                                          CASE
                                              WHEN rn_monetary >= (SELECT MIN(rn_monetary) FROM rfm_calculation) AND
                                                   rn_monetary < (SELECT COUNT(rn_monetary) * 0.25 FROM rfm_calculation)
                                                  THEN '1'
                                              WHEN rn_monetary >=
                                                   (SELECT COUNT(rn_monetary * 0.25) FROM rfm_calculation) AND
                                                   rn_monetary < (SELECT COUNT(rn_monetary) * 0.5 FROM rfm_calculation)
                                                  THEN '2'
                                              WHEN rn_monetary >=
                                                   (SELECT COUNT(rn_monetary * 0.5) FROM rfm_calculation) AND
                                                   rn_monetary < (SELECT COUNT(rn_monetary) * 0.75 FROM rfm_calculation)
                                                  THEN '3'
                                              ELSE '4'
                                              END AS M
                                   FROM rfm_calculation
                                   GROUP BY CustomerID, rn_recency, rn_frequency, rn_monetary, recency, monetary,
                                            frequency);

SELECT *
FROM cus_rfm;
SELECT *
FROM rfm_calculation;
SELECT *
FROM rfm;

SELECT CONCAT(R, F, M) AS RFM,
       COUNT(*)        AS total_rfm
FROM rfm
GROUP BY CONCAT(R, F, M)
ORDER BY total_rfm DESC;

SELECT COUNT(*),
       CONCAT(R, F, M) AS RFM
FROM rfm
GROUP BY CONCAT(R, F, M)
ORDER BY 1 DESC;

SELECT *,
       CONCAT(R, F, M) AS RFM,
       CASE
           WHEN CONCAT(R, F, M) IN ('444', '443', '442', '434', '433', '432', '344', '343', '333', '334') THEN 'VIP'
           WHEN CONCAT(R, F, M) IN
                ('441', '431', '424', '423', '414', '413', '342', '332', '323', '324', '331', '243', '244', '234')
               THEN 'Loyal Customer'
           WHEN CONCAT(R, F, M) IN ('422', '421', '412', '411', '311', '312', '313', '314', '321', '322', '341')
               THEN 'New Customer'
           ELSE 'Hibernated Customer'
           END         AS customer_segmentation
FROM rfm;

SELECT COUNT(CustomerID)
FROM cus_rfm;

SELECT *
FROM cus_rfm


