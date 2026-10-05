-- Q1
SELECT
	dk."CustomerOrderType" ,
	sum(dk."GrossRevenue" ) AS gross_revenue,
	round(100.0 * sum(dk."GrossRevenue" ) / sum(sum(dk."GrossRevenue")) OVER (),1) AS pct_dari_total
FROM data_kerja dk 
WHERE dk."MonthStart" BETWEEN '2011-01-01' AND '2011-11-01'
GROUP BY dk."CustomerOrderType" 
ORDER BY 1;

-- Q2
SELECT 
	dk."MonthStart" ,
	count(DISTINCT dk."InvoiceNo" ) FILTER (WHERE dk."CustomerOrderType" = 'Existing') AS order_existing,
	count(DISTINCT dk."InvoiceNo" ) FILTER (WHERE dk."CustomerOrderType" = 'New') AS order_new
FROM data_kerja dk 
WHERE dk."MonthStart" >= '2011-01-01' AND dk."MonthStart" < '2011-12-01'
GROUP BY dk."MonthStart" 
ORDER BY dk."MonthStart" ;

-- retention rate
WITH aktif AS 
(
	SELECT 
		DISTINCT "CustomerID",
		"MonthStart"
	FROM data_kerja
	WHERE trim("CustomerID") <>''
)
SELECT
	a."MonthStart" ,
	count(*) AS pelanggan_aktif ,
	count(b."CustomerID" ) AS kembali_bulan_depan ,
	round(100.0 * count(b."CustomerID" ) / count(*), 1) AS retention_pct
FROM aktif a
LEFT JOIN aktif b
	ON b."CustomerID" = a."CustomerID" 
	AND b."MonthStart" = (a."MonthStart" + INTERVAL '1 month')::date 
WHERE a."MonthStart" >= '2011-01-01' AND a."MonthStart" < '2011-11-01'
GROUP BY a."MonthStart" 
ORDER BY a."MonthStart" ;

-- Pecah pelanggan aktif tiap bulan ke dalam existing dan new
SELECT 
	dk."MonthStart" ,
	count(DISTINCT dk."CustomerID" ) FILTER (WHERE dk."CustomerOrderType" = 'New' ) AS pelanggan_new,
	count(DISTINCT dk."CustomerID" ) FILTER (WHERE dk."CustomerOrderType" = 'Existing' ) AS pelanggan_existing
FROM data_kerja dk
WHERE dk."CustomerOrderType" <> 'Unknown'
	AND dk."MonthStart" >= '2011-01-01' AND dk."MonthStart" < '2011-12-01'
GROUP BY dk."MonthStart" 
ORDER BY dk."MonthStart" ;

-- Rata-rata order per pelanggan aktif per bulan 
SELECT
    "MonthStart" AS bulan,
    COUNT(DISTINCT "InvoiceNo")  FILTER (WHERE "CustomerOrderType" = 'Existing') AS order_existing,
    COUNT(DISTINCT "CustomerID") FILTER (WHERE "CustomerOrderType" = 'Existing') AS pelanggan_existing,
    ROUND(
        1.0 * COUNT(DISTINCT "InvoiceNo") FILTER (WHERE "CustomerOrderType" = 'Existing')
        / NULLIF(COUNT(DISTINCT "CustomerID") FILTER (WHERE "CustomerOrderType" = 'Existing'), 0)
    , 2) AS order_per_pelanggan_existing,
    COUNT(DISTINCT "InvoiceNo")  FILTER (WHERE "CustomerOrderType" = 'New') AS order_new,
    COUNT(DISTINCT "CustomerID") FILTER (WHERE "CustomerOrderType" = 'New') AS pelanggan_new,
    ROUND(
        1.0 * COUNT(DISTINCT "InvoiceNo") FILTER (WHERE "CustomerOrderType" = 'New')
        / NULLIF(COUNT(DISTINCT "CustomerID") FILTER (WHERE "CustomerOrderType" = 'New'), 0)
    , 2) AS order_per_pelanggan_new
FROM data_kerja
WHERE TRIM("CustomerID") <> ''
  AND "MonthStart" >= '2011-01-01'
  AND "MonthStart" <  '2011-12-01'
GROUP BY "MonthStart"
ORDER BY "MonthStart";

