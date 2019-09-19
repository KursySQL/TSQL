/*

	Funkcja STRING_AGG - SQL Server 2017 
	Tomasz Lbera | MVP Data Platform
	libera@kursysql.pl
	http://www.kursysql.pl

*/

USE AdventureWorks2014
GO




SELECT * FROM Production.Product



SELECT STRING_AGG(Name, ',') AS ProductList
FROM Production.Product
WHERE ProductID < 500



--! Dla wszystkich 19K produkt�w si� nie uda - domy�lnie nvarchar(4000)
SELECT STRING_AGG (Name, ',') AS ProductList 
FROM Production.Product
/*
	Msg 9829, Level 16, State 1, Line 18
	STRING_AGG aggregation result exceeded the limit of 8000 bytes. Use LOB types to avoid result truncation.
*/

-- sugerowane w b��dzie rozwi�zanie:
-- - cast pierwszego parametru na varchar(max) 
SELECT STRING_AGG (CAST(Name AS varchar(max)), ',') AS ProductList 
FROM Production.Product

-- > https://docs.microsoft.com/en-us/sql/t-sql/functions/string-agg-transact-sql?view=sql-server-2017
-- > Return Types --


-- mo�liwos� wygenerowania listy oddzielanej znakami przej�cia do nowego wiersza
-- (SSMS: Results to Text)
SELECT STRING_AGG (Name, CHAR(13)) AS csv 
FROM Production.Product
WHERE ProductID < 500


-- wi�cej ni� jedna kolumna - wcze�niejsze po��czenie kolumn w jedn�
SELECT STRING_AGG(CONCAT(Name, ' (', ProductNumber, ', ', Color, ')'), ',') AS ProductList 
FROM Production.Product
WHERE ProductID < 500 AND Color IS NOT NULL


-- warto�ci nieokre�lone -> pusty string
SELECT STRING_AGG(CONCAT(Name, ' (', ProductNumber, ', ', Color, ')'), ',') AS ProductList 
FROM Production.Product
WHERE ProductID < 200 AND Color IS NULL


-- skoro to funkcja agreguj�ca - mo�e by tak u�y� GROUP BY?
SELECT ProductSubcategoryID, STRING_AGG (CAST(Name AS varchar(max)), ',') AS ProductList
FROM Production.Product
GROUP BY ProductSubcategoryID


-- nieposortowane kierownice
SELECT STRING_AGG (CAST(Name AS varchar(max)), ' __ ') AS ProductList
FROM Production.Product
WHERE ProductSubcategoryID = 4


-- sorted!
SELECT STRING_AGG (CAST(Name AS varchar(max)), ' __ ') WITHIN GROUP(ORDER BY Name) AS ProductList
FROM Production.Product
WHERE ProductSubcategoryID = 4






/*
	Por�wnanie wydajno�ci
*/

SET STATISTICS IO ON

-- OLD-School - STAFF() + FOR XML PATH
SELECT ProductSubcategoryID, 
	(SELECT STUFF((SELECT ', ' + Name FROM Production.Product
	WHERE ProductSubcategoryID=p.ProductSubcategoryID ORDER BY Name FOR XML PATH('')), 1, 1, '')) ProductList
FROM Production.Product AS p
GROUP BY ProductSubcategoryID


SELECT ProductSubcategoryID, STRING_AGG (CAST(Name AS varchar(max)), ',') AS ProductList
FROM Production.Product
GROUP BY ProductSubcategoryID




/*
	feedback.azure.com
	
	Support DISTINCT for STRING_AGG

	Currently STRING_AGG aggregates all strings passed as an input. 
	It would be very useful to support DISTINCT, 
	so it would concatenate unique strings only.

	
https://feedback.azure.com/forums/908035-sql-server/suggestions/35243533-support-distinct-for-string-agg

*/

