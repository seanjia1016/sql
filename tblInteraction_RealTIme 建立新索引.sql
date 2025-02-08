DECLARE @sql NVARCHAR(MAX) = '';
DECLARE @indexName NVARCHAR(128);

-- 構建刪除索引的動態 SQL
DECLARE index_cursor CURSOR FOR
SELECT name
FROM sys.indexes
WHERE object_id = OBJECT_ID('tblInteraction_RealTime') AND type > 1;  -- 排除主鍵和唯一約束的索引

OPEN index_cursor;
FETCH NEXT FROM index_cursor INTO @indexName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- 動態生成刪除索引的 SQL 語句
    SET @sql = 'DROP INDEX [' + @indexName + '] ON tblInteraction_RealTime;';
    
    -- 執行刪除命令
    EXEC sp_executesql @sql;
    
    FETCH NEXT FROM index_cursor INTO @indexName;
END


CLOSE index_cursor;
DEALLOCATE index_cursor;

CREATE NONCLUSTERED INDEX IX_tblInteraction_RealTime_ContactID ON tblInteraction_RealTime (ContactID);
CREATE NONCLUSTERED INDEX IX_tblInteraction_RealTime_IxnID ON tblInteraction_RealTime (IxnID);
CREATE NONCLUSTERED INDEX IX_tblInteraction_RealTime_CallID ON tblInteraction_RealTime (CallID);
CREATE NONCLUSTERED INDEX IX_tblInteraction_RealTime_AgentID ON tblInteraction_RealTime (AgentID);
CREATE NONCLUSTERED INDEX IX_tblInteraction_RealTime_TenantID ON tblInteraction_RealTime (TenantID);
CREATE NONCLUSTERED INDEX IX_tblInteraction_RealTime_Status ON tblInteraction_RealTime (Status);
CREATE NONCLUSTERED INDEX IX_tblInteraction_RealTime_EndDate ON tblInteraction_RealTime (EndDate);


