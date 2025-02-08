SET NOCOUNT ON

DECLARE @startServiceTime DATETIME
DECLARE @endServiceTime DATETIME
DECLARE @duration INT

--服務中
SELECT @startServiceTime = StartDatetime FROM tblRpt_AgentStatus WHERE callID='A2024101400333276' and Status_DBID= 7

--文字處理
SELECT @endServiceTime = StartDatetime FROM tblRpt_AgentStatus WHERE callID='A2024101400333276' and Status_DBID= 5

--兩筆動作的時間差(秒)
SELECT @duration = DATEDIFF(S,@startServiceTime,@endServiceTime)

--校正資料
UPDATE tblRpt_AgentStatus SET Duration = @duration WHERE callID='A2024101400333276' and Status_DBID= 7