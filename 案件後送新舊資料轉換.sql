SET NOCOUNT ON;

/*--------------------執行新舊主表轉移開始--------------------*/

-- 先刪除暫存表，確保不會有衝突
-- IF OBJECT_ID('tempdb..#TempFuncData') IS NOT NULL DROP TABLE #TempFuncData;
-- IF OBJECT_ID('tempdb..#funcIDMapping') IS NOT NULL DROP TABLE #funcIDMapping;

-- 建立存新舊 ID 對應的暫存表
CREATE TABLE #funcIDMapping (
                                NEW_FUNC_ID BIGINT,
                                OLD_FUNC_ID INT
);

-- **✅ 先手動建立 `#TempFuncData`**
CREATE TABLE #TempFuncData (
                               RowNum BIGINT IDENTITY(1,1),  -- ✅ 自增 ID 確保順序
                               OLD_FUNC_ID INT,
                               FUNC_NAME NVARCHAR(255),
                               FUNC_COMMENTS NVARCHAR(MAX),
                               ACTIVE_STATUS INT,
                               MODIFY_TIME DATETIME2,
                               MODIFY_USER NVARCHAR(20),
                               IS_DEFAULT NVARCHAR(10),
                               FUNC_SORT INT,
                               CONTACT_TYPE_ID BIGINT,
                               TENANT_ID BIGINT
);

-- 填充暫存表
INSERT INTO #TempFuncData (OLD_FUNC_ID, FUNC_NAME, FUNC_COMMENTS, ACTIVE_STATUS, MODIFY_TIME, MODIFY_USER, IS_DEFAULT, FUNC_SORT, CONTACT_TYPE_ID, TENANT_ID)
SELECT
    tTT.DBID,  -- 舊主鍵
    tTT.Name,
    tTT.Description,
    CASE
        WHEN tTT.DeleteFlag = 'Y' THEN 2
        WHEN tTT.displayFlag = 'N' THEN 0
        WHEN tTT.DeleteFlag = 'N' THEN 1
        END,
    CAST(GETDATE() AS DateTime2),
    tTT.ModifyPersonID,
    'N',
    ROW_NUMBER() OVER (ORDER BY tTT.DBID) + 1,
    tTT.TypeID,
    tTT.TenantID
FROM tblTicketTemplate tTT;

-- **✅ 直接 `OUTPUT` 進 `#funcIDMapping`，不用 `#InsertedIDs`**
MERGE INTO tblCfg_FuncMain AS target
USING #TempFuncData AS source
ON 1 = 0  -- **強制 INSERT**
WHEN NOT MATCHED THEN
    INSERT (FUNC_NAME, FUNC_COMMENTS, ACTIVE_STATUS, MODIFY_TIME, MODIFY_USER, IS_DEFAULT, FUNC_SORT, TENANT_ID, CONTACT_TYPE_ID)
    VALUES (source.FUNC_NAME, source.FUNC_COMMENTS, source.ACTIVE_STATUS, source.MODIFY_TIME, source.MODIFY_USER, source.IS_DEFAULT, source.FUNC_SORT, source.TENANT_ID, source.CONTACT_TYPE_ID)
    OUTPUT inserted.FUNC_ID, source.OLD_FUNC_ID  -- **✅ 直接存進 `#funcIDMapping`**
        INTO #funcIDMapping;

-- **檢查對應關係**
SELECT * FROM #funcIDMapping;


/*--------------------執行新舊主表轉移結束--------------------*/

/*--------------------執行新舊案件分類轉移開始--------------------*/
-- 先刪除暫存表，確保不會有衝突
-- IF OBJECT_ID('tempdb..#TempFuncTypeData') IS NOT NULL DROP TABLE #TempFuncTypeData;
-- IF OBJECT_ID('tempdb..#typeIDMapping') IS NOT NULL DROP TABLE #typeIDMapping;

-- 建立存新舊 ID 對應的暫存表
CREATE TABLE #typeIDMapping (
                                NEW_TYPE_ID BIGINT,
                                OLD_TYPE_ID INT
);

-- **✅ 先手動建立 `#TempFuncTypeData`**
CREATE TABLE #TempFuncTypeData (
                                   RowNum BIGINT IDENTITY(1,1),  -- ✅ 加上自增 ID 來確保順序
                                   OLD_FUNC_TYPE_ID INT,
                                   FUNC_TYPE_NAME NVARCHAR(255),
                                   GROUP_ID BIGINT,
                                   PARENT_ID BIGINT,
                                   FUNC_TYPE_SORT INT,
                                   ACTIVE_STATUS INT,
                                   TENANT_ID BIGINT,
                                   MODIFY_TIME DATETIME2,
                                   MODIFY_USER BIGINT,
                                   IS_DEFAULT BIT
);