-- Pertumbuhan order per bulan (existing vs new)
WITH bulanan AS (
    SELECT
        "MonthStart" AS bulan,
        COUNT(DISTINCT "InvoiceNo") FILTER (WHERE "CustomerOrderType" = 'Existing') AS order_existing,
        COUNT(DISTINCT "InvoiceNo") FILTER (WHERE "CustomerOrderType" = 'New')      AS order_new
    FROM data_kerja
    WHERE TRIM("CustomerID") <> ''
      AND "MonthStart" >= '2011-01-01'
      AND "MonthStart" <  '2011-12-01'
    GROUP BY "MonthStart"
),
tumbuh AS (
    SELECT
        bulan,
        order_existing,
        order_new,
        ROUND(100.0 * (order_existing - LAG(order_existing) OVER (ORDER BY bulan))
              / NULLIF(LAG(order_existing) OVER (ORDER BY bulan), 0), 1) AS tumbuh_existing_pct,
        ROUND(100.0 * (order_new - LAG(order_new) OVER (ORDER BY bulan))
              / NULLIF(LAG(order_new) OVER (ORDER BY bulan), 0), 1)      AS tumbuh_new_pct
    FROM bulanan
)
SELECT
    bulan,
    order_existing,
    order_new,
    tumbuh_existing_pct,
    tumbuh_new_pct,
    tumbuh_existing_pct > tumbuh_new_pct AS existing_lebih_cepat
FROM tumbuh
WHERE tumbuh_existing_pct IS NOT NULL   -- buang Januari
ORDER BY bulan;

-- Total bulan unggul antara existing dan new
WITH bulanan AS (
    SELECT
        "MonthStart" AS bulan,
        COUNT(DISTINCT "InvoiceNo") FILTER (WHERE "CustomerOrderType" = 'Existing') AS order_existing,
        COUNT(DISTINCT "InvoiceNo") FILTER (WHERE "CustomerOrderType" = 'New')      AS order_new
    FROM data_kerja
    WHERE TRIM("CustomerID") <> ''
      AND "MonthStart" >= '2011-01-01'
      AND "MonthStart" <  '2011-12-01'
    GROUP BY "MonthStart"
),
tumbuh AS (
    SELECT
        bulan,
        100.0 * (order_existing - LAG(order_existing) OVER (ORDER BY bulan))
              / NULLIF(LAG(order_existing) OVER (ORDER BY bulan), 0) AS tumbuh_existing_pct,
        100.0 * (order_new - LAG(order_new) OVER (ORDER BY bulan))
              / NULLIF(LAG(order_new) OVER (ORDER BY bulan), 0)      AS tumbuh_new_pct
    FROM bulanan
)
SELECT
    COUNT(*) FILTER (WHERE tumbuh_existing_pct > tumbuh_new_pct) AS bulan_existing_lebih_cepat,
    COUNT(*)                                                      AS total_perbandingan
FROM tumbuh
WHERE tumbuh_existing_pct IS NOT NULL;

-- Retention per CustomerOrderType
WITH aktif AS 
(
	SELECT 
		DISTINCT "CustomerID",
		"MonthStart",
		"CustomerOrderType"
	FROM data_kerja
	WHERE trim("CustomerID") <>''
)
SELECT
	count(*) FILTER (WHERE a."CustomerOrderType" = 'New') AS new_aktif,
	round(100.0 * count(b."CustomerID") FILTER (WHERE a."CustomerOrderType" = 'New') 
		/ count(*) FILTER (WHERE a."CustomerOrderType" = 'New'), 1) AS retention_new_pct,
	count(*) FILTER (WHERE a."CustomerOrderType" = 'Existing') AS existing_aktif,
	round(100.0 * count(b."CustomerID") FILTER (WHERE a."CustomerOrderType" = 'Existing') 
		/ count(*) FILTER (WHERE a."CustomerOrderType" = 'Existing'), 1) AS retention_existing_pct
FROM aktif a
LEFT JOIN aktif b
	ON b."CustomerID" = a."CustomerID" 
	AND b."MonthStart" = (a."MonthStart" + INTERVAL '1 month')::date 
WHERE a."MonthStart" >= '2011-01-01' AND a."MonthStart" < '2011-11-01';

-- Cek jarak hari pembelian kembali pelanggan
WITH order_pelanggan AS 
(
	SELECT
		"CustomerID" ,
		"InvoiceNo" ,
		min("InvoiceDate")::date AS tgl
	FROM data_kerja
	WHERE trim("CustomerID") <> '' 	
		AND "MonthStart" >= '2011-01-01' 
		AND "MonthStart" < '2011-12-01'
	GROUP BY "CustomerID", "InvoiceNo"
),
jarak AS 
(
	SELECT tgl - lag(tgl) OVER (PARTITION BY "CustomerID" ORDER BY tgl) AS hari
	FROM order_pelanggan
)
SELECT 
	count(*) AS jml_jarak,
	percentile_cont(0.25) WITHIN GROUP (ORDER BY hari) AS p25,
	percentile_cont(0.50) WITHIN GROUP (ORDER BY hari) AS median,
	percentile_cont(0.75) WITHIN GROUP (ORDER BY hari) AS p75
