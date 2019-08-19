/*

	CTE - Common Table Expressions
	Tomasz Lbera | MVP Data Platform
	tomasz.libera@datacommunity.pl
	http://www.kursysql.pl

*/




USE AdventureWorks2014
GO


-- stronnicowanie za pomoc� ROW_NUMBER
WITH Paging_CTE AS
(
	SELECT CustomerID, SalesOrderNumber, OrderDate, CurrencyRateID, TotalDue
		,ROW_NUMBER() OVER (ORDER BY OrderDate) AS RowNumber
	FROM Sales.SalesOrderHeader
)
SELECT * FROM Paging_CTE 
WHERE RowNumber >= 101 AND RowNumber <= 200



-- zapytanie wy�wietlaj�ce produkty
SELECT ProductSubcategoryID, ProductID, Name, Color, Size 
FROM Production.Product;

-- zapytanie z CTE zwracaj�ce ten sam wynik
-- ! poprzednia instrukcja musi by� zako�czona �rednikiem
--	 (podobnie jak MERGE)
WITH cte AS 
(
	SELECT ProductSubcategoryID, ProductID, Name, Color, Size 
	FROM Production.Product
)
SELECT * FROM cte



-- CTE, zapytanie wy�wietlaj�ce dodatkowo nazwy kategorii
-- ! wszystkie nazwy kolumn musz� by� unikalne (p.Name i ps.Name)
;WITH cte AS 
(
	SELECT ps.ProductSubcategoryID, ps.Name AS SubcategoryName, p.ProductID, p.Name, p.Color, p.Size
	FROM Production.Product AS p
	JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
)
SELECT * FROM cte

-- deklaracja kolumn w CTE
;WITH cte (SubcategoryID, SubcategoryName, ProductID, ProductName, Color, Size) AS 
(
	SELECT ps.ProductSubcategoryID, ps.Name, p.ProductID, p.Name, p.Color, p.Size
	FROM Production.Product AS p
	JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
)
SELECT * FROM cte



-- "zewn�trzne" zapytanie mo�e filtrowa�, sortowa� dane, ��czy� z innymi tabelami itd
;WITH cte AS 
(
	SELECT ps.ProductSubcategoryID, ps.Name AS SubcategoryName, p.ProductID, p.Name, p.Color, p.Size
	FROM Production.Product AS p
	JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
)
SELECT * 
FROM cte
WHERE Color IS NOT NULL
ORDER BY SubcategoryName, Name


-- poka� zam�wienia, kt�re nale�� do 3 najbardziej licznych podkategorii
SELECT DISTINCT soh.SalesOrderID, soh.OrderDate, soh.SubTotal, ps.Name AS SubcategoryName 
FROM Production.Product AS p
JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
JOIN Sales.SalesOrderDetail AS sod ON sod.ProductID = p.ProductID
JOIN Sales.SalesOrderHeader AS soh ON soh.SalesOrderID = sod.SalesOrderID
WHERE p.ProductSubcategoryID IN (
	SELECT TOP 3 ProductSubcategoryID 
	FROM Production.Product 
	WHERE ProductSubcategoryID IS NOT NULL
	GROUP BY ProductSubcategoryID
	ORDER BY COUNT(*) DESC
)
ORDER BY soh.OrderDate









-- CTE, poka� zam�wienia, kt�re nale�� do 3 najbardziej licznych podkategorii
;WITH cte AS 
(
	SELECT TOP 3 ProductSubcategoryID, COUNT(*) AS Cnt
	FROM Production.Product
	WHERE ProductSubcategoryID IS NOT NULL
	GROUP BY ProductSubcategoryID
	ORDER BY COUNT(*) DESC
)
SELECT DISTINCT soh.SalesOrderID, soh.OrderDate, soh.SubTotal, ps.Name AS SubcategoryName 
FROM cte
JOIN Production.Product AS p ON p.ProductSubcategoryID = cte.ProductSubcategoryID
JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
JOIN Sales.SalesOrderDetail AS sod ON sod.ProductID = p.ProductID
JOIN Sales.SalesOrderHeader AS soh ON soh.SalesOrderID = sod.SalesOrderID
ORDER BY soh.OrderDate



