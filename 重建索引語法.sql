Declare @IndexName varchar(100)
Declare @objectId varchar(100)
Declare @TableName varchar(100)
Declare @SchemaName varchar(100)
Declare @ExecutionSyntax varchar(500)
Declare @ExecutionType varchar(100)
Declare @AvgFragmentation varchar(100)
Declare @FillFactor int

-- 設定 Fill Factor
Set @FillFactor = 80  

DECLARE index_cursor CURSOR FOR
   SELECT
       'ALTER INDEX [' + ix.name + '] ON [' + s.name + '].[' + t.name + '] ' +
       CASE
          WHEN ps.avg_fragmentation_in_percent > 15 THEN
              'REBUILD WITH (FILLFACTOR = ' + CAST(@FillFactor AS varchar(3)) + ')'  -- 重建並設置 Fill Factor
          ELSE
              'REORGANIZE'  -- 重組不支持 Fill Factor 設定
       END +
       CASE
          WHEN pc.partition_count > 1 THEN
              ' PARTITION = ' + CAST(ps.partition_number AS nvarchar(MAX))
          ELSE ''
       END as ExecutionSyntax,
       ps.avg_fragmentation_in_percent,
       CASE
          WHEN ps.avg_fragmentation_in_percent > 15 THEN 'REBUILD'
          ELSE 'REORGANIZE'
       END as ExecutionType,
       ix.object_id as objectId,
       ix.name as IndexName,
       t.name as TableName,
       s.name as SchemaName
   FROM sys.indexes AS ix
       INNER JOIN sys.tables t ON t.object_id = ix.object_id
       INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
       INNER JOIN
           (SELECT object_id, index_id, avg_fragmentation_in_percent, partition_number
            FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL)) ps
           ON t.object_id = ps.object_id AND ix.index_id = ps.index_id
       INNER JOIN
           (SELECT object_id, index_id, COUNT(DISTINCT partition_number) AS partition_count
            FROM sys.partitions
            GROUP BY object_id, index_id) pc
           ON t.object_id = pc.object_id AND ix.index_id = pc.index_id
   WHERE ps.avg_fragmentation_in_percent > 10
      AND ix.name IS NOT NULL

OPEN index_cursor
FETCH NEXT FROM index_cursor INTO @ExecutionSyntax, @AvgFragmentation, @ExecutionType, @objectId, @IndexName, @TableName, @SchemaName
WHILE @@FETCH_STATUS = 0
    BEGIN
        -- 重整資訊
        PRINT '-- TableName: ' + @TableName + ' , IndexName: ' + @IndexName + ' , SchemaName: ' + @SchemaName + ' , AvgFragmentationInPercent: ' + @AvgFragmentation + ' , ExecutionType: ' + @ExecutionType
        PRINT '   ExecutionSyntax: ' + @ExecutionSyntax
        EXEC(@ExecutionSyntax)
        FETCH NEXT FROM index_cursor INTO @ExecutionSyntax, @AvgFragmentation, @ExecutionType, @objectId, @IndexName, @TableName, @SchemaName
    END

CLOSE index_cursor
DEALLOCATE index_cursor