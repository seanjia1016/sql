SET NOCOUNT ON;

/*--------------------執行新舊主表轉移開始--------------------*/

-- 建立暫存表來儲存舊PK和新PK的對應關係
CREATE TABLE #funcIDMapping
(
    OLD_FUNC_ID INT,
    NEW_FUNC_ID BIGINT
);

-- 使用 CTE 準備插入數據
WITH OLD_FUNC_TO_NEW AS (SELECT tTT.DBID                              AS OLD_FUNC_ID, -- 這是舊的PK
                                tTT.Name                              AS FUNC_NAME,
                                tTT.Description                       AS FUNC_COMMENTS,
                                CASE
                                    WHEN tTT.DeleteFlag = 'Y' THEN 2
                                    WHEN tTT.displayFlag = 'N' THEN 0
                                    WHEN tTT.DefaultFlag = 'N' THEN 1
                                    END                               AS ACTIVE_STATUS,
                                CAST(GETDATE() AS DateTime2)          AS MODIFY_TIME,
                                tTT.ModifyPersonID                    AS MODIFY_USER,
                                0                                     AS IS_DEFAULT,
                                ROW_NUMBER() OVER (ORDER BY tTT.DBID) AS FUNC_SORT,
                                 tTT.TypeID                            AS CONTACT_TYPE_ID,
                                tTT.TenantID                          AS TENANT_ID
                         FROM tblTicketTemplate tTT)

-- 將數據插入到 `tblCfg_FuncMain`，並輸出新舊PK到 #funcIDMapping
INSERT
INTO tblCfg_FuncMain (FUNC_NAME,
                      FUNC_COMMENTS,
                      ACTIVE_STATUS,
                      MODIFY_TIME,
                      MODIFY_USER,
                      IS_DEFAULT,
                      FUNC_SORT,
                      TENANT_ID,
                      CONTACT_TYPE_ID)
OUTPUT inserted.FUNC_ID,
       OLD_FUNC_TO_NEW.OLD_FUNC_ID -- 記錄新舊PK關係
    INTO #funcIDMapping (NEW_FUNC_ID, OLD_FUNC_ID)
SELECT FUNC_NAME,
       FUNC_COMMENTS,
       ACTIVE_STATUS,
       MODIFY_TIME,
       MODIFY_USER,
       IS_DEFAULT,
       FUNC_SORT,
       TENANT_ID,
       CONTACT_TYPE_ID
FROM OLD_FUNC_TO_NEW;

-- 檢查暫存表是否成功存入對應關係
SELECT *
FROM #funcIDMapping;

/*--------------------執行新舊主表轉移結束--------------------*/

/*--------------------執行新舊案件分類轉移開始--------------------*/
CREATE TABLE #typeIDMapping
(
    OLD_TYPE_ID INT,
    NEW_TYPE_ID bigint
)
;
WITH OLD_TYPE_TO_NEW AS (SELECT tTC.DBID                     AS OLD_FUNC_TYPE_ID,
                                tTC.Name                     AS FUNC_TYPE_NAME,
                                tTC.GroupID                  AS GROUP_ID,
                                tTC.ParentID                 AS PARENT_ID,
                                tTC.Sort                     AS FUNC_TYPE_SORT,
                                CASE tTC.DeleteFlag
                                    WHEN 'Y' THEN 1
                                    WHEN 'N' THEN 2
                                    END                      AS ACTIVE_STATUS,
                                tTC.tenantID                 AS TENANT_ID,
                                CAST(GETDATE() AS DateTime2) AS MODIFY_TIME,
                                0                            AS MODIFY_USER, --以前的'SYSTEM'
                                0                            AS IS_DEFAULT
                         FROM tblTicketCategory tTC)

INSERT
INTO tblCfg_FuncType (FUNC_TYPE_NAME,
                      GROUP_ID,
                      PARENT_ID,
                      FUNC_TYPE_SORT,
                      ACTIVE_STATUS,
                      TENANT_ID,
                      MODIFY_TIME,
                      MODIFY_USER,
                      IS_DEFAULT)
OUTPUT inserted.FUNC_TYPE_ID,
       OLD_TYPE_TO_NEW.OLD_FUNC_TYPE_ID -- 記錄新舊PK關係
    INTO #typeIDMapping (NEW_TYPE_ID, OLD_TYPE_ID)
SELECT FUNC_TYPE_NAME,
       GROUP_ID,
       PARENT_ID,
       FUNC_TYPE_SORT,
       ACTIVE_STATUS,
       TENANT_ID,
       MODIFY_TIME,
       MODIFY_USER,
       IS_DEFAULT