-- zan�wienia z najbardziej licznych podkategorii, 
-- wraz z liczb� zam�wie� kt�re z�o�yli przypisani do nich klienci
;WITH cte_products AS 
(
	SELECT TOP 3 ProductSubcategoryID, COUNT(*) AS Cnt
	FROM Production.Product
	WHERE ProductSubcategoryID IS NOT NULL
	GROUP BY ProductSubcategoryID
	ORDER BY COUNT(*) DESC
),
cte_orders AS
(
	SELECT DISTINCT 
		soh.SalesOrderID, soh.OrderDate, soh.SubTotal, ps.Name AS SubcategoryName, soh.CustomerID 
	FROM cte_products
	JOIN Production.Product AS p ON p.ProductSubcategoryID = cte_products.ProductSubcategoryID
	JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
	JOIN Sales.SalesOrderDetail AS sod ON sod.ProductID = p.ProductID
	JOIN Sales.SalesOrderHeader AS soh ON soh.SalesOrderID = sod.SalesOrderID
),
cte_customers (CustomerID, NumOfOrders) AS
(
	SELECT c.CustomerID, COUNT(*)
	FROM Sales.Customer AS c
	JOIN cte_orders ON cte_orders.CustomerID = c.CustomerID
	GROUP BY c.CustomerID
)
SELECT 
	SalesOrderID, OrderDate, SubTotal, SubcategoryName, cte_customers.CustomerID, NumOfOrders
FROM cte_orders
JOIN cte_customers ON cte_customers.CustomerID = cte_orders.CustomerID
ORDER BY OrderDate





-- zan�wienia z najbardziej licznych podkategorii, 
-- wraz z liczb� zam�wie� kt�re z�o�yli przypisani do nich klienci
-- ->>> INSERT 
;WITH cte_products AS 
(
	SELECT TOP 3 ProductSubcategoryID, COUNT(*) AS Cnt
	FROM Production.Product
	WHERE ProductSubcategoryID IS NOT NULL
	GROUP BY ProductSubcategoryID
	ORDER BY COUNT(*) DESC
),
cte_orders AS
(
	SELECT DISTINCT 
		soh.SalesOrderID, soh.OrderDate, soh.SubTotal, ps.Name AS SubcategoryName, soh.CustomerID 
	FROM cte_products
	JOIN Production.Product AS p ON p.ProductSubcategoryID = cte_products.ProductSubcategoryID
	JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
	JOIN Sales.SalesOrderDetail AS sod ON sod.ProductID = p.ProductID
	JOIN Sales.SalesOrderHeader AS soh ON soh.SalesOrderID = sod.SalesOrderID
),
cte_customers (CustomerID, NumOfOrders) AS
(
	SELECT c.CustomerID, COUNT(*)
	FROM Sales.Customer AS c
	JOIN cte_orders ON cte_orders.CustomerID = c.CustomerID
	GROUP BY c.CustomerID
)
SELECT 
	SalesOrderID, OrderDate, SubTotal, SubcategoryName, cte_customers.CustomerID, NumOfOrders
INTO #CteResult
FROM cte_orders
JOIN cte_customers ON cte_customers.CustomerID = cte_orders.CustomerID
ORDER BY OrderDate

SELECT * FROM #CteResult


/*	
	Rekurencja 
*/


SELECT * FROM HumanResources.Employee

-- Konwersja z typu hierarchyID na wersj� FK, self-reference: ManagerID
-- https://docs.microsoft.com/en-us/sql/relational-databases/tables/lesson-1-converting-a-table-to-a-hierarchical-structure

DROP TABLE IF EXISTS HumanResources.EmployeeOldSchool
GO

 SELECT emp.BusinessEntityID AS EmployeeID, emp.LoginID, 
  (SELECT  man.BusinessEntityID FROM HumanResources.Employee man 
	    WHERE emp.OrganizationNode.GetAncestor(1)=man.OrganizationNode OR 
		    (emp.OrganizationNode.GetAncestor(1) = 0x AND man.OrganizationNode IS NULL)) AS ManagerID,
       emp.JobTitle, emp.HireDate
INTO HumanResources.EmployeeOldSchool  
FROM HumanResources.Employee emp;
GO

SELECT * FROM HumanResources.EmployeeOldSchool

-- kierownictwo + podw�adni w AdventureWorks
SELECT manager.*, emp.EmployeeID, emp.LoginID 
FROM HumanResources.EmployeeOldSchool AS manager
LEFT JOIN HumanResources.EmployeeOldSchool AS emp ON emp.ManagerID = manager.EmployeeID
ORDER BY manager.ManagerID



