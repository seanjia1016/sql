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

    -- �o�̬O�ΨӦs�x�ާ@���G���{�ɪ�
    CREATE TABLE #TempOutputLog (
        Operation NVARCHAR(50),
        RecordID INT
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        -- �d�ߪ�O�_�s�b
        IF EXISTS (SELECT 1 
                   FROM INFORMATION_SCHEMA.TABLES  WITH(NOLOCK)
                   WHERE TABLE_NAME = @tableName 
                   AND TABLE_SCHEMA = 'dbo')
        --����tblInteraction_yyyyMM�w�s�b
        BEGIN 
            -- �}�� IDENTITY_INSERT
            SET @sql = N'
            SET IDENTITY_INSERT ' + QUOTENAME(@tableName) + N' ON;

            -- �ϥ� OUTPUT �O�� INSERT �ާ@
            MERGE INTO ' + QUOTENAME(@tableName) + N' AS Target
            USING (
                SELECT *
                FROM tblInteraction WITH(NOLOCK)
                WHERE CONVERT(CHAR(6), StartDate, 112) = CONVERT(CHAR(6), @lastSixMonth, 112)
            ) AS Source
            ON Target.DBID = Source.DBID -- �ǰt����
            WHEN NOT MATCHED THEN
                -- �p�G�l��������S�����J�L���O���A�[�J�s�ƾ�
                INSERT (DBID, AgentID, Status_DBID, Reason_DBID, StartDate, callID, entityTypeID, stopReason, TenantID, StatID, Duration, EndDatetime, ScheduledCalcDatetime, ScheduledValidationResult)
                VALUES (Source.DBID, Source.AgentID, Source.Status_DBID, Source.Reason_DBID, Source.StartDate, Source.callID, Source.entityTypeID, Source.stopReason, Source.TenantID, Source.StatID, Source.Duration, Source.EndDatetime, Source.ScheduledCalcDatetime, Source.ScheduledValidationResult);
				SELECT ''���J�s�ƾڦܤw�g�s�b���l��'' AS Operation, @@ROWCOUNT AS RecordID INTO #TempOutputLog;  -- ���� INSERT �ާ@
            ';

            -- ����ʺA SQL ���J�ާ@
            EXEC sp_executesql @sql, N'@lastSixMonth DATE', @lastSixMonth;

            -- �ϥ� OUTPUT �O�� DELETE �ާ@
            SET @sql = N'
            DELETE FROM tblInteraction
            WHERE CONVERT(CHAR(6), StartDate, 112) = CONVERT(CHAR(6), @lastSixMonth, 112)
            SELECT ''�q����R��'' AS Operation, @@ROWCOUNT AS RecordID INTO #TempOutputLog;  -- ���� DELETE �ާ@
            ';

            -- ����ʺA SQL �R���ާ@
            EXEC sp_executesql @sql, N'@lastSixMonth DATE', @lastSixMonth;

            -- �O���ާ@���G�A�N OUTPUT ���G���J��x��
            INSERT INTO dbo.OperationLog (TableName, Action, RowsInserted, Result)
            SELECT @tableName, Operation, RecordID, @result FROM #TempOutputLog
        

        END
        ELSE
        --����tblInteraction_yyyyMM���s�b
        BEGIN
            -- �Ыت� SQL�]���Ыت�A�A���J��ơ^
            SET @sql = N'SELECT * INTO ' + QUOTENAME(@tableName) + ' FROM tblInteraction WITH(NOLOCK) WHERE CONVERT(CHAR(6), StartDate, 112) = ' + CONVERT(CHAR(6), @lastSixMonth, 112);
            
            -- ����Ыت�ô��J���
            EXEC sp_executesql @sql;

            -- �O�����J���
            SELECT @rowsInserted =  COUNT(*) 
            FROM tblInteraction 
            WHERE CONVERT(CHAR(6), StartDate, 112) = CONVERT(CHAR(6), @lastSixMonth, 112);

            -- �O���ާ@���G���x��
            INSERT INTO dbo.OperationLog (TableName, Action, RowsInserted,  Result)
            VALUES (@tableName, '���ʼƾڦܷs�Ыت��l��', @rowsInserted, @result);

            -- �N�Ӧ~��q����R��
            DELETE tblInteraction 
            WHERE CONVERT(CHAR(6), StartDate, 112) = CONVERT(CHAR(6), @lastSixMonth, 112);
            
            -- �O���R�������
            SET @rowsDeleted = @@ROWCOUNT;  -- �O���R�������

            -- �O���ާ@���G���x��
            INSERT INTO dbo.OperationLog (TableName, Action, RowsDeleted, Result)
            VALUES (@tableName, '�q����R���ƾ�', @rowsDeleted, @result);

            COMMIT TRANSACTION;

        END;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        -- ������~
        SET @result = 'Fail';
        SET @errorMessage = ERROR_MESSAGE();
        SET @errorLine = ERROR_LINE();

        -- �O�����~���x��
        INSERT INTO dbo.OperationLog (TableName, Action, RowsInserted, RowsDeleted, Result, ErrorMessage)
        VALUES (@tableName, '���~����', @rowsInserted, @rowsDeleted, @result, '��'+CONVERT(VARCHAR, @errorLine)+'����~ '+ @errorMessage);
    END CATCH;

    -- �M�z�{�ɪ�
    DROP TABLE #TempOutputLog;

END;

SET NOCOUNT OFF;