-- 填充暫存表
INSERT INTO #TempFuncTypeData (OLD_FUNC_TYPE_ID, FUNC_TYPE_NAME, GROUP_ID, PARENT_ID, FUNC_TYPE_SORT, ACTIVE_STATUS, TENANT_ID, MODIFY_TIME, MODIFY_USER, IS_DEFAULT)
SELECT
    tTC.DBID,  -- 舊主鍵
    tTC.Name,
    tTC.GroupID,
    tTC.ParentID,
    tTC.Sort,
    CASE tTC.DeleteFlag
        WHEN 'Y' THEN 1
        WHEN 'N' THEN 2
        END,
    tTC.tenantID,
    CAST(GETDATE() AS DateTime2),
    0, -- 以前的 'SYSTEM'
    0
FROM tblTicketCategory tTC;

-- **✅ 直接使用 `MERGE`，並將 `OUTPUT` 存入 `#typeIDMapping`**
MERGE INTO tblCfg_FuncType AS target
USING #TempFuncTypeData AS source
ON 1 = 0  -- **強制 INSERT**
WHEN NOT MATCHED THEN
    INSERT (FUNC_TYPE_NAME, GROUP_ID, PARENT_ID, FUNC_TYPE_SORT, ACTIVE_STATUS, TENANT_ID, MODIFY_TIME, MODIFY_USER, IS_DEFAULT)
    VALUES (source.FUNC_TYPE_NAME, source.GROUP_ID, source.PARENT_ID, source.FUNC_TYPE_SORT, source.ACTIVE_STATUS, source.TENANT_ID, source.MODIFY_TIME, source.MODIFY_USER, source.IS_DEFAULT)
    OUTPUT inserted.FUNC_TYPE_ID, source.OLD_FUNC_TYPE_ID  -- **✅ 直接存入 `#typeIDMapping`**
        INTO #typeIDMapping;

-- **檢查對應關係**
SELECT * FROM #typeIDMapping;

/*--------------------執行新舊案件分類轉移結束--------------------*/

/*--------------------執行新舊案件自定義欄位轉移開始--------------------*/
-- 先刪除暫存表，確保不會有衝突
-- IF OBJECT_ID('tempdb..#TempFuncFieldData') IS NOT NULL DROP TABLE #TempFuncFieldData;
-- IF OBJECT_ID('tempdb..#funcFieldIDMapping') IS NOT NULL DROP TABLE #funcFieldIDMapping;

-- 建立存新舊 ID 對應的暫存表
CREATE TABLE #funcFieldIDMapping (
                                     NEW_FUNC_FIELD_ID BIGINT,
                                     OLD_FUNC_FIELD_ID INT
);

-- **✅ 先手動建立 `#TempFuncFieldData`**
CREATE TABLE #TempFuncFieldData (
                                    RowNum BIGINT IDENTITY(1,1),  -- ✅ 加上自增 ID 確保順序
                                    OLD_FUNC_FIELD_ID INT,
                                    FUNC_FIELD_NAME NVARCHAR(255),
                                    FUNC_FIELD_COMMENTS NVARCHAR(MAX),
                                    FUNC_FIELD_TYPE NVARCHAR(100),
                                    REQUIRED BIT,
                                    ACTIVE_STATUS INT,
                                    MODIFY_TIME DATETIME2,
                                    MODIFY_USER BIGINT,
                                    TENANT_ID BIGINT,
                                    SEARCH_COL_TYPE NVARCHAR(100)
);

