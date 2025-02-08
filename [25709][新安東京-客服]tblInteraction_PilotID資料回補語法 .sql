-- 步驟1：先查詢總共有幾筆需要回補

/******此處開始選取*******/
select count(1)
from tblInteraction i
         join tblVoiceQueueHistory v on i.CallID = v.UniqueKey
where (i.PilotID is null or len(i.PilotID) = 0)
  and (v.PilotName is not null and len(v.PilotName) <> 0)
/******此處結束選取*******/

-----------------------------------------------------------------------------------------------------------------

-- 步驟2：執行回補語法，
-- 參數 (控制回補的時間區間)
-- :開始時間　Interaction表創建時間  開始時間
-- :結束時間　Interaction表創建時間  結束時間　
-- 兩者格式均為 yyyyMMdd ex:20240101


/******此處開始選取*******/
SET NOCOUNT ON

DECLARE @sTime DATE;
DECLARE @eTime DATE;

--如不需要時間區間過濾，下列兩行可以註解
--直接把下列時間替換成要控制的時間區間即可
SET @sTime = CONVERT(CHAR(8), 20200101 , 112); --開始時間
SET @eTime = CONVERT(CHAR(8), 20221231 , 112); --結束時間

BEGIN

    UPDATE i
    SET i.PilotID = v.PilotName
    FROM tblInteraction i
    JOIN tblVoiceQueueHistory v
    ON i.CallID = v.UniqueKey
    WHERE (i.PilotID IS NULL OR LEN(i.PilotID) = 0)
          AND (v.PilotName IS NOT NULL AND LEN(v.PilotName) <> 0)
           --如不需要時間區間過濾，下列此行可以註解
          AND CONVERT(CHAR(8), i.CreateDate, 112) BETWEEN @sTime AND @eTime

    --確認更新行數
    SELECT @@ROWCOUNT AS UpdatedRowsCount;

END
/******此處結束選取*******/
