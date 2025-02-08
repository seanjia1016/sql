--[EXEC]
UPDATE tblCfg_Application
SET Value = '影像資料比對項目異常，下方通話筆數無法正確對應影像檔案，請儘速確認。;callid = @callId. 開始通話時間：@startTime. 接聽人員：@agentName. 申請結果:@verifyResult  '
WHERE TenantID = 3 AND Parameter='lostContent' AND Application='video' AND Setion='videoFileWarningEmail'

--[ROLLBACK]
UPDATE tblCfg_Application
SET Value = '影像資料比對項目異常，下方通話筆數無法正確對應影像檔案，請儘速確認。;callid = @callId. 開始通話時間：@startTime. 接聽人員：@agentName  '
WHERE TenantID = 3 AND Parameter='lostContent' AND Application='video' AND Setion='videoFileWarningEmail'