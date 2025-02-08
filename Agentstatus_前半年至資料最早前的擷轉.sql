SET NOCOUNT ON;

DECLARE @minTime DATETIME;
DECLARE @maxTime DATETIME;

-- 取得tblInteraction 最小開始年月
SELECT 
    @minTime = MIN(StartDate)
FROM 
    tblInteraction WITH(NOLOCK);

-- 取得tblInteraction 系統日前半年之年月
SELECT 
   @maxTime =DATEADD(m,-6,MAX(StartDate))
FROM 
    tblInteraction WITH(NOLOCK);

--執行複製表以及資料
WHILE @minTime <= @maxTime
BEGIN

    DECLARE @tableName NVARCHAR(MAX) = N'tblInteraction_' + FORMAT(@minTime, 'yyyyMM');


    DECLARE @sql NVARCHAR(MAX) = 'SELECT * INTO ' + QUOTENAME(@tableName) + ' FROM tblInteraction WITH(NOLOCK) WHERE CONVERT(CHAR(6), StartDate, 112) = '+ CONVERT(CHAR(6), @minTime, 112) ;
    EXEC sp_executesql @sql;

    SET @minTime = DATEADD(MONTH, 1, @minTime);
END;

--刪除小於系統日前半年之年月以前的資料(只留半年資料)
	DELETE tblInteraction  WHERE CONVERT(CHAR(6), StartDate, 112) <= CONVERT(CHAR(6), @maxTime, 112) 