;WITH cte_recursive AS
(
	-- tzw. kotwica - korze� relacji, 
	-- dyrektor zarz�dzaj�cy, nie maj�cy nad sob� �adnego prze�o�onego
	SELECT EmployeeID, LoginID, JobTitle, ManagerID, 0 AS OrgLevel 
	FROM HumanResources.EmployeeOldSchool
	WHERE ManagerID IS NULL

	UNION ALL -- uwaga!, uwaga! b�dzie rekurencja

	-- zapytanie rekursywne, powi�zane z poprzedni� iteracj�, a w pierwszym kroku z korzeniem
	SELECT emp.EmployeeID, emp.LoginID, emp.JobTitle, emp.ManagerID, OrgLevel+1 AS OrgLevel 
	FROM HumanResources.EmployeeOldSchool AS emp
	JOIN cte_recursive ON emp.ManagerID = cte_recursive.EmployeeID
)
SELECT * FROM cte_recursive



-- liczba kolumn musi si� zgadza�
;WITH cte_recursive AS
(
	SELECT EmployeeID, LoginID, JobTitle, ManagerID, 0 AS OrgLevel 
	FROM HumanResources.EmployeeOldSchool
	WHERE ManagerID IS NULL
	UNION ALL 
	SELECT emp.EmployeeID, emp.LoginID, emp.JobTitle, emp.ManagerID--, OrgLevel+1 AS OrgLevel 
	FROM HumanResources.EmployeeOldSchool AS emp
	JOIN cte_recursive ON emp.ManagerID = cte_recursive.EmployeeID
)
SELECT * FROM cte_recursive




-- podw�adni Laury z dzia�u finansowego
;WITH cte_recursive AS
(
	SELECT EmployeeID, LoginID, JobTitle, ManagerID, 0 AS OrgLevel 
	FROM HumanResources.EmployeeOldSchool
	WHERE LoginID='adventure-works\laura1'
	UNION ALL
	SELECT emp.EmployeeID, emp.LoginID, emp.JobTitle, emp.ManagerID, OrgLevel+1 AS OrgLevel 
	FROM HumanResources.EmployeeOldSchool AS emp
	JOIN cte_recursive ON emp.ManagerID = cte_recursive.EmployeeID
)
SELECT * FROM cte_recursive



-- prze�o�eni Davida2, technika z dzia�u produkcji
;WITH cte_recursive AS
(
	SELECT EmployeeID, LoginID, JobTitle, ManagerID
	FROM HumanResources.EmployeeOldSchool
	WHERE LoginID='adventure-works\david2'
	UNION ALL
	SELECT manager.EmployeeID, manager.LoginID, manager.JobTitle, manager.ManagerID
	FROM HumanResources.EmployeeOldSchool AS manager
	JOIN cte_recursive ON manager.EmployeeID = cte_recursive.ManagerID
)
SELECT * FROM cte_recursive


-- maksymalny poziom rekurencji: 32767 


;WITH cte_recursive AS
(
	SELECT EmployeeID, LoginID, JobTitle, ManagerID
	FROM HumanResources.EmployeeOldSchool
	WHERE LoginID='adventure-works\david2'
	UNION ALL
	SELECT manager.EmployeeID, manager.LoginID, manager.JobTitle, manager.ManagerID
	FROM HumanResources.EmployeeOldSchool AS manager
	JOIN cte_recursive ON manager.EmployeeID = cte_recursive.ManagerID
)
SELECT * FROM cte_recursive
OPTION (maxrecursion 2)


-- je�li nie potrzenuejmy b��du
BEGIN TRY 
	;WITH cte_recursive AS
	(
		SELECT EmployeeID, LoginID, JobTitle, ManagerID
		FROM HumanResources.EmployeeOldSchool
		WHERE LoginID='adventure-works\david2'
		UNION ALL
		SELECT manager.EmployeeID, manager.LoginID, manager.JobTitle, manager.ManagerID
		FROM HumanResources.EmployeeOldSchool AS manager
		JOIN cte_recursive ON manager.EmployeeID = cte_recursive.ManagerID
	)
	SELECT * FROM cte_recursive
	OPTION (maxrecursion 2)
END TRY
BEGIN CATCH
END CATCH


-- materia�y: 
-- http://www.kursysql.pl