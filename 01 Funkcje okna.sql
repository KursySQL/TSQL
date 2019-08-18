/*

	FUNKCJE OKNA W SQL SERVER
	Tomasz Lbera | MVP Data Platform
	tomasz.libera@datacommunity.pl
	http://bit.ly/tsqlcourse

*/



USE AdventureWorks2014
GO


/*
	Demo 1 
	- Wprowadzenie
	- Partycja
	- Ramka
*/


-- bez grupowania
SELECT OrderDate
	,CustomerID, SalesOrderNumber, TotalDue
FROM Sales.SalesOrderHeader
ORDER BY OrderDate ASC


-- GROUP BY 
SELECT OrderDate
	--,CustomerID, SalesOrderNumber, TotalDue
	,SUM(TotalDue)
FROM Sales.SalesOrderHeader
GROUP BY OrderDate
ORDER BY OrderDate

-- ?? jaki klient? jakie numery zamówieñ?

-- PARTYCJA: data (dzieñ) sprzeda¿y
SELECT OrderDate, CustomerID, SalesOrderNumber, TotalDue
	,SUM(TotalDue) OVER (PARTITION BY OrderDate) AS TotalDueDate
FROM Sales.SalesOrderHeader
WHERE OrderDate > '20110531'
ORDER BY OrderDate ASC


-- RAMKA: dodanie ORDER BY daje sumê krocz¹c¹, kolejnoœæ wyznaczona numeracj¹ zamówieñ
SELECT OrderDate, CustomerID, SalesOrderNumber, TotalDue
	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber) AS TotalDueDateRunningSUM
FROM Sales.SalesOrderHeader
WHERE OrderDate > '20110531'
ORDER BY OrderDate ASC


-- jedno zapytanie - dwa wyra¿enia
SELECT OrderDate, CustomerID, SalesOrderNumber, TotalDue
	,SUM(TotalDue) OVER (PARTITION BY OrderDate) AS TotalDueDateSUM
	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber) AS TotalDueDateRunningSUM
	,SUM(TotalDue) OVER () 
FROM Sales.SalesOrderHeader
WHERE OrderDate > '20110531'
ORDER BY OrderDate ASC
-- ***



/*
	Demo 2 
	Przyk³ady funkcji okna
	- agreguj¹ce (SUM, MIN, MAX, AVG)
	- szereguj¹ce - ranguj¹ce (RANK, DENSE_RANK, ROW_NUMBER, NTILE)
	- analityczne (...)
*/


-- agreguj¹ce
SELECT CustomerID, SalesOrderNumber, OrderDate, CurrencyRateID, TotalDue
	,SUM(TotalDue) OVER (PARTITION BY OrderDate) AS TotalDueDateSUM
	,AVG(TotalDue) OVER (PARTITION BY OrderDate) AS TotalDueDateAVG
	,MIN(TotalDue) OVER (PARTITION BY OrderDate) AS TotalDueDateMIN
	,MAX(TotalDue) OVER (PARTITION BY OrderDate) AS TotalDueDateMAX
	,COUNT(*) OVER (PARTITION BY OrderDate) AS TotalDueDateCOUNT
	,COUNT(CurrencyRateID) OVER (PARTITION BY OrderDate) AS TotalDueDateCOUNT_CurrencyRateID
	-- ,COUNT(DISTINCT CurrencyRateID) OVER (PARTITION BY OrderDate) AS TotalDueDateCOUNT_DISTINCT
FROM Sales.SalesOrderHeader
WHERE OrderDate > '20110531'
ORDER BY OrderDate ASC


-- szereguj¹ce
SELECT CustomerID, SalesOrderNumber, OrderDate, CurrencyRateID, TotalDue
	,RANK() OVER (PARTITION BY OrderDate ORDER BY TotalDue DESC) AS TotalDueRANK
	,DENSE_RANK() OVER (PARTITION BY OrderDate ORDER BY TotalDue DESC) AS TotalDueDENSE_RANK
	,ROW_NUMBER() OVER (PARTITION BY OrderDate ORDER BY TotalDue DESC) AS TotalDueROW_NUMBER
	,ROW_NUMBER() OVER (ORDER BY TotalDue DESC) AS TotalDueROW_NUMBER2
FROM Sales.SalesOrderHeader
WHERE OrderDate > '20110531'
--ORDER BY OrderDate ASC, TotalDue DESC
ORDER BY Custim

-- stronnicowanie za pomoc¹ ROW_NUMBER
WITH Paging_CTE AS
(
	SELECT CustomerID, SalesOrderNumber, OrderDate, CurrencyRateID, TotalDue
		,ROW_NUMBER() OVER (ORDER BY OrderDate) AS RowNumber
	FROM Sales.SalesOrderHeader
)
SELECT * FROM Paging_CTE 
WHERE RowNumber >= 101 AND RowNumber <= 200