FROM OLD_TYPE_TO_NEW
/*--------------------執行新舊案件分類轉移結束--------------------*/

/*--------------------執行新舊案件自定義欄位轉移開始--------------------*/
CREATE TABLE #funcFieldIDMapping
(
    OLD_FUNC_FIELD_ID INT,
    NEW_FUNC_FIELD_ID BIGINT
);
;
WITH OLD_FUNC_FIELD_TO_NEW AS (SELECT tTCT.DBID                        AS FUNC_FIELD_ID,
                                      tTCT.Title                       AS FUNC_FIELD_NAME,
                                      tTCT.description                 AS FUNC_FIELD_COMMENTS,
                                      tTCT.TitleType                   AS FUNC_FIELD_TYPE,
                                      IIF(tTCT.IsRequire = 'N', 0, 1)  AS REQUIRED,
                                      IIF(tTCT.DeleteFlag = 'N', 1, 2) AS ACTIVE_STATUS,
                                      CAST(GETDATE() AS DATETIME2)     AS MODIFY_TIME,
                                      0                                AS MODIFY_USER, --'SYSTEM'
                                      tTT.TenantID                     AS TENANT_ID,
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
                                          END                          AS SEARCH_COL_TYPE
                               FROM tblTicketColTitle tTCT
                                        JOIN tblTicketTemplate tTT ON (tTCT.TicketTemplateID = tTT.DBID)
                               WHERE tTCT.Type = 'castom')
INSERT
INTO tblCfg_FuncField (FUNC_FIELD_NAME,
                       FUNC_FIELD_COMMENTS,
                       FUNC_FIELD_TYPE,
                       REQUIRED,
                       ACTIVE_STATUS,
                       MODIFY_TIME,
                       MODIFY_USER, --'SYSTEM'
                       TENANT_ID,
                       SEARCH_COL_TYPE)
OUTPUT inserted.FUNC_FIELD_ID,
       OLD_FUNC_FIELD_TO_NEW.FUNC_FIELD_ID
    INTO #funcFieldIDMapping (NEW_FUNC_FIELD_ID, OLD_FUNC_FIELD_ID)
SELECT FUNC_FIELD_NAME,
       FUNC_FIELD_COMMENTS,
       FUNC_FIELD_TYPE,
       REQUIRED,
       ACTIVE_STATUS,
       MODIFY_TIME,
       MODIFY_USER, --'SYSTEM'
       TENANT_ID,
       SEARCH_COL_TYPE
FROM OLD_FUNC_FIELD_TO_NEW

/*--------------------執行新舊自定義欄位轉移結束--------------------*/