-- **✅ 先將 CTE 資料插入暫存表**
INSERT INTO #TempFuncFieldData (OLD_FUNC_FIELD_ID, FUNC_FIELD_NAME, FUNC_FIELD_COMMENTS, FUNC_FIELD_TYPE, REQUIRED, ACTIVE_STATUS, MODIFY_TIME, MODIFY_USER, TENANT_ID, SEARCH_COL_TYPE)
SELECT
    tTCT.DBID,
    tTCT.Title,
    tTCT.description,
    tTCT.TitleType,
    IIF(tTCT.IsRequire = 'N', 0, 1),
    IIF(tTCT.DeleteFlag = 'N', 1, 2),
    CAST(GETDATE() AS DATETIME2),
    0, -- 以前的 'SYSTEM'
    tTT.TenantID,
    CASE tTCT.TitleType
        WHEN 'input' THEN 'basic-text'
        WHEN 'inputforEnglish' THEN 'basic-text-english'
        WHEN 'inputforNumber' THEN 'basic-text-number'
        WHEN 'inputforNumberAndEnglish' THEN 'basic-text-number-english'
        WHEN 'inputforNumberAndSign' THEN 'basic-text-number-sign'
        WHEN 'inputforSignAndEnglish' THEN 'basic-text-english-sign'
        WHEN 'select' THEN 'basic-select'
        WHEN 'selectlist' THEN 'multiple-select'
        WHEN 'cusData' THEN 'text-with-switch-btn'
        ELSE 'Unknown funcFieldType'
        END
FROM tblTicketColTitle tTCT
         JOIN tblTicketTemplate tTT ON tTCT.TicketTemplateID = tTT.DBID
WHERE tTCT.Type = 'castom';

-- **✅ 直接使用 `MERGE`，並將 `OUTPUT` 存入 `#funcFieldIDMapping`**
MERGE INTO tblCfg_FuncField AS target
USING #TempFuncFieldData AS source
ON 1 = 0  -- **強制 INSERT**
WHEN NOT MATCHED THEN
    INSERT (FUNC_FIELD_NAME, FUNC_FIELD_COMMENTS, FUNC_FIELD_TYPE, REQUIRED, ACTIVE_STATUS, MODIFY_TIME, MODIFY_USER, TENANT_ID, SEARCH_COL_TYPE)
    VALUES (source.FUNC_FIELD_NAME, source.FUNC_FIELD_COMMENTS, source.FUNC_FIELD_TYPE, source.REQUIRED, source.ACTIVE_STATUS, source.MODIFY_TIME, source.MODIFY_USER, source.TENANT_ID, source.SEARCH_COL_TYPE)
    OUTPUT inserted.FUNC_FIELD_ID, source.OLD_FUNC_FIELD_ID  -- **✅ 直接存入 `#funcFieldIDMapping`**
        INTO #funcFieldIDMapping;

-- **檢查對應關係**
SELECT * FROM #funcFieldIDMapping;

/*--------------------執行新舊自定義欄位轉移結束--------------------*/

/*--------------------執行新舊案件主表和自定義欄位Mapping表轉移開始--------------------*/
-- 先刪除暫存表，確保不會有衝突
-- IF OBJECT_ID('tempdb..#TempFuncFieldMapping') IS NOT NULL DROP TABLE #TempFuncFieldMapping;

-- **✅ 先手動建立 `#TempFuncFieldMapping`**
CREATE TABLE #TempFuncFieldMapping (
                                       RowNum BIGINT IDENTITY(1,1),  -- ✅ 加上自增 ID 確保順序
                                       FUNC_ID BIGINT,
                                       FUNC_FIELD_ID BIGINT,
                                       TICKET_DISPLAY INT,
                                       TICKET_FORM_HEADER_DISPLAY INT,
                                       TICKET_REPLY_DISPLAY INT,
                                       FUNC_FIELD_SORT INT,
                                       DELETE_FLAG NVARCHAR(10) -- 假設 DeleteFlag 是 NVARCHAR(10)，根據實際情況調整
);

-- **✅ 先將 CTE 內容插入暫存表**
INSERT INTO #TempFuncFieldMapping (FUNC_ID, FUNC_FIELD_ID, TICKET_DISPLAY, TICKET_FORM_HEADER_DISPLAY, TICKET_REPLY_DISPLAY, FUNC_FIELD_SORT, DELETE_FLAG)
SELECT
    t2.NEW_FUNC_ID,
    t3.NEW_FUNC_FIELD_ID,
    IIF(tTCT.ColType = 'Open', 1, 0),
    IIF(tTCT.ColType = 'Open', 1, 0),
    1,
    ROW_NUMBER() OVER (PARTITION BY t2.NEW_FUNC_ID, t3.NEW_FUNC_FIELD_ID ORDER BY tTCT.Sort),
    tTCT.DeleteFlag
