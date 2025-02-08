--修改一筆tblInteraction EntityTypeID 設定為15 Status設定為1
--EndDate 設定 為 DATEADD(MINUTE,  -1 , GETDATE() ) 系統時間 - 設定檔裡的分鐘數

UPDATE tblInteraction SET EntityTypeID = '15' , Status = '1' , EndDate = DATEADD(MINUTE,  -1 , GETDATE() ) WHERE DBID = 1

--更新 tblRpt_VisiterCollectData 申請結果(紹定檔自訂義欄位)為'成功' callID 為剛剛更新的tblInteraction.callID

UPDATE tblRpt_VisiterCollectData SET CallID = (SELECT CallID FROM tblInteraction WHERE DBID = 1) WHERE DBID = (SELECT TOP 1 DBID FROM tblRpt_VisiterCollectData WHERE ExtendField01 = '成功')

--確認以下SQL可以查詢出結果

SET NOCOUNT ON;
DECLARE @lostVideoAndMailTime INT;
DECLARE @column NVARCHAR(25);
DECLARE @SQL NVARCHAR(MAX);

SET @lostVideoAndMailTime = 1; --設定檔裡的分鐘數
SET @column = 'ExtendField01'; --紹定檔自訂義欄位

SET @SQL = N'
    SELECT CallID,
           CONVERT(VARCHAR, StartDate, 121) AS StartDate,
           UserName,
           ' + QUOTENAME(@column) + ' AS VerifyResult
    FROM (
        SELECT tblInteraction.CallID,
               tblInteraction.StartDate,
               (SELECT USER_NAME FROM tblCfg_Person WHERE DBID = tblInteraction.AgentID) AS UserName,
               tblRpt_VisiterCollectData.' + QUOTENAME(@column) + '
        FROM (
            SELECT CallID, MIN(DBID) AS DBID
            FROM tblInteraction WITH(NOLOCK)
            WHERE EntityTypeID = ''15''
              AND Status = ''1''
              AND EndDate BETWEEN DATEADD(MINUTE, -(' + CAST(@lostVideoAndMailTime AS NVARCHAR(10)) + ' * 2), GETDATE())
                              AND DATEADD(MINUTE, -' + CAST(@lostVideoAndMailTime AS NVARCHAR(10)) + ', GETDATE())
            GROUP BY CallID
        ) AS InteractionCall
        INNER JOIN tblInteraction WITH(NOLOCK)
            ON tblInteraction.DBID = InteractionCall.DBID
        INNER JOIN tblRpt_VisiterCollectData WITH(NOLOCK)
            ON tblInteraction.CallID = tblRpt_VisiterCollectData.CallID
        LEFT JOIN tblVideoFile WITH(NOLOCK)
            ON InteractionCall.CallID = tblVideoFile.callID
            AND IO = ''i''
        WHERE tblVideoFile.DBID IS NULL
          AND LEN(tblInteraction.CallID) > 0
          AND tblRpt_VisiterCollectData.' + QUOTENAME(@column) + N' = ''成功''
        UNION ALL
        SELECT tblInteraction.CallID,
               CONVERT(VARCHAR, tblInteraction.StartDate, 121) AS StartDate,
               (SELECT USER_NAME FROM tblCfg_Person WHERE DBID = tblInteraction.AgentID) AS UserName,
               tblRpt_VisiterCollectData.' + QUOTENAME(@column) + '
        FROM (
            SELECT CallID, MIN(DBID) AS DBID
            FROM tblInteraction WITH(NOLOCK)
            WHERE EntityTypeID = ''15''
              AND Status = ''1''
              AND EndDate BETWEEN DATEADD(MINUTE, -(' + CAST(@lostVideoAndMailTime AS NVARCHAR(10)) + ' * 2), GETDATE())
                              AND DATEADD(MINUTE, -' + CAST(@lostVideoAndMailTime AS NVARCHAR(10)) + ', GETDATE())
            GROUP BY CallID
        ) AS InteractionCall
        INNER JOIN tblInteraction WITH(NOLOCK)
            ON tblInteraction.DBID = InteractionCall.DBID
        INNER JOIN tblRpt_VisiterCollectData WITH(NOLOCK)
            ON tblInteraction.CallID = tblRpt_VisiterCollectData.CallID
        LEFT JOIN tblVideoFile WITH(NOLOCK)
            ON InteractionCall.CallID = tblVideoFile.callID
            AND IO = ''o''
        WHERE tblVideoFile.DBID IS NULL
          AND LEN(tblInteraction.CallID) > 0
          AND tblRpt_VisiterCollectData.' + QUOTENAME(@column) + N' = ''成功''
    ) AS TBL
    GROUP BY CallID, StartDate, UserName, ' + QUOTENAME(@column) + ';
';

EXEC sp_executesql @SQL, N'@lostVideoAndMailTime INT, @column NVARCHAR(25)', @lostVideoAndMailTime, @column;

----------------------------------------

--如果要查看更動報表 需額外設定此更新
--將 剛剛 email 結果 callID 更換以下兩張報表


UPDATE tblVideoFile SET callID=N'B2024120400068346' , status = -13 WHERE DBID=4

UPDATE FUNC_HIS SET CALL_ID = N'B2024120400068346' WHERE SKEY = 4

--畫面上報表的開此時間跟結束時間為今日