-- stronnicowanie za pomoc¹ OFFSET... FETCH (SQL Server 2012+)
SELECT CustomerID, SalesOrderNumber, OrderDate, TotalDue
FROM Sales.SalesOrderHeader
ORDER BY OrderDate ASC OFFSET 100 ROWS 
FETCH NEXT 100 ROWS ONLY;


-- szereguj¹ce c.d. NTILE
SELECT  CustomerID, SalesOrderNumber, OrderDate, TotalDue
	,NTILE(3) OVER (PARTITION BY OrderDate ORDER BY TotalDue DESC) AS TotalDueNTILE3
	,NTILE(2) OVER (PARTITION BY OrderDate ORDER BY TotalDue DESC) AS TotalDueNTILE2
	,NTILE(3) OVER (ORDER BY OrderDate) AS TotalDueRANK3All
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '20110605' AND OrderDate <= '20110607'
ORDER BY OrderDate ASC




-- analityczne: LAG, LEAD
SELECT  CustomerID, SalesOrderNumber, OrderDate, TotalDue
	,LAG(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber) AS TotalDue_Lag
	,LEAD(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber) AS TotalDue_Lead
	,LAG(TotalDue) OVER (ORDER BY SalesOrderNumber) AS TotalDue_Lag2
	,LEAD(TotalDue) OVER (ORDER BY SalesOrderNumber) AS TotalDue_Lead2
FROM Sales.SalesOrderHeader
WHERE OrderDate > '20110531'
ORDER BY OrderDate, SalesOrderNumber

SELECT  CustomerID, SalesOrderNumber, OrderDate, TotalDue
	,LAG(TotalDue, 2, 0) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber) AS TotalDue_Lag
	,LEAD(TotalDue, 1, 0) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber) AS TotalDue_Lead
FROM Sales.SalesOrderHeader
WHERE OrderDate > '20110531'
ORDER BY OrderDate, SalesOrderNumber


-- analityczne: FIRST_VALUE, LAST_VALUE
SELECT  CustomerID, SalesOrderNumber, OrderDate, TotalDue
	,FIRST_VALUE(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber) AS TotalDue_FirstValue
	,LAST_VALUE(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber) AS TotalDue_LastValue
FROM Sales.SalesOrderHeader
WHERE OrderDate > '20110531'
ORDER BY OrderDate, SalesOrderNumber


-- analityczne: FIRST_VALUE, LAST_VALUE
SELECT  CustomerID, SalesOrderNumber, OrderDate, TotalDue
	,LAST_VALUE(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber) AS TotalDue_LastValue
	,LAST_VALUE(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS TotalDue_LastValue
	,LAST_VALUE(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS TotalDue_LastValueCORRECT
FROM Sales.SalesOrderHeader
WHERE OrderDate > '20110531'
ORDER BY OrderDate, SalesOrderNumber



/*
	Demo 3 
	ROWS vs RANGE

*/


-- ROWS
SELECT CustomerID, SalesOrderNumber, OrderDate, TotalDue
	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber) AS TotalDueSum
	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS TotalDueSum_Rows

	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS TotalDueSum_RowsUnUn

	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber
		ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS TotalDueSum_Rows1Curr
	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber
		ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS TotalDueSum_Rows11
FROM Sales.SalesOrderHeader
WHERE OrderDate > '20110531'
ORDER BY OrderDate, SalesOrderNumber


-- RANGE : dopóki SalesOrderNumber jest unikalne - wynik bêdzie taki sam jak ROWS
SELECT CustomerID, SalesOrderNumber, OrderDate, TotalDue
	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber) AS TotalDueSum
	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS TotalDueSum_Rows
	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber
		RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS TotalDueSum_Range

	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS TotalDueSum_RowsUnUn
	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY SalesOrderNumber
		RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS TotalDueSum_RangeUnUn
FROM Sales.SalesOrderHeader
WHERE OrderDate > '20110531'
ORDER BY OrderDate, SalesOrderNumber



-- ROWS vs RANGE
-- W kolumnie TotalDue wystêpuj¹ duplikaty
SELECT CustomerID, SalesOrderNumber, OrderDate, TotalDue
	-- bierze pod uwagê wiersze poprzedzaj¹ce i bie¿acy
	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY  TotalDue
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS TotalDueSum_Rows
	-- bierze pod uwagê wiersze z mniejszym lub równym TotalDue
	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY  TotalDue
		RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS TotalDueSum_Range
	-- domyœlnie jest stosowany RANGE
	,SUM(TotalDue) OVER (PARTITION BY OrderDate ORDER BY  TotalDue) AS TotalDueSum_DEFAULT
FROM Sales.SalesOrderHeader
WHERE OrderDate > '20110531'
ORDER BY OrderDate, TotalDue 
GO