FROM
    (SELECT DISTINCT tTT.DBID AS OLD_FUNC_ID, tTCT.DBID AS OLD_FUNC_FIELD_ID
     FROM tblTicketColTitle tTCT
              JOIN dbo.tblTicketTemplate tTT ON (tTCT.TicketTemplateID = tTT.DBID)) AS t1
        JOIN tblTicketColTitle tTCT ON (t1.OLD_FUNC_FIELD_ID = tTCT.DBID)
        JOIN #FuncIDMapping t2 ON (t1.OLD_FUNC_ID = t2.OLD_FUNC_ID)
        JOIN #funcFieldIDMapping t3 ON (t1.OLD_FUNC_FIELD_ID = t3.OLD_FUNC_FIELD_ID);

-- **✅ 直接使用 `MERGE`，並將 `OUTPUT` 存入變數**
DECLARE @NEW_FUNC_FIELD_MAPPING_ID TABLE (NEW_FUNC_FIELD_MAPPING_ID BIGINT);

MERGE INTO tblCfg_FuncFieldMapping AS target
USING #TempFuncFieldMapping AS source
ON 1 = 0  -- **強制 INSERT**
WHEN NOT MATCHED THEN
    INSERT (FUNC_ID, FUNC_FIELD_ID, TICKET_DISPLAY, TICKET_FORM_HEADER_DISPLAY, TICKET_REPLY_DISPLAY, FUNC_FIELD_SORT, DELETE_FLAG)
    VALUES (source.FUNC_ID, source.FUNC_FIELD_ID, source.TICKET_DISPLAY, source.TICKET_FORM_HEADER_DISPLAY, source.TICKET_REPLY_DISPLAY, source.FUNC_FIELD_SORT, source.DELETE_FLAG)
    OUTPUT inserted.DBID INTO @NEW_FUNC_FIELD_MAPPING_ID;

-- **檢查新插入的 ID**
SELECT * FROM @NEW_FUNC_FIELD_MAPPING_ID;

/*--------------------執行新舊案件主表和自定義欄位Mapping表轉移結束--------------------*/

/*--------------------執行新舊工單轉移開始--------------------*/
-- IF OBJECT_ID('tempdb..#TempTicket') IS NOT NULL DROP TABLE #TempTicket;
-- IF OBJECT_ID('tempdb..#ticketIDMapping') IS NOT NULL DROP TABLE  #ticketIDMapping;
CREATE TABLE #ticketIDMapping
(
    OLD_TICKET_ID INT,
    NEW_TICKET_ID bigint
)

-- **✅ 建立 `#TempTicket` 暫存表**
CREATE TABLE #TempTicket (
                             TICKET_ID INT,
                             FUNC_ID BIGINT,
                             FUNC_STATUS_ID INT,
                             FUNC_TYPE_ID BIGINT,
                             TENANT_ID BIGINT,
                             CONTACT_ID BIGINT,
                             CONTACT_TYPE_ID BIGINT,
                             IXN_ID BIGINT,
                             TICKET_SUBJECT NVARCHAR(255),
                             TICKET_CONTENT NVARCHAR(MAX),
                             TICKET_PRIORITY INT,
                             TICKET_MEMO NVARCHAR(MAX),
                             TICKET_REPLY_CONTENT NVARCHAR(MAX),
                             CREATE_TIME DATETIME2,
                             CREATE_USER BIGINT,
                             HANDLING_PERSON BIGINT,
                             HANDLING_PILOT BIGINT,
                             MODIFY_TIME DATETIME2,
                             MODIFY_USER BIGINT,
                             EXPIRED_TIME DATETIME2,
                             WATCHERS_ID NVARCHAR(MAX),
                             IS_DRAFT INT,
                             EMAIL_NOTICE_FLAG INT,
                             ACTIVE_STATUS INT
);

-- **✅ 先將 CTE 內容存入 `#TempTicket`**
INSERT INTO #TempTicket (TICKET_ID, FUNC_ID, FUNC_STATUS_ID, FUNC_TYPE_ID, TENANT_ID, CONTACT_ID, CONTACT_TYPE_ID,
                         IXN_ID, TICKET_SUBJECT, TICKET_CONTENT, TICKET_PRIORITY, TICKET_MEMO, TICKET_REPLY_CONTENT,
                         CREATE_TIME, CREATE_USER, HANDLING_PERSON, HANDLING_PILOT, MODIFY_TIME, MODIFY_USER, EXPIRED_TIME,
                         WATCHERS_ID, IS_DRAFT, EMAIL_NOTICE_FLAG, ACTIVE_STATUS)