FROM jarak
WHERE hari > 0;

-- Membuat rentang pembelian kembali
WITH order_pelanggan AS 
(
	SELECT
		"CustomerID" ,
		"InvoiceNo" ,
		min("InvoiceDate")::date AS tgl
	FROM data_kerja
	WHERE trim("CustomerID") <> ''
	GROUP BY "CustomerID", "InvoiceNo"
),
jarak AS 
(
	SELECT 
		tgl,
		tgl - lag(tgl) OVER (PARTITION BY "CustomerID" ORDER BY tgl) AS hari
	FROM order_pelanggan
),
bucket AS
(
	SELECT CASE
		WHEN hari <= 7 THEN 1
		WHEN hari <= 14 THEN 2
		WHEN hari <= 21 THEN 3
		WHEN hari <= 30 THEN 4
		WHEN hari <= 45 THEN 5
		WHEN hari <= 60 THEN 6
		WHEN hari <= 90 THEN 7
	ELSE 8
	END	AS urutan
	FROM jarak
	WHERE hari > 0
		AND tgl >= DATE '2011-01-01'
		AND tgl < DATE '2011-12-01'
)
SELECT 
	urutan,
	CASE urutan
		WHEN 1 THEN '1-7' WHEN 2 THEN '8-14'
		WHEN 3 THEN '15-21' WHEN 4 THEN '22-30'
		WHEN 5 THEN '31-45' WHEN 6 THEN '46-60'
		WHEN 7 THEN '61-90' ELSE '>90'
	END AS rentang_hari,
	count(*) AS jumlah,
	round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct,
	round(100.0 * sum(count(*)) OVER (ORDER BY urutan)
		/ sum(count(*)) OVER (), 1) AS kumulatif_pct
FROM bucket
GROUP BY urutan
ORDER BY urutan;

-- Pct pelanggan existing kembali dalam 60 hari
WITH order_pel AS (
  SELECT "CustomerID", "InvoiceNo",
         MIN("InvoiceDate")::date AS tgl,
         MIN("MonthStart") AS bulan,
         MIN("CustomerOrderType") AS tipe
  FROM data_kerja
  WHERE TRIM("CustomerID") <> ''
  GROUP BY "CustomerID", "InvoiceNo"
),
terakhir AS (
  SELECT "CustomerID", bulan, tipe, MAX(tgl) AS tgl_akhir
  FROM order_pel
  GROUP BY "CustomerID", bulan, tipe
)
SELECT COUNT(*) AS pelanggan_existing,
       SUM(kembali) AS kembali_60_hari,
       ROUND(100.0 * SUM(kembali) / COUNT(*), 1) AS pct_kembali_60_hari
FROM (
  SELECT t."CustomerID",
         CASE WHEN EXISTS (
           SELECT 1 FROM order_pel o
           WHERE o."CustomerID" = t."CustomerID"
             AND o.tgl > t.tgl_akhir
             AND o.tgl <= t.tgl_akhir + 60
         ) THEN 1 ELSE 0 END AS kembali
  FROM terakhir t
  WHERE t.tipe = 'Existing'
    AND t.bulan >= '2011-01-01' AND t.bulan < '2011-10-01'
) x;

-- Skenario dampak retention existing naik 5 poin
WITH nilai AS (
    SELECT
        SUM("GrossRevenue")::numeric / COUNT(DISTINCT "InvoiceNo") AS rev_per_order
    FROM data_kerja
    WHERE "CustomerOrderType" = 'Existing'
      AND "MonthStart" >= '2011-01-01'
      AND "MonthStart" <  '2011-12-01'
),
okt AS (
    SELECT
        COUNT(DISTINCT "CustomerID") AS pelanggan_aktif,
        1.0 * COUNT(DISTINCT "InvoiceNo") / COUNT(DISTINCT "CustomerID") AS order_per_pelanggan
    FROM data_kerja
    WHERE "CustomerOrderType" = 'Existing'
      AND "MonthStart" >= '2011-10-01'
      AND "MonthStart" <  '2011-11-01'
)
SELECT
    ROUND(nilai.rev_per_order, 0)                                   AS revenue_per_order,
    okt.pelanggan_aktif                                             AS pelanggan_existing_okt,
    ROUND(okt.order_per_pelanggan, 2)                               AS order_per_pelanggan,
    ROUND(okt.pelanggan_aktif * 0.05)                               AS tambahan_pelanggan,
    ROUND(okt.pelanggan_aktif * 0.05 * okt.order_per_pelanggan)     AS tambahan_order,
    ROUND(okt.pelanggan_aktif * 0.05 * okt.order_per_pelanggan
          * nilai.rev_per_order)                                    AS tambahan_revenue
FROM nilai, okt;





	
	
	
	
	