DECLARE @StartDate DATETIME, @EndDate DATETIME

SET @StartDate = '2024-08-01 00:00:00'
SET @EndDate = '2024-08-31 23:59:59'

BEGIN
    SET NOCOUNT ON;

    ;WITH FilteredAgentStatus AS (
        SELECT DISTINCT
            tblRpt_AgentStatus.DBID,
            tblRpt_AgentStatus.AgentID,
            tblRpt_AgentStatus.Status_DBID,
            tblRpt_AgentStatus.Reason_DBID,
            tblRpt_AgentStatus.StartDatetime,
            tblRpt_AgentStatus.entityTypeID,
            tblRpt_AgentStatus.stopReason,
            tblRpt_AgentStatus.TenantID,
            tblRpt_AgentStatus.StatID,
            tblRpt_AgentStatus.Duration,
            tblRpt_AgentStatus.EndDatetime,
            tblServiceEntry.CallID,
            tblServiceEntry.EnterTime
        FROM tblRpt_AgentStatus WITH (NOLOCK)
                 LEFT JOIN tblServiceEntry WITH (NOLOCK) ON tblServiceEntry.CallID = tblRpt_AgentStatus.callID
                 JOIN tblInteraction WITH (NOLOCK) ON tblRpt_AgentStatus.callID = tblInteraction.CallID AND tblInteraction.CallID != '-1'
        WHERE tblRpt_AgentStatus.StatID IS NOT NULL
          AND tblRpt_AgentStatus.Status_DBID IS NOT NULL
          AND ISNUMERIC(tblRpt_AgentStatus.Status_DBID) != -1
          AND tblServiceEntry.EnterTime BETWEEN @StartDate AND @EndDate
          AND tblRpt_AgentStatus.TenantID = '3'
          AND tblRpt_AgentStatus.entityTypeID IN ('2')
          AND tblRpt_AgentStatus.Status_DBID IN ('7', '9')  -- 包含接通和未接通的狀態
    ),
          AgentPilotMapping AS (
              SELECT
                  f.AgentID,
                  f.CallID,
                  f.EnterTime,
                  a.Pilot,
                  p.PilotName,
                  CASE
                      WHEN f.Status_DBID = '7' THEN 1  -- 接通
                      WHEN f.Status_DBID = '9' THEN 0  -- 未接通
                      ELSE NULL
                      END AS CallStatus
              FROM FilteredAgentStatus f
                       LEFT JOIN tblCfg_Pilot_Agent a ON f.AgentID = a.AgentID AND f.TenantID = a.TenantID AND f.entityTypeID = a.EntityTypeID
                       LEFT JOIN tblCfg_Pilot p ON a.Pilot = p.Pilot AND a.TenantID = p.TenantID AND a.EntityTypeID = p.EntityTypeID
                       LEFT JOIN tblCfg_Person tcp ON tcp.DBID = a.AgentID
              WHERE tcp.STATE = 0
          )
     SELECT
         Pilot,
         PilotName,
         YEAR(EnterTime) AS Year,
         MONTH(EnterTime) AS Month,
         COUNT(CallID) AS [Total Calls],
         SUM(CASE WHEN CallStatus = 1 THEN 1 ELSE 0 END) AS [Pick Up Num],  -- 計算接通數量
         ROUND(ISNULL(SUM(CASE WHEN CallStatus = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(CallID), 0), 0), 3) AS [Pick Up %],  -- 計算接聽百分比
         SUM(CASE WHEN CallStatus = 0 THEN 1 ELSE 0 END) AS [Miss Call Num],  -- 計算未接來電數
         ROUND(ISNULL(SUM(CASE WHEN CallStatus = 0 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(CallID), 0), 0), 3) AS [Miss Call %]  -- 計算未接來電百分比
     FROM AgentPilotMapping
     GROUP BY Pilot, PilotName, YEAR(EnterTime), MONTH(EnterTime);
END