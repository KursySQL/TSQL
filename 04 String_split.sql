/*

	Funkcja STRING_SPLUT - SQL Server 2016 
	Tomasz Lbera | MVP Data Platform
	libera@kursysql.pl
	http://www.kursysql.pl

*/



SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID()
GO

-- pamiętamy o trybie zgodności
ALTER DATABASE AdventureWorks2014 SET COMPATIBILITY_LEVEL = 130
GO

/*
	Składnia:
	STRING_SPLIT ( string , separator )  
*/

SELECT * FROM STRING_SPLIT('Chisel Epic Epic EVO Epic FSR Epic Hardtail Riprock', ' ')
GO


-- spacje
DECLARE @tosplit NVARCHAR(400) = 'Chisel Epic Riprock'  
  
SELECT value  
FROM STRING_SPLIT(@tosplit, ' ')  
GO

-- przecinki
DECLARE @tosplit NVARCHAR(400) = 'Chisel,Epic,Epic EVO,,Epic FSR,Epic Hardtail,Riprock'  
  
SELECT value  
FROM STRING_SPLIT(@tosplit, ',')  
WHERE value <> '';


/*

	Co można, a co nie można

*/


-- szukamy w pustym łańcuchu
SELECT value FROM STRING_SPLIT('', ',')
SELECT value FROM STRING_SPLIT(NULL, ',')
GO

-- !szukamy pustego separatora...
SELECT value FROM STRING_SPLIT('Chisel,Epic,Riprock', '')
SELECT value FROM STRING_SPLIT('Chisel,Epic,Riprock', NULL)
GO

-- separatorem może być tylko jeden znak
SELECT value FROM STRING_SPLIT('Chisel*@Epic*@Riprock', '*@')
GO

-- chyba, że identyczne dwa znaki...
SELECT value FROM STRING_SPLIT('Chisel**Epic**Riprock', '*')

SELECT value FROM STRING_SPLIT('Chisel**Epic**Riprock', '*')
WHERE value <> ''
GO



/*

	Old-school
	funkcja dla wersji <2016

*/


CREATE OR ALTER FUNCTION dbo.udfSplit (@string nvarchar(max), @separator char(1)) 
RETURNS @result TABLE(val nvarchar(max)) 
BEGIN 
    DECLARE @i int, @separator_index int

	-- w pierwszej iteracji sprawdzamy 
	-- miejsce pierwszego wystąpienia separatora
    SELECT @i = 1, @separator_index = CHARINDEX(@separator, @string) 

    WHILE @i < LEN(@string) + 1 
	BEGIN 
		-- jeśli nie ma kolejnego separatora - zwracamy wszystko do końca
        IF @separator_index = 0  
            SET @separator_index = LEN(@string) + 1       

		INSERT INTO @result (val) VALUES(SUBSTRING(@string, @i, @separator_index - @i)) 

		-- od którego miejsca będziemy szukać kolejnego przecinka
        SET @i = @separator_index + 1 

		-- sprawdzamy miejsce wystąpienia kolejnego separatora
        SET @separator_index = CHARINDEX(@separator, @string, @i)        
    END 
    RETURN 
END


SELECT val FROM dbo.udfSplit('Chisel Epic Riprock', ' ')




/*

	STRING_SPLIT i CROSS JOIN

*/

DROP TABLE IF EXISTS #Bikes

CREATE TABLE #Bikes (ID int identity, Category varchar(20), ProductFamily varchar(100))
INSERT INTO #Bikes (Category, ProductFamily) VALUES
	('Cross Country', 'Chisel,Epic,Epic EVO,Epic FSR,Epic Hardtail'),
	('Trail', 'E-Bike,Mountain'),
	('Road', 'Roubaix,Tarmac,Venge'),
	('Kids', 'Riprock,Hotrock')


SELECT * FROM #Bikes

SELECT ID, Category, value  
FROM #Bikes  
    CROSS APPLY STRING_SPLIT(ProductFamily, ',');  


/*
	feedback.azure.com

STRING_SPLIT is not feature complete
The new string splitter function in SQL Server 2016 
is a good addition but it needs an extra column, 
a ListOrder column which denotes the order of the splitted values.
*/
https://feedback.azure.com/forums/908035-sql-server/suggestions/32902852-string-split-is-not-feature-complete
