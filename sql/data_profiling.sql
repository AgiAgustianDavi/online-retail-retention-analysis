--Cek total baris
SELECT count(*) FROM online_retail t ;

--Cek total transaksi unik
SELECT count(DISTINCT t."InvoiceNo") FROM online_retail t;

-- Cek total customerID unik
SELECT count(DISTINCT t."CustomerID"  ) FROM online_retail t ;

-- Hitung total baris customerId yang kosong dan persentasenya dari keseluruhan baris data
SELECT 
	count(*) AS total_baris_kosong,
	round((count(*)::NUMERIC / (SELECT count(*) FROM online_retail t)) * 100, 2) AS pct_null
FROM online_retail t 
WHERE t."CustomerID" IS NULL
	OR t."CustomerID" = 'NaN'
	OR t."CustomerID" = 'nan'
	OR t."CustomerID" = '';

-- cek InvoiceNo berawalan C atau canceled
SELECT 
	count(*)
FROM online_retail t 
WHERE t."InvoiceNo" LIKE 'C%';

-- Cek quantity untuk baris yang InvoicNo nya diawali dengan 'C'
SELECT 
	t."InvoiceNo" ,
	t."Quantity" 
FROM online_retail t 
WHERE t."InvoiceNo" LIKE 'C%'
ORDER BY t."Quantity" DESC;


-- Cek nilai kolom quantity dan unitprice
SELECT 
	MIN(t."Quantity") AS qty_min,
	MAX(t."Quantity" ) AS qty_max,
	MIN(t."UnitPrice") AS price_min,
	MAX(t."UnitPrice" ) AS price_max
FROM online_retail t 
WHERE t."InvoiceNo" NOT LIKE 'C%';

-- Cek quantity yang <= 0
SELECT 
	count(*)
FROM online_retail t 
WHERE t."InvoiceNo" NOT LIKE 'C%' 
	AND t."Quantity" <= 0;

SELECT 
	*
FROM online_retail t 
WHERE t."InvoiceNo" NOT LIKE 'C%' 
	AND t."Quantity" <= 0;

-- Cek description yang quantity <= 0
SELECT 
	DISTINCT LOWER(t."Description"),
	count(*) AS total
FROM online_retail t 
WHERE t."InvoiceNo" NOT LIKE 'C%' 
	AND t."Quantity" <= 0
GROUP BY 1
ORDER BY total DESC ;

-- Cek unitprice yang quantity nya <= 0
SELECT 
	DISTINCT t."UnitPrice" ,
	count(*) AS total
FROM online_retail t 
WHERE t."InvoiceNo" NOT LIKE 'C%' 
	AND t."Quantity" <= 0
GROUP BY 1
ORDER BY total DESC ;

-- Cek customerID yang quantity nya <= 0
SELECT 
	DISTINCT t."CustomerID" ,
	count(*) AS total
FROM online_retail t 
WHERE t."InvoiceNo" NOT LIKE 'C%' 
	AND t."Quantity" <= 0
GROUP BY 1
ORDER BY total DESC ;

-- Cek unitprice yang <= 0
SELECT 
	count(*)
FROM online_retail t 
WHERE t."InvoiceNo" NOT LIKE 'C%' 
	AND t."UnitPrice" <= 0;

SELECT 
	*
FROM online_retail t 
WHERE t."InvoiceNo" NOT LIKE 'C%' 
	AND t."UnitPrice" <= 0;

-- Cek description yang unitprice nya <= 0
SELECT 
	DISTINCT LOWER(t."Description"),
	count(*) AS total
FROM online_retail t 
WHERE t."InvoiceNo" NOT LIKE 'C%' 
	AND t."UnitPrice" <= 0
GROUP BY 1
ORDER BY total DESC ;

-- Cek unitprice yang unitprice nya <= 0
SELECT 
	DISTINCT t."Quantity" ,
	count(*) AS total
FROM online_retail t 
WHERE t."InvoiceNo" NOT LIKE 'C%' 
	AND t."UnitPrice" <= 0
GROUP BY 1
ORDER BY total DESC ;

-- Cek customerID yang unitprice nya <= 0
SELECT 
	DISTINCT t."CustomerID" ,
	count(*) AS total
FROM online_retail t 
WHERE t."InvoiceNo" NOT LIKE 'C%' 
	AND t."UnitPrice" <= 0
GROUP BY 1
ORDER BY total DESC ;

-- Cek baris duplikat
WITH duplicate_count AS 
(
	SELECT
		t."InvoiceNo" ,
		t."StockCode" ,
		t."Description" ,
		t."InvoiceDate" ,
		t."Quantity" ,
		t."UnitPrice" ,
		t."CustomerID" ,
		t."Country" ,
		count(*) AS total
	FROM online_retail t 
	GROUP BY 
		t."InvoiceNo" ,
		t."StockCode" ,
		t."Description" ,
		t."InvoiceDate" ,
		t."Quantity" ,
		t."UnitPrice" ,
		t."CustomerID" ,
		t."Country" 
	HAVING count(*) > 1
)
SELECT 
	sum(total) AS total_baris_terdampak_duplikat,
	sum(total - 1) AS total_baris_redundant_yang_harus_dihapus
FROM duplicate_count ;