SELECT
    tT.DBID,
    fIM.NEW_FUNC_ID,
    CASE tT.TicketStatus
        WHEN 'ACCEPT' THEN 2
        WHEN 'TRANSFER' THEN 2
        WHEN 'REQOPEN' THEN 7
        WHEN 'CLOSED' THEN 5
        WHEN 'DELETE' THEN 6
        END,
    tIM.NEW_TYPE_ID,
    tT.tenantId,
    tT.contactID,
    tT.typeID,
    tIII.IxnID,
    tT.Subject,
    tTSI.Content,
    tT.PriorityID,
    tT.Memo,
    tTSI2.TicketContentText,
    CAST(tT.CreateTime AS DATETIME2),
    IIF(tT.OwnerID = 'SYSTEM', 0, ISNULL(TRY_CAST(tT.OwnerID AS BIGINT), 0)),
    IIF(ISNUMERIC(tT.holderId) = 1, tT.holderId, NULL),
    IIF(ISNUMERIC(tT.holderId) = 0, 0, NULL),
    CAST(tT.ModifyTime AS DATETIME2),
    IIF(tT.ModifyPersonID = 'SYSTEM', 0, ISNULL(TRY_CAST(tT.ModifyPersonID AS BIGINT), 0)),
    CAST(tT.EndTime AS DATETIME2),
    TIPL.PersonList,
    IIF(tT.isTemp = 'N', 0, 1),
    IIF(tEC.EMAIL_NOTICE_FLAG > 0, 1, 0),
    IIF(tT.TicketStatus = 'DELETE', 2, 1)
FROM tblTicket tT
         OUTER APPLY (SELECT TOP 1 tTSI.Content FROM tblTicketSubItem tTSI WHERE tT.DBID = tTSI.TicketID ORDER BY tTSI.DBID) tTSI
         OUTER APPLY (SELECT TOP 1 tTSI.TicketContentText FROM tblTicketSubItem tTSI WHERE tT.DBID = tTSI.TicketID AND tTSI.ReplyType = 'Reply' ORDER BY tTSI.DBID) tTSI2
         OUTER APPLY (SELECT TicketID, '[' + STUFF((SELECT ',"' + COALESCE(NULLIF(PersonID, ''), MonitorEmail) + '"'
                                                    FROM tblTicketMonitor t2 WHERE t1.TicketID = t2.TicketID FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
                                                   1, 1, '') + ']' AS PersonList FROM tblTicketMonitor t1 WHERE tT.DBID = t1.TicketID GROUP BY TicketID) TIPL
         OUTER APPLY (SELECT TOP 1 IxnID FROM tblInteraction tI WHERE tI.TenantID = tT.tenantId AND tI.ContactID = tT.contactID AND tI.SystemID = tT.DBID ORDER BY StartDate DESC) tIII
         OUTER APPLY (SELECT TOP 1 COUNT(1) AS EMAIL_NOTICE_FLAG FROM tblEmailOut tEO WHERE tEO.IxnID = tIII.IxnID) tEC
         LEFT JOIN #funcIDMapping fIM ON tT.TicketTemplateID = fIM.OLD_FUNC_ID
         LEFT JOIN #typeIDMapping tIM ON tT.TicketCategoryID = tIM.OLD_TYPE_ID;

-- **✅ 使用 `MERGE` 插入數據，同時直接 `OUTPUT` 到 `#ticketIDMapping`**
MERGE INTO tblRpt_Ticket AS target
USING #TempTicket AS source
ON 1 = 0  -- **強制 `INSERT`**
WHEN NOT MATCHED THEN
    INSERT (FUNC_ID, FUNC_STATUS_ID, FUNC_TYPE_ID, TENANT_ID, CONTACT_ID, CONTACT_TYPE_ID, IXN_ID,
            TICKET_SUBJECT, TICKET_CONTENT, TICKET_PRIORITY, TICKET_MEMO, TICKET_REPLY_CONTENT, CREATE_TIME,
            CREATE_USER, HANDLING_PERSON, HANDLING_PILOT, MODIFY_TIME, MODIFY_USER, EXPIRED_TIME,
            WATCHERS_ID, IS_DRAFT, EMAIL_NOTICE_FLAG, ACTIVE_STATUS)
    VALUES (source.FUNC_ID, source.FUNC_STATUS_ID, source.FUNC_TYPE_ID, source.TENANT_ID, source.CONTACT_ID,
            source.CONTACT_TYPE_ID, source.IXN_ID, source.TICKET_SUBJECT, source.TICKET_CONTENT, source.TICKET_PRIORITY,
            source.TICKET_MEMO, source.TICKET_REPLY_CONTENT, source.CREATE_TIME, source.CREATE_USER,
            source.HANDLING_PERSON, source.HANDLING_PILOT, source.MODIFY_TIME, source.MODIFY_USER,
            source.EXPIRED_TIME, source.WATCHERS_ID, source.IS_DRAFT, source.EMAIL_NOTICE_FLAG, source.ACTIVE_STATUS)
    OUTPUT inserted.TICKET_ID, source.TICKET_ID INTO #ticketIDMapping (NEW_TICKET_ID, OLD_TICKET_ID);

-- **✅ 檢查新舊 ID 對應**
SELECT * FROM #ticketIDMapping;

/*--------------------執行新舊工單轉移結束--------------------*/

/*--------------------執行新舊工單自定義欄位轉移開始--------------------*/
-- 先刪除暫存表，避免影響
-- IF OBJECT_ID('tempdb..#TempTicketField') IS NOT NULL DROP TABLE #TempTicketField;
-- IF OBJECT_ID('tempdb..#ticketFieldIDMapping') IS NOT NULL DROP TABLE #ticketFieldIDMapping;

CREATE TABLE #ticketFieldIDMapping
(
    OLD_TICKET_FIELD_ID INT,
    NEW_TICKET_FIELD_ID bigint
)

-- ✅ **建立 `#TempTicketField` 暫存表**
CREATE TABLE #TempTicketField (
                                  DBID INT,
                                  TICKET_ID BIGINT,
                                  FUNC_FIELD_ID BIGINT,
                                  FIELD_NAME NVARCHAR(255),
                                  ARRAY_VALUE NVARCHAR(MAX),
                                  ACTIVE_STATUS INT
);

-- ✅ **使用 `ArrayValues` CTE 預處理 `ARRAY_VALUE`**
WITH ArrayValues AS (
    SELECT DISTINCT
        tRTCD.TicketID,
        tRTCD.TicketColID,
        (SELECT STUFF((SELECT '|,|' + tRTCD2.Value
                       FROM tblRpt_TicketColData tRTCD2
                       WHERE tRTCD2.TicketID = tRTCD.TicketID
                         AND tRTCD2.TicketColID = tRTCD.TicketColID
                       FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 3, '')) AS ARRAY_VALUE
    FROM tblRpt_TicketColData tRTCD
)
-- ✅ **將 CTE 結果存入 `#TempTicketField`，避免 CTE 內部重複計算**
INSERT INTO #TempTicketField (DBID, TICKET_ID, FUNC_FIELD_ID, FIELD_NAME, ARRAY_VALUE, ACTIVE_STATUS)
SELECT
    tRTCD.DBID,  -- ✅ 只是作紀錄，不影響 GROUP
    tIM.NEW_TICKET_ID,
    fFIM.NEW_FUNC_FIELD_ID,
    tTCT.Title,
    AV.ARRAY_VALUE,
    IIF(tTCT.DeleteFlag = 'N', 1, 2)  -- `DeleteFlag = 'N'` 則 `ACTIVE_STATUS=1`
FROM tblRpt_TicketColData tRTCD
         JOIN tblTicketColTitle tTCT ON tRTCD.TicketColID = tTCT.DBID
         JOIN tblTicketTemplate tTT ON tTCT.TicketTemplateID = tTT.DBID
         JOIN #ticketIDMapping tIM ON tRTCD.TicketID = tIM.OLD_TICKET_ID
         JOIN #funcFieldIDMapping fFIM ON tTCT.DBID = fFIM.OLD_FUNC_FIELD_ID
         JOIN ArrayValues AV ON tRTCD.TicketID = AV.TicketID AND tRTCD.TicketColID = AV.TicketColID;

-- ✅ **使用 `MERGE` 插入數據，並 `OUTPUT` 到 `#ticketFieldIDMapping`**
MERGE INTO tblRpt_TicketField AS target
USING #TempTicketField AS source
ON 1 = 0  -- **強制 `INSERT`**
WHEN NOT MATCHED THEN
    INSERT (TICKET_ID, FUNC_FIELD_ID, FIELD_NAME, ARRAY_VALUE, ACTIVE_STATUS)
    VALUES (source.TICKET_ID, source.FUNC_FIELD_ID, source.FIELD_NAME, source.ARRAY_VALUE, source.ACTIVE_STATUS)
    OUTPUT inserted.DBID, source.DBID INTO #ticketFieldIDMapping (NEW_TICKET_FIELD_ID, OLD_TICKET_FIELD_ID);

-- ✅ **檢查新舊 ID 對應**
SELECT * FROM #ticketFieldIDMapping;

/*--------------------執行新舊工單自定義欄位轉移結束--------------------*/

/*--------------------執行新舊工單附件轉移開始--------------------*/
-- 先刪除暫存表，避免影響
-- IF OBJECT_ID('tempdb..#TempTicketAttach') IS NOT NULL DROP TABLE #TempTicketAttach;
-- IF OBJECT_ID('tempdb..#ticketAttachIDMapping') IS NOT NULL DROP TABLE #ticketAttachIDMapping;
CREATE TABLE #ticketAttachIDMapping
(
    OLD_TICKET_ATTACH_ID INT,
    NEW_TICKET_ATTACH_ID bigint
)

-- ✅ **建立 `#TempTicketAttach` 暫存表**
CREATE TABLE #TempTicketAttach (
                                   DBID INT,
                                   TICKET_ID BIGINT,
                                   FILE_PATH NVARCHAR(255),
                                   DISPLAY_NAME NVARCHAR(255),
                                   MODIFY_TIME DATETIME2,
                                   ACTIVE_STATUS INT,
                                   MODIFY_USER BIGINT
);

-- ✅ **將 CTE 轉換為臨時表，減少計算次數**
INSERT INTO #TempTicketAttach (DBID, TICKET_ID, FILE_PATH, DISPLAY_NAME, MODIFY_TIME, ACTIVE_STATUS, MODIFY_USER)
SELECT
    tTAD.DBID,
    tIM.NEW_TICKET_ID,
    tTAD.attachDataSorce,
    tTAD.displayName,
    CAST(GETDATE() AS DATETIME2),
    IIF(tTAD.deleteFlag = 1, 2, 1),
    tTSI.createPersonID
FROM tblTicketAttachData tTAD
         JOIN tblTicketSubItem tTSI ON tTAD.subitemID = tTSI.DBID
         JOIN #ticketIDMapping tIM ON tTSI.TicketID = tIM.OLD_TICKET_ID;

-- ✅ **使用 `MERGE` 插入數據，並 `OUTPUT` 到 `#ticketAttachIDMapping`**
MERGE INTO tblRpt_TicketAttach AS target
USING #TempTicketAttach AS source
ON 1 = 0  -- **強制 `INSERT`**
WHEN NOT MATCHED THEN
    INSERT (TICKET_ID, FILE_PATH, DISPLAY_NAME, MODIFY_TIME, ACTIVE_STATUS, MODIFY_USER)
    VALUES (source.TICKET_ID, source.FILE_PATH, source.DISPLAY_NAME, source.MODIFY_TIME, source.ACTIVE_STATUS, source.MODIFY_USER)
    OUTPUT inserted.DBID, source.DBID INTO #ticketAttachIDMapping (NEW_TICKET_ATTACH_ID, OLD_TICKET_ATTACH_ID);

-- ✅ **檢查新舊 ID 對應**
SELECT * FROM #ticketAttachIDMapping;

/*--------------------執行新舊工單附件轉移結束--------------------*/

SELECT DISTINCT *
FROM tblTicket
SELECT *
FROM tblCfg_FuncMain
SELECT *
FROM tblRpt_Ticket
SELECT *
FROM tblCfg_FuncType
SELECT *
FROM tblTicketSubItem
SELECT *
FROM tblRpt_TicketField
SELECT *
FROM tblRpt_TicketColData
SELECT *
FROM tblTicketColTitle
SELECT DISTINCT *
FROM tblCfg_FuncField
SELECT *
FROM tblCfg_SolrSearchColumn
SELECT *
FROM tblCfg_FuncFieldMapping
SELECT *
FROM tblRpt_TicketAttach
SELECT *
FROM tblTicketTemplate

-- SELECT DISTINCT FUNC_FIELD_TYPE, SEARCH_COL_TYPE
-- FROM tblCfg_FuncField
-- WHERE LTRIM(FUNC_FIELD_TYPE) <> 'basic'
--   AND LTRIM(FUNC_FIELD_TYPE) <> 'system'