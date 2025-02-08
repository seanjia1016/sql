SET NOCOUNT ON;

DECLARE @minTime DATETIME;
DECLARE @maxTime DATETIME;

-- ���otblInteraction �̤p�}�l�~��
SELECT 
    @minTime = MIN(StartDate)
FROM 
    tblInteraction WITH(NOLOCK);

-- ���otblInteraction �t�Τ�e�b�~���~��
SELECT 
   @maxTime =DATEADD(m,-6,MAX(StartDate))
FROM 
    tblInteraction WITH(NOLOCK);

--����ƻs��H�θ��
WHILE @minTime <= @maxTime
BEGIN

    DECLARE @tableName NVARCHAR(MAX) = N'tblInteraction_' + FORMAT(@minTime, 'yyyyMM');


    DECLARE @sql NVARCHAR(MAX) = 'SELECT * INTO ' + QUOTENAME(@tableName) + ' FROM tblInteraction WITH(NOLOCK) WHERE CONVERT(CHAR(6), StartDate, 112) = '+ CONVERT(CHAR(6), @minTime, 112) ;
    EXEC sp_executesql @sql;

    SET @minTime = DATEADD(MONTH, 1, @minTime);
END;

--�R���p��t�Τ�e�b�~���~��H�e�����(�u�d�b�~���)
	DELETE tblInteraction  WHERE CONVERT(CHAR(6), StartDate, 112) <= CONVERT(CHAR(6), @maxTime, 112) 