/*--------------------執行新舊案件主表和自定義欄位Mapping表轉移開始--------------------*/
DECLARE @NEW_FUNC_FIELD_MAPPING_ID BIGINT
;
WITH OLD_FUNC_FIELD_MAPPING_TO_NEW AS (SELECT t2.NEW_FUNC_ID                                                                          AS FUNC_ID,
                                              t3.NEW_FUNC_FIELD_ID                                                                    AS FUNC_FIELD_ID,
                                              IIF(tTCT.ColType = 'Open', 1, 0)                                                        AS TICKET_DISPLAY,
                                              IIF(tTCT.ColType = 'Open', 1, 0)                                                        AS TICKET_FORM_HEADER_DISPLAY,
                                              1                                                                                       AS TICKET_REPLY_DISPLAY,
                                              ROW_NUMBER() over (PARTITION BY t2.NEW_FUNC_ID,t3.NEW_FUNC_FIELD_ID ORDER BY tTCT.Sort) AS FUNC_FIELD_SORT,
                                               tTCT.DeleteFlag                                                                         AS DELETE_FLAG
                                       FROM (SELECT DISTINCT tTT.DBID AS OLD_FUNC_ID, tTCT.DBID AS OLD_FUNC_FIELD_ID
                                             FROM tblTicketColTitle tTCT
                                                      JOIN dbo.tblTicketTemplate tTT ON (tTCT.TicketTemplateID = tTT.DBID)) AS t1
                                                JOIN tblTicketColTitle tTCT ON (t1.OLD_FUNC_FIELD_ID = tTCT.DBID)
                                                JOIN #FuncIDMapping t2 ON (t1.OLD_FUNC_ID = t2.OLD_FUNC_ID)
                                                JOIN #funcFieldIDMapping t3 ON (t1.OLD_FUNC_FIELD_ID = t3.OLD_FUNC_FIELD_ID))
INSERT
INTO tblCfg_FuncFieldMapping(
    FUNC_ID,
    FUNC_FIELD_ID,
    TICKET_DISPLAY,
    TICKET_FORM_HEADER_DISPLAY,
    TICKET_REPLY_DISPLAY,
    FUNC_FIELD_SORT,
    DELETE_FLAG)
OUTPUT @NEW_FUNC_FIELD_MAPPING_ID = inserted.DBID
SELECT FUNC_ID,
       FUNC_FIELD_ID,
       TICKET_DISPLAY,
       TICKET_FORM_HEADER_DISPLAY,
       TICKET_REPLY_DISPLAY,
       FUNC_FIELD_SORT,
       DELETE_FLAG
FROM OLD_FUNC_FIELD_MAPPING_TO_NEW
/*--------------------執行新舊工單轉移開始--------------------*/
CREATE TABLE #ticketIDMapping
(
    OLD_TICKET_ID INT,
    NEW_TICKET_ID bigint
)

-- 使用 CTE 準備插入數據
;
WITH OLD_TICKET_TO_NEW AS (SELECT tT.DBID                                               AS TICKET_ID,
                                  fIM.NEW_FUNC_ID                                       AS FUNC_ID,
                                  CASE tT.TicketStatus
                                      WHEN 'ACCEPT' THEN 2
                                      WHEN 'TRANSFER' THEN 2
                                      WHEN 'REQOPEN' THEN 7
                                      WHEN 'CLOSED' THEN 5
                                      WHEN 'DELETE' THEN 6
                                      END                                               AS FUNC_STATUS_ID,
                                  tIM.NEW_TYPE_ID                                       AS FUNC_TYPE_ID,
                                  tT.tenantId                                           AS TENANT_ID,
                                  tT.contactID                                          AS CONTACT_ID,
                                  tT.typeID                                             AS CONTACT_TYPE_ID,
                                  tIII.IxnID                                            AS IXN_ID,
                                  tT.Subject                                            AS TICKET_SUBJECT,
                                  tTSI.Content                                          AS TICKET_CONTENT,
                                  tT.PriorityID                                         AS TICKET_PRIORITY,
                                  tT.Memo                                               AS TICKET_MEMO,
                                  tTSI2.TicketContentText                               AS TICKET_REPLY_CONTENT,
                                  CAST(tT.CreateTime AS DATETIME2)                      AS CREATE_TIME,
                                  IIF(tT.OwnerID = 'SYSTEM', CAST(0 AS BIGINT),
                                      ISNULL(TRY_CAST(tT.OwnerID AS BIGINT), 0))        AS CREATE_USER,
                                  IIF(ISNUMERIC(tT.holderId) = 1, tT.holderId, NULL)    AS HANDLING_PERSON,
                                  IIF(ISNUMERIC(tT.holderId) = 0, 0, NULL)              AS HANDLING_PILOT,
                                  CAST(tT.ModifyTime AS DATETIME2)                      AS MODIFY_TIME,
                                  IIF(tT.ModifyPersonID = 'SYSTEM', CAST(0 AS BIGINT),
                                      ISNULL(TRY_CAST(tT.ModifyPersonID AS BIGINT), 0)) AS MODIFY_USER,
                                  CAST(tT.EndTime AS DATETIME2)                         AS EXPIRED_TIME,
                                  TIPL.PersonList                                       AS WATCHERS_ID,
                                  IIF(tT.isTemp = 'N', 0, 1)                            AS IS_DRAFT,
                                  IIF(tEC.EMAIL_NOTICE_FLAG > 0, 1, 0)                  AS EMAIL_NOTICE_FLAG,
                                  IIF(tT.TicketStatus = 'DELETE', 2, 1)                 AS ACTIVE_STATUS

                           FROM tblTicket tT

    OUTER APPLY (SELECT TOP 1 tTSI.Content AS Content
    FROM tblTicketSubItem tTSI
    WHERE tT.DBID = tTSI.TicketID
    ORDER BY tTSI.DBID) tTSI

    OUTER APPLY (SELECT TOP 1 tTSI.TicketContentText AS TicketContentText
    FROM tblTicketSubItem tTSI
    WHERE tT.DBID = tTSI.TicketID
    AND tTSI.ReplyType = 'Reply'
    ORDER BY tTSI.DBID) tTSI2

    OUTER APPLY (SELECT TOP 1 tTSI.ReplyType AS ReplyType
    FROM tblTicketSubItem tTSI
    WHERE tT.DBID = tTSI.TicketID
    ORDER BY tTSI.DBID) tTSI3

    OUTER APPLY (SELECT TicketID,
    '[' + STUFF(
   (SELECT ',"' + COALESCE(NULLIF(PersonID, ''), MonitorEmail) + '"'
    FROM tblTicketMonitor t2
    WHERE t1.TicketID = t2.TicketID
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')
   , 1, 1, '') + ']' AS PersonList
    FROM tblTicketMonitor t1
    WHERE tT.DBID = t1.TicketID
    GROUP BY TicketID) AS TIPL

    OUTER APPLY (SELECT TOP 1 IxnID
    FROM tblInteraction tI
    WHERE tI.TenantID = tT.tenantId
    AND tI.ContactID = tT.contactID
    AND tI.SystemID = tT.DBID
    ORDER BY StartDate DESC) AS tIII

    OUTER APPLY (SELECT TOP 1 COUNT(1) AS EMAIL_NOTICE_FLAG
    FROM tblEmailOut tEO
    WHERE tEO.IxnID = tIII.IxnID) as tEC

    LEFT JOIN #funcIDMapping fIM ON (tT.TicketTemplateID = fIM.OLD_FUNC_ID)
    LEFT JOIN #typeIDMapping tIM ON (tT.TicketCategoryID = tIM.OLD_TYPE_ID))

INSERT
INTO tblRpt_Ticket(FUNC_ID,
                   FUNC_STATUS_ID,
                   FUNC_TYPE_ID,
                   TENANT_ID,
                   CONTACT_ID,
                   CONTACT_TYPE_ID,
                   IXN_ID,
                   TICKET_SUBJECT,
                   TICKET_CONTENT,
                   TICKET_PRIORITY,
                   TICKET_MEMO,
                   TICKET_REPLY_CONTENT,
                   CREATE_TIME,
                   CREATE_USER,
                   HANDLING_PERSON,
                   HANDLING_PILOT,
                   MODIFY_TIME,
                   MODIFY_USER,
                   EXPIRED_TIME,
                   WATCHERS_ID,
                   IS_DRAFT,
                   EMAIL_NOTICE_FLAG,
                   ACTIVE_STATUS)
    OUTPUT inserted.TICKET_ID,
    OLD_TICKET_TO_NEW.TICKET_ID -- 記錄新舊PK關係
INTO #ticketIDMapping (NEW_TICKET_ID, OLD_TICKET_ID)
SELECT FUNC_ID,
       FUNC_STATUS_ID,
       FUNC_TYPE_ID,
       TENANT_ID,
       CONTACT_ID,
       CONTACT_TYPE_ID,
       IXN_ID,
       TICKET_SUBJECT,
       TICKET_CONTENT,
       TICKET_PRIORITY,
       TICKET_MEMO,
       TICKET_REPLY_CONTENT,
       CREATE_TIME,
       CREATE_USER,
       HANDLING_PERSON,
       HANDLING_PILOT,
       MODIFY_TIME,
       MODIFY_USER,
       EXPIRED_TIME,
       WATCHERS_ID,
       IS_DRAFT,
       EMAIL_NOTICE_FLAG,
       ACTIVE_STATUS
FROM OLD_TICKET_TO_NEW

/*--------------------執行新舊工單轉移結束--------------------*/

/*--------------------執行新舊工單自定義欄位轉移開始--------------------*/
CREATE TABLE #ticketFieldIDMapping
(
    OLD_TICKET_FIELD_ID INT,
    NEW_TICKET_FIELD_ID bigint
)
-- SELECT tTSI.DBID AS DBID tIM.NEW_TICKET_ID AS TICKET_ID, tTSI
--
-- FROM tblTicketSubItem tTSI
--          JOIN #ticketIDMapping tIM ON tTSI.TicketID = tIM.OLD_TICKET_ID


-- SELECT DISTINCT tblTicket.TicketStatus
-- FROM tblTicket
-- SELECT *
-- FROM tblCfg_FuncMain
-- SELECT *
-- FROM tblRpt_Ticket
-- SELECT *
-- FROM tblCfg_FuncType
-- SELECT *
-- FROM tblTicketSubItem
-- SELECT *
-- FROM tblRpt_TicketField
-- SELECT *
-- FROM tblRpt_TicketColData
-- SELECT *
-- FROM tblTicketColTitle
-- SELECT DISTINCT *
-- FROM tblCfg_FuncField
-- SELECT *
-- FROM tblCfg_SolrSearchColumn
-- SELECT *
-- FROM tblCfg_FuncFieldMapping
--
-- SELECT DISTINCT FUNC_FIELD_TYPE, SEARCH_COL_TYPE
-- FROM tblCfg_FuncField
-- WHERE LTRIM(FUNC_FIELD_TYPE) <> 'basic'
--   AND LTRIM(FUNC_FIELD_TYPE) <> 'system'