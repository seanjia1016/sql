-- 定義批次大小
DECLARE @BatchSize INT = 2000;
DECLARE @Offset INT = 0;

-- 創建暫存表以存放分批查詢的結果
CREATE TABLE #Temp_ActivityLog (
    dbid INT
);

-- 設置循環來分批查詢
WHILE 1 = 1
BEGIN
    -- 插入當前批次的數據到暫存表
    INSERT INTO #Temp_ActivityLog (dbid)
    SELECT dbid
    FROM tblRpt_Activitylog WITH(NOLOCK)
    WHERE dbid IN ( SELECT dbid 
    FROM tblRpt_Activitylog WITH(NOLOCK) )
    ORDER BY dbid
    OFFSET @Offset ROWS FETCH NEXT @BatchSize ROWS ONLY;

    -- 確認是否還有更多數據
    IF @@ROWCOUNT < @BatchSize
        BREAK;

    -- 更新偏移量
    SET @Offset = @Offset + @BatchSize;
END


SELECT
    tblRpt_Activitylog.InteractionID AS interactionID,
    tblRpt_Activitylog.dbid AS activityLogDBID,
    tblRpt_Activitylog.ActivityDataID AS activityDataID,
    tblRpt_Activitylog.DateTime AS dateTime,
    tblRpt_Activitylog.TenantID AS tenantID,
    tblRpt_Activitylog.EntityTypeID AS entityTypeID,
    tblRpt_Activitylog.PilotID AS pilotID,
    tblInteraction.StartDate AS startDate,
    tblInteraction.EndDate AS endDate,
    tblCfg_Person.USER_NAME AS userName,
    tblInteraction.Text AS comment,
    CASE
        WHEN tblInteraction.Text IS NOT NULL THEN REPLACE(REPLACE(tblInteraction.Text, '<', '&lt;'), '>', '&gt;')
        ELSE ''
    END AS comment,
    tblInteraction.ContactID AS contactId,
    tblInteractionContactData.ExtContactData01 AS extContactData01,
    tblInteractionContactData.ExtContactData02 AS extContactData02,
    tblInteractionContactData.ExtContactData03 AS extContactData03,
    tblInteractionContactData.ExtContactData04 AS extContactData04,
    tblInteractionContactData.ExtContactData05 AS extContactData05,
    tblInteractionContactData.ExtContactData06 AS extContactData06,
    tblInteractionContactData.ExtContactData07 AS extContactData07,
    tblInteractionContactData.ExtContactData08 AS extContactData08,
    tblInteractionContactData.ExtContactData09 AS extContactData09,
    tblInteractionContactData.ExtContactData10 AS extContactData10,
    tblInteractionContactData.ExtContactData11 AS extContactData11,
    tblInteractionContactData.ExtContactData12 AS extContactData12,
    tblInteractionContactData.ExtContactData13 AS extContactData13,
    tblInteractionContactData.ExtContactData14 AS extContactData14,
    tblInteractionContactData.ExtContactData15 AS extContactData15,
    tblInteractionContactData.ExtContactData16 AS extContactData16,
    tblInteractionContactData.ExtContactData17 AS extContactData17,
    tblInteractionContactData.ExtContactData18 AS extContactData18,
    tblInteractionContactData.ExtContactData19 AS extContactData19,
    tblInteractionContactData.ExtContactData20 AS extContactData20,
    tblInteractionContactData.ExtContactData21 AS extContactData21,
    tblInteractionContactData.ExtContactData22 AS extContactData22,
    tblInteractionContactData.ExtContactData23 AS extContactData23,
    tblInteractionContactData.ExtContactData24 AS extContactData24,
    tblInteractionContactData.ExtContactData25 AS extContactData25,
    tblInteractionContactData.ExtContactData26 AS extContactData26,
    tblInteractionContactData.ExtContactData27 AS extContactData27,
    tblInteractionContactData.ExtContactData28 AS extContactData28,
    tblInteractionContactData.ExtContactData29 AS extContactData29,
    tblInteractionContactData.ExtContactData30 AS extContactData30,
    tblInteractionContactData.ExtContactData31 AS extContactData31,
    tblInteractionContactData.ExtContactData32 AS extContactData32,
    tblInteractionContactData.ExtContactData33 AS extContactData33,
    tblInteractionContactData.ExtContactData34 AS extContactData34,
    tblInteractionContactData.ExtContactData35 AS extContactData35,
    tblInteractionContactData.ExtContactData36 AS extContactData36,
    tblInteractionContactData.ExtContactData37 AS extContactData37,
    tblInteractionContactData.ExtContactData38 AS extContactData38,
    tblInteractionContactData.ExtContactData39 AS extContactData39,
    tblInteractionContactData.ExtContactData40 AS extContactData40,
    tblInteractionContactData.ExtContactData41 AS extContactData41,
    tblInteractionContactData.ExtContactData42 AS extContactData42,
    tblInteractionContactData.ExtContactData43 AS extContactData43,
    tblInteractionContactData.ExtContactData44 AS extContactData44,
    tblInteractionContactData.ExtContactData45 AS extContactData45,
    tblInteractionContactData.ExtContactData46 AS extContactData46,
    tblInteractionContactData.ExtContactData47 AS extContactData47,
    tblInteractionContactData.ExtContactData48 AS extContactData48,
    tblInteractionContactData.ExtContactData49 AS extContactData49,
    tblInteractionContactData.ExtContactData50 AS extContactData50,
    tblInteractionContactData.ExtContactData51 AS extContactData51,
    tblInteractionContactData.ExtContactData52 AS extContactData52,
    tblInteractionContactData.ExtContactData53 AS extContactData53,
    tblInteractionContactData.ExtContactData54 AS extContactData54,
    tblInteractionContactData.ExtContactData55 AS extContactData55,
    tblInteractionContactData.ExtContactData56 AS extContactData56,
    tblInteractionContactData.ExtContactData57 AS extContactData57,
    tblInteractionContactData.ExtContactData58 AS extContactData58,
    tblInteractionContactData.ExtContactData59 AS extContactData59,
    tblInteractionContactData.ExtContactData60 AS extContactData60
FROM #Temp_ActivityLog tal
INNER JOIN tblRpt_Activitylog ON tal.dbid = tblRpt_Activitylog.dbid
INNER JOIN tblInteraction WITH(NOLOCK) ON tblRpt_Activitylog.InteractionID = tblInteraction.DBID
INNER JOIN tblCfg_Person WITH(NOLOCK) ON tblRpt_Activitylog.agentID = tblCfg_Person.DBID
LEFT JOIN tblInteractionContactData WITH(NOLOCK) ON tblInteraction.IxnID = tblInteractionContactData.IxnID
ORDER BY tal.dbid;

-- 刪除暫存表
DROP TABLE #Temp_ActivityLog;
