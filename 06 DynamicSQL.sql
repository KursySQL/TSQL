/*

	TSQL: Dynamic SQL 
	Tomasz Lbera | MVP Data Platform
	libera@kursysql.pl
	http://www.kursysql.pl

*/

USE AdventureWorks2019
GO



SELECT ProductID, Name, Color, ListPrice FROM Production.Product WHERE Color = 'Black' AND ListPrice > 100



/*
	EXEC 
*/

DECLARE @Sql nvarchar(max)
DECLARE @Color nvarchar(15)
DECLARE @ListPrice money -- !!!!

SET @Color = 'Black'
SET @ListPrice = 100
 


SET @Sql = 'SELECT ProductID, Name, Color, ListPrice  FROM Production.Product WHERE Color = '''+@Color+''' AND ListPrice > '+ CAST(@ListPrice AS varchar(10))
PRINT @Sql

EXEC (@Sql)
GO





/*
	sp_executesql

	tworzy "nienazwaną procedurę" (jeden plan w cache)
	przyjmuje dwa parametry: 
	- @stmt (zawiera wsad do wykonania)
	- @params - opcjonalny - parametry przekazane do wsadu

	bardziej czytelny, uporządkowany kod

*/



-- dwa parametry
SELECT * FROM Production.Product WHERE Color = 'Black' AND ListPrice > 100
GO


DECLARE @Sql nvarchar(max)
DECLARE @Params nvarchar(1000)

SET @Sql = 'SELECT * FROM Production.Product WHERE Color = @Color AND ListPrice > @ListPrice'
PRINT @Sql

SET @Params = '@Color nvarchar(15) = ''Black'',
			@ListPrice money = 100'

EXEC sp_executesql @Sql, @Params
GO


-- bez domyślnych wartości parametrów
DECLARE @Sql nvarchar(max)
DECLARE @Params nvarchar(1000)
DECLARE @PColor nvarchar(15) = 'Black'
DECLARE @PListPrice money = 100


SET @Sql = 'SELECT * FROM Production.Product WHERE Color = @Color AND ListPrice > @ListPrice'
PRINT @Sql

SET @Params = '@Color nvarchar(15), @ListPrice money'

EXEC sp_executesql @Sql, @Params, @Color = @PColor, @ListPrice = @PListPrice
GO


-- inny sposób wywołania
DECLARE @Params nvarchar(1000)
DECLARE @PColor nvarchar(15) = 'Black'
DECLARE @PListPrice money = 100

SET @Params = '@Color nvarchar(15), @ListPrice money'

EXEC sp_executesql N'SELECT * FROM Production.Product WHERE Color = @Color AND ListPrice > @ListPrice', @Params, @Color = @PColor, @ListPrice = @PListPrice
GO

-- inny sposób wywołania #2
DECLARE @Sql nvarchar(max)
DECLARE @Params nvarchar(1000)

SET @Sql = 'SELECT * FROM Production.Product WHERE Color = @Color AND ListPrice > @ListPrice'
PRINT @Sql

SET @Params = '@Color nvarchar(15),	@ListPrice money'

EXEC sp_executesql @Sql, @Params, @Color = 'Black', @ListPrice = 100
GO




/*
	Dynamiczne sortowanie
*/


SELECT * FROM Production.Product 
GO


SELECT * FROM Production.Product ORDER BY Name

SELECT * FROM Production.Product ORDER BY Color

SELECT * FROM Production.Product ORDER BY Size

SELECT * FROM Production.Product ORDER BY ListPrice

SELECT * FROM Production.Product ORDER BY ListPrice DESC
GO


DECLARE @SortColumn sysname = 'Size'


SELECT ProductID, Name, Color, Size, ListPrice  
FROM Production.Product 
ORDER BY CASE @SortColumn 
		WHEN 'Name' THEN Name
		WHEN 'Color' THEN Color
		WHEN 'Size' THEN Size
		WHEN 'ListPrice' THEN CAST(ListPrice AS varchar(10))
		WHEN 'ProductID' THEN CAST(ProductID AS varchar(10)) END 
GO


-- porządek sortowania
DECLARE @SortColumn sysname
DECLARE @IsDesc bit

SET @SortColumn = 'Name'
SET @IsDesc = 1


SELECT ProductID, Name, Color, Size, ListPrice 
FROM Production.Product 
ORDER BY 
	CASE WHEN @SortColumn='Name' AND @IsDesc=1 THEN Name END DESC,
	CASE WHEN @SortColumn='Name' AND @IsDesc=0 THEN Name END,
	CASE WHEN @SortColumn='Color' AND @IsDesc=1 THEN Color END DESC,
	CASE WHEN @SortColumn='Color' AND @IsDesc=0 THEN Color END ASC,
	CASE WHEN @SortColumn='Size' AND @IsDesc=1 THEN Size END DESC,
	CASE WHEN @SortColumn='Size' AND @IsDesc=0 THEN Size END,
	CASE WHEN @SortColumn='ListPrice' AND @IsDesc=1 THEN ListPrice END DESC,
	CASE WHEN @SortColumn='ListPrice' AND @IsDesc=0 THEN ListPrice END
OPTION (RECOMPILE)
GO		




-- dynamic sql EXEC

DECLARE @Sql nvarchar(max)
DECLARE @SortColumn sysname
DECLARE @IsDesc bit

SET @SortColumn = 'Name'
SET @IsDesc = 1

SET @Sql = 'SELECT ProductID, Name, Color, Size, ListPrice FROM Production.Product'

IF @SortColumn IN ('Name', 'Color', 'Size', 'ListPrice')
  SET @Sql = @Sql + ' ORDER BY ' + @SortColumn + IIF(@IsDesc=1, ' DESC', ' ASC')


PRINT @Sql
EXEC (@sql)
GO


-- dynamic sql sp_executesql

DECLARE @Sql nvarchar(max)
DECLARE @SortColumn sysname
DECLARE @IsDesc bit

SET @SortColumn = 'Name'
SET @IsDesc = 1

SET @Sql = 'SELECT ProductID, Name, Color, Size, ListPrice FROM Production.Product'

IF @SortColumn IN ('Name', 'Color', 'Size', 'ListPrice')
  SET @Sql = @Sql + ' ORDER BY ' + @SortColumn + IIF(@IsDesc=1, ' DESC', ' ASC')

SET @Sql = @Sql + ' OPTION(RECOMPILE)'

PRINT @Sql
EXEC sp_executesql @Sql





/*
	Dynamiczne filtrowanie
*/

USE AdventureWorks2019
GO

SELECT * FROM Production.Product WHERE Color = 'Black'

SELECT * FROM Production.Product WHERE Size = 'L'

SELECT * FROM Production.Product WHERE ListPrice > 100

SELECT * FROM Production.Product WHERE ProductID = 710
GO



SELECT * FROM Production.Product WHERE Color = 'Black' AND Size = 'L'
GO





DECLARE @Color nvarchar(15)
DECLARE @Size nvarchar(5)
DECLARE @ListPrice money
DECLARE @ProductID int
DECLARE @Sql nvarchar(max)
DECLARE @Params nvarchar(1000)

SET @Color = 'Black'
SET @Size = 'L'


SET @Sql = 
'SELECT ProductID, Name, Color, Size, ListPrice 
FROM Production.Product
WHERE 1=1' + char(13) + char(10) 

IF @Color IS NOT NULL
  SELECT @Sql = @Sql + ' AND Color = @Color' + char(13) + char(10) 

IF @Size IS NOT NULL
  SELECT @Sql = @Sql + ' AND Size = @Size' + char(13) + char(10) 
	
IF @ListPrice IS NOT NULL
  SELECT @Sql = @Sql + ' AND ListPrice = @ListPrice' + char(13) + char(10) 

IF @ProductID IS NOT NULL
  SELECT @Sql = @Sql + ' AND ProductID = @ProductID' + char(13) + char(10) 

SET @Sql = @Sql + 'OPTION(RECOMPILE)'
	
PRINT @Sql


SELECT @params = '@Color nvarchar(15), @Size nvarchar(5), @ListPrice money, @ProductID int'

EXEC sp_executesql @Sql, @Params, @Color, @Size, @ListPrice, @ProductID
GO
