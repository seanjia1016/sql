SET NOCOUNT ON;

BEGIN
    DECLARE @lastSixMonth DATE = DATEADD(MONTH, -6, GETDATE());
    DECLARE @tableName NVARCHAR(MAX) = N'tblInteraction_' + FORMAT(@lastSixMonth, 'yyyyMM');
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @rowsInserted INT = 0;
    DECLARE @rowsDeleted INT = 0;
    DECLARE @result NVARCHAR(50) = 'Success';
    DECLARE @errorMessage NVARCHAR(MAX) = NULL;
    DECLARE @errorLine INT = 0; 

    -- 這裡是用來存儲操作結果的臨時表
    CREATE TABLE #TempOutputLog (
        Operation NVARCHAR(50),
        RecordID INT
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 查詢表是否存在
        IF EXISTS (SELECT 1 
                   FROM INFORMATION_SCHEMA.TABLES  WITH(NOLOCK)
                   WHERE TABLE_NAME = @tableName 
                   AND TABLE_SCHEMA = 'dbo')
        --此表tblInteraction_yyyyMM已存在
        BEGIN 
            -- 開啟 IDENTITY_INSERT
            SET @sql = N'
            SET IDENTITY_INSERT ' + QUOTENAME(@tableName) + N' ON;

            -- 使用 OUTPUT 記錄 INSERT 操作
            MERGE INTO ' + QUOTENAME(@tableName) + N' AS Target
            USING (
                SELECT *
                FROM tblInteraction WITH(NOLOCK)
                WHERE CONVERT(CHAR(6), StartDate, 112) = CONVERT(CHAR(6), @lastSixMonth, 112)
            ) AS Source
            ON Target.DBID = Source.DBID -- 匹配條件
            WHEN NOT MATCHED THEN
                -- 如果子表中有父表沒有插入過的記錄，加入新數據
                INSERT (DBID, AgentID, Status_DBID, Reason_DBID, StartDate, callID, entityTypeID, stopReason, TenantID, StatID, Duration, EndDatetime, ScheduledCalcDatetime, ScheduledValidationResult)
                VALUES (Source.DBID, Source.AgentID, Source.Status_DBID, Source.Reason_DBID, Source.StartDate, Source.callID, Source.entityTypeID, Source.stopReason, Source.TenantID, Source.StatID, Source.Duration, Source.EndDatetime, Source.ScheduledCalcDatetime, Source.ScheduledValidationResult);
				SELECT ''插入新數據至已經存在的子表'' AS Operation, @@ROWCOUNT AS RecordID INTO #TempOutputLog;  -- 捕獲 INSERT 操作
            ';

            -- 執行動態 SQL 插入操作
            EXEC sp_executesql @sql, N'@lastSixMonth DATE', @lastSixMonth;

            -- 使用 OUTPUT 記錄 DELETE 操作
            SET @sql = N'
            DELETE FROM tblInteraction
            WHERE CONVERT(CHAR(6), StartDate, 112) = CONVERT(CHAR(6), @lastSixMonth, 112)
            SELECT ''從父表刪除'' AS Operation, @@ROWCOUNT AS RecordID INTO #TempOutputLog;  -- 捕獲 DELETE 操作
            ';

            -- 執行動態 SQL 刪除操作
            EXEC sp_executesql @sql, N'@lastSixMonth DATE', @lastSixMonth;

            -- 記錄操作結果，將 OUTPUT 結果插入日誌表
            INSERT INTO dbo.OperationLog (TableName, Action, RowsInserted, Result)
            SELECT @tableName, Operation, RecordID, @result FROM #TempOutputLog
        

        END
        ELSE
        --此表tblInteraction_yyyyMM不存在
        BEGIN
            -- 創建表的 SQL（先創建表，再插入資料）
            SET @sql = N'SELECT * INTO ' + QUOTENAME(@tableName) + ' FROM tblInteraction WITH(NOLOCK) WHERE CONVERT(CHAR(6), StartDate, 112) = ' + CONVERT(CHAR(6), @lastSixMonth, 112);
            
            -- 執行創建表並插入資料
            EXEC sp_executesql @sql;

            -- 記錄插入行數
            SELECT @rowsInserted =  COUNT(*) 
            FROM tblInteraction 
            WHERE CONVERT(CHAR(6), StartDate, 112) = CONVERT(CHAR(6), @lastSixMonth, 112);

            -- 記錄操作結果到日誌表
            INSERT INTO dbo.OperationLog (TableName, Action, RowsInserted,  Result)
            VALUES (@tableName, '移動數據至新創建的子表', @rowsInserted, @result);

            -- 將該年月從父表刪除
            DELETE tblInteraction 
            WHERE CONVERT(CHAR(6), StartDate, 112) = CONVERT(CHAR(6), @lastSixMonth, 112);
            
            -- 記錄刪除的行數
            SET @rowsDeleted = @@ROWCOUNT;  -- 記錄刪除的行數

            -- 記錄操作結果到日誌表
            INSERT INTO dbo.OperationLog (TableName, Action, RowsDeleted, Result)
            VALUES (@tableName, '從父表刪除數據', @rowsDeleted, @result);

            COMMIT TRANSACTION;

        END;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        -- 捕獲錯誤
        SET @result = 'Fail';
        SET @errorMessage = ERROR_MESSAGE();
        SET @errorLine = ERROR_LINE();

        -- 記錄錯誤到日誌表
        INSERT INTO dbo.OperationLog (TableName, Action, RowsInserted, RowsDeleted, Result, ErrorMessage)
        VALUES (@tableName, '錯誤紀錄', @rowsInserted, @rowsDeleted, @result, '第'+CONVERT(VARCHAR, @errorLine)+'行錯誤 '+ @errorMessage);
    END CATCH;

    -- 清理臨時表
    DROP TABLE #TempOutputLog;

END;

SET NOCOUNT OFF;
