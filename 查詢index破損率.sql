SELECT
    dbo.tblCfg_ActivityMenu.DBID,
    dbo.tblCfg_ActivityMenu.MenuName,
    dbo.tblCfg_ActivityMenu.DeleteFlag,
    dbo.tblCfg_ActivityMenu.DeleteDATETIME,
    dbo.tblCfg_ActivityMenu.CreateDATETIME,
    dbo.tblCfg_ActivityMenu.Sort,
    dbo.tblCfg_ActivityMenu.TenantID,
    dbo.tblCfg_ActivityMenu.EntityTypeID
FROM dbo.tblCfg_ActivityMenu_Pilot WITH(NOLOCK)
         INNER JOIN dbo.tblCfg_ActivityMenu
                    ON dbo.tblCfg_ActivityMenu_Pilot.activityMenuID = dbo.tblCfg_ActivityMenu.DBID
WHERE
    dbo.tblCfg_ActivityMenu_Pilot.pilotID IN (
        SELECT Pilot
        FROM tblCfg_Pilot WITH(NOLOCK)
        WHERE Pilot = 3339
           OR Pilot IN (
            SELECT ReferencePilotID
            FROM tblCfg_Pilot WITH(NOLOCK)
            WHERE Pilot = 3339
        )
    )
  AND dbo.tblCfg_ActivityMenu.DeleteFlag = 0