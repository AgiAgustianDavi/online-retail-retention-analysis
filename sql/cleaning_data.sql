CREATE TABLE data_kerja AS
SELECT * FROM online_retail t ;

SELECT count(*) FROM data_kerja dk ;

-- Cek tipe data kolom
SELECT 
	column_name,
	data_type
FROM information_schema."columns"
WHERE table_name = 'data_kerja';

-- Cek format InvoiceDate
SELECT dk."InvoiceDate"  FROM data_kerja dk LIMIT 5;

SELECT count(*) FROM data_kerja dk
WHERE dk."InvoiceDate" !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$';

-- Ubah tipe data InvoiceDate
ALTER TABLE data_kerja 
ALTER COLUMN "InvoiceDate" TYPE timestamp
USING "InvoiceDate"::timestamp;

-- Cek perubahan tipe data InvoiceDate
SELECT 
	min(dk."InvoiceDate" ),
	max(dk."InvoiceDate" )
FROM data_kerja dk ;

-- Data problem #1
-- Invoice C / canceled

-- Cek jumlah baris dan nilainya
SELECT
	count(*) FILTER (WHERE dk."InvoiceNo" LIKE 'C%') AS total_baris_c,
	round(sum(dk."Quantity" * dk."UnitPrice" ) FILTER (WHERE dk."InvoiceNo" LIKE 'C%')::NUMERIC, 2) AS nilai_c,
	round(sum(dk."Quantity" * dk."UnitPrice" )::NUMERIC, 2) AS nilai_total
FROM data_kerja dk ;

-- Hapus Invoice C
DELETE FROM data_kerja WHERE "InvoiceNo" LIKE 'C%';

SELECT count(*) FROM data_kerja dk;

SELECT sum(dk."Quantity" * dk."UnitPrice" ) FROM data_kerja dk ;

-- Data problem #2
-- Quantity & UnitPrice <= 0

-- Cek jumlah baris dan nilainya
SELECT
	count(*) FILTER (WHERE dk."Quantity" <= 0 OR dk."UnitPrice" <= 0) AS total_gabungan,
	count(*) FILTER (WHERE dk."Quantity" <= 0) AS qty_bermasalah,
	count(*) FILTER (WHERE dk."UnitPrice" <= 0) AS price_bermasalah,
	count(*) FILTER (WHERE dk."Quantity" <= 0 AND dk."UnitPrice" <= 0) AS total_keduanya,
	round(sum(dk."Quantity" * dk."UnitPrice" ) FILTER (WHERE dk."Quantity" <= 0 OR dk."UnitPrice" <= 0)::NUMERIC, 2) AS nilai
FROM data_kerja dk ;

-- Hapus Quantity & UnitPrice <= 0
DELETE FROM data_kerja 
WHERE "Quantity" <= 0 OR "UnitPrice" <= 0;

SELECT 
	count(*) ,
	sum(dk."Quantity" * dk."UnitPrice" )
FROM data_kerja dk ;

-- Data problem #3
-- Data duplikat 

-- Cek jumlah baris duplikat dan nilainya
SELECT 
	count(*) AS salinan_berlebih,
	round(sum("Quantity" * "UnitPrice")::NUMERIC,2) AS nilai
FROM 
(
	SELECT 
		*,
		row_number() OVER (PARTITION BY "InvoiceNo", "StockCode", "Description", "Quantity", 
							"InvoiceDate", "UnitPrice", "CustomerID", "Country"
							ORDER BY ctid) AS rn
	FROM data_kerja
) t
WHERE rn > 1;

-- Hapus baris duplikat
DELETE FROM data_kerja 
WHERE ctid IN 
(
	SELECT ctid FROM 
	(
		SELECT
			ctid,
			row_number() over(PARTITION BY "InvoiceNo", "StockCode", "Description", "Quantity", 
							"InvoiceDate", "UnitPrice", "CustomerID", "Country"
							ORDER BY ctid) AS rn
		FROM data_kerja
	)t
	WHERE rn > 1
);

-- Verifikasi
SELECT 
	count(*) ,
	sum("Quantity" * "UnitPrice")
FROM data_kerja;

-- Data problem #4
-- Membuat kolom baru: GrossRevenue, MonthStart, dan CustomerOrderType

-- GrossRevenue & MonthStart
ALTER TABLE data_kerja 
	ADD COLUMN "GrossRevenue" numeric(12,2),
	ADD COLUMN "MonthStart" date;

UPDATE data_kerja
SET "GrossRevenue" = round(("Quantity" * "UnitPrice")::NUMERIC,2),
	"MonthStart" = date_trunc('month', "InvoiceDate")::date;

-- Cek hasil
SELECT
	dk."MonthStart" ,
	count(DISTINCT dk."InvoiceNo" ) AS order_unik,
	sum(dk."GrossRevenue" ) AS gross_revenue
FROM data_kerja dk 
GROUP BY dk."MonthStart" 
ORDER BY dk."MonthStart" ;

-- CustomerOrderType
-- Cek null di customerID
SELECT 
	count(*) FILTER (WHERE "CustomerID" IS NULL ) AS total_null,
	count(*) FILTER (WHERE TRIM("CustomerID") = '' ) AS total_kosong,
	count(*) FILTER (WHERE "CustomerID" LIKE '%.%') AS pakai_titk,
	count(DISTINCT "CustomerID") AS id_unik
FROM data_kerja ;

-- Buat kolom
ALTER TABLE data_kerja 
ADD COLUMN "CustomerOrderType" text;

-- buat defenisi CustomerID yang kosong
UPDATE data_kerja
SET "CustomerOrderType" = 'Unknown'
WHERE trim("CustomerID") = '';

-- baris dengan ID New jika bulan ini sama dengan bulan pertama pelanggan, selain itu existing
UPDATE data_kerja dk
SET "CustomerOrderType" = CASE
	WHEN dk."MonthStart" = f.first_month THEN 'New'
	ELSE 'Existing' 
	END
FROM 
(
	SELECT
		"CustomerID",
		min("MonthStart") AS first_month
	FROM data_kerja
	WHERE trim("CustomerID") <> ''
	GROUP BY "CustomerID"
) f
WHERE dk."CustomerID" = f."CustomerID" ;

-- Verifikasi hasil
SELECT 
	"CustomerOrderType",
	count(*) AS baris,
	count(DISTINCT "InvoiceNo") AS order_unik,
	sum("GrossRevenue") AS gross_revenue,
	count(DISTINCT "CustomerID") AS pelanggan
FROM data_kerja
GROUP BY "CustomerOrderType"
ORDER BY 1;






