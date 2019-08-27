/*

	Klauzula OUTPUT w SQL Server
	Tomasz Lbera | MVP Data Platform
	tomasz.libera@datacommunity.pl
	http://www.kursysql.pl

*/















USE AdventureWorks2014
GO




/*

	INSERT 

*/

SELECT * FROM Production.ProductCategory

SELECT * FROM Production.ProductSubcategory WHERE ProductCategoryID = 1




-- wstawienie nowego wiersza
INSERT INTO Production.ProductSubcategory (ProductCategoryID, Name, rowguid, ModifiedDate)
VALUES (1, 'E-Bikes', NEWID(), GETDATE())

-- sprawdzenie wartości IDENTITY
SELECT SCOPE_IDENTITY() AS ProductSubcategoryID

-- skasowanie wprowadzonego wiersza i cofnięcie IDENTITY
DELETE FROM Production.ProductSubcategory WHERE ProductSubcategoryID > 37
DBCC CHECKIDENT('Production.ProductSubcategory', RESEED, 37)


-- wstawienie nowego wiersza z wyświetleniem wartości kolumn - wraz z IDENTITY
INSERT INTO Production.ProductSubcategory (ProductCategoryID, Name, rowguid, ModifiedDate)
OUTPUT inserted.*
VALUES (1, 'E-Bikes', NEWID(), GETDATE())



-- wstawienie jednocześnie 3 rekordów
INSERT INTO Production.ProductSubcategory (ProductCategoryID, Name, rowguid, ModifiedDate)
OUTPUT inserted.*
VALUES (1, 'E-Bikes', NEWID(), GETDATE()), 
	(1, 'Triathlon', NEWID(), GETDATE()), 
	(1, 'Gravel', NEWID(), GETDATE())


-- skasowanie wprowadzonych wierszy i cofnięcie IDENTITY
DELETE FROM Production.ProductSubcategory WHERE ProductSubcategoryID > 37
DBCC CHECKIDENT('Production.ProductSubcategory', RESEED, 37)



-- wstawienie jednocześnie 3 rekordów ale tylko jednej kolumny
INSERT INTO Production.ProductSubcategory (ProductCategoryID, Name, rowguid, ModifiedDate)
OUTPUT inserted.ProductSubcategoryID
VALUES (1, 'E-Bikes', NEWID(), GETDATE()), 
	(1, 'Triathlon', NEWID(), GETDATE()), 
	(1, 'Gravel', NEWID(), GETDATE())




-- skasowanie wprowadzonych wierszy i cofnięcie IDENTITY
DELETE FROM Production.ProductSubcategory WHERE ProductSubcategoryID > 37
DBCC CHECKIDENT('Production.ProductSubcategory', RESEED, 37)




-- wstawienie jednocześnie 3 rekordów ale tylko jednej kolumny
INSERT INTO Production.ProductSubcategory (ProductCategoryID, Name, rowguid, ModifiedDate)
OUTPUT inserted.ProductSubcategoryID, inserted.Name
VALUES (1, 'E-Bikes', NEWID(), GETDATE()), 
	(1, 'Triathlon', NEWID(), GETDATE()), 
	(1, 'Gravel', NEWID(), GETDATE())



-- skasowanie wprowadzonych wierszy i cofnięcie IDENTITY
DELETE FROM Production.ProductSubcategory WHERE ProductSubcategoryID > 37
DBCC CHECKIDENT('Production.ProductSubcategory', RESEED, 37)




CREATE TABLE #CreatedSubcategories (
ProductSubcategoryID int, 
Name nvarchar(50))



-- zapisanie wyniku OUTPUT do tabeli tymczasowej
INSERT INTO Production.ProductSubcategory (ProductCategoryID, Name, rowguid, ModifiedDate)
OUTPUT inserted.ProductSubcategoryID, inserted.Name
INTO #CreatedSubcategories
VALUES (1, 'E-Bikes', NEWID(), GETDATE()), 
	(1, 'Triathlon', NEWID(), GETDATE()), 
	(1, 'Gravel', NEWID(), GETDATE())


SELECT * FROM #CreatedSubcategories


-- skasowanie wprowadzonych wierszy i cofnięcie IDENTITY
DELETE FROM Production.ProductSubcategory WHERE ProductSubcategoryID > 37
DBCC CHECKIDENT('Production.ProductSubcategory', RESEED, 37)


DROP TABLE #CreatedSubcategories


/*

	DELETE

*/


CREATE TABLE #SubcategoriesAudit (
id int identity,
ProductSubcategoryID int, 
ProductCategoryID int,
Name nvarchar(50),
rowguid uniqueidentifier,
ModifiedDate datetime,
DeletedDate datetime)


-- wstawiamy 3 wiersze, które będziemy chcieli zaraz skasować
INSERT INTO Production.ProductSubcategory (ProductCategoryID, Name, rowguid, ModifiedDate)
VALUES (1, 'E-Bikes', NEWID(), GETDATE()), 
	(1, 'Triathlon', NEWID(), GETDATE()), 
	(1, 'Gravel', NEWID(), GETDATE())



-- kasujemy wiersze, zapisując je w tabeli audytu
DELETE FROM Production.ProductSubcategory
OUTPUT deleted.*, GETDATE()
INTO #SubcategoriesAudit
WHERE ProductSubcategoryID > 37


SELECT * FROM #SubcategoriesAudit



/*

	UPDATE

*/

SELECT * FROM Production.ProductSubcategory WHERE ProductCategoryID = 1

-- wyświetlenie poprzedniej i nowej wartości
UPDATE Production.ProductSubcategory SET Name = 'Cross Country' 
OUTPUT deleted.Name AS OldName, inserted.Name AS NewName
WHERE Name = 'Mountain Bikes'

UPDATE Production.ProductSubcategory SET Name = 'Mountain Bikes' 
WHERE Name = 'Cross Country' 


-- zapisanie poprzedniej wersji do tabeli audytu
UPDATE Production.ProductSubcategory SET Name = 'Cross Country' 
OUTPUT deleted.*, GETDATE()
INTO #SubcategoriesAudit
WHERE Name = 'Mountain Bikes'


SELECT * FROM #SubcategoriesAudit



/*
	skrypt: www.kursysql.pl


*/
