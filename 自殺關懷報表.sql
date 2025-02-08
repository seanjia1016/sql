SET NOCOUNT ON;

BEGIN

    BEGIN TRY DROP TABLE #treatmentMappingList END TRY BEGIN CATCH END CATCH

    BEGIN TRY DROP TABLE #treatmentCountMap END TRY BEGIN CATCH END CATCH

    BEGIN TRY DROP TABLE #recordList END TRY BEGIN CATCH END CATCH

    BEGIN TRY DROP TABLE #TempMap END TRY BEGIN CATCH END CATCH

--#treatmentMappingList
    SELECT CCRATM.*
    INTO #treatmentMappingList
    FROM CUS_CALL_RECORD_AND_TREATMENT_MAPPING CCRATM WITH (NOLOCK)
             INNER JOIN CUS_CALL_RECORD CCR ON CCR.SKEY = CCRATM.CALL_RECORD_ID
    WHERE CCR.START_DATETIME BETWEEN CONVERT(DATE, CONVERT(VARCHAR, :startDate), 101) AND CONVERT(DATE, CONVERT(VARCHAR, :endDate), 101)
      AND CCRATM.TREATMENT_ID NOT IN ('1099', '2099', '3099')

--@TotalTreatmentCount
    DECLARE
        @TotalTreatmentCount INT;
    SELECT @TotalTreatmentCount = COUNT(1)
    FROM #treatmentMappingList;

    CREATE TABLE #treatmentCountMap
    (
        TREATMENT NVARCHAR(255) COLLATE DATABASE_DEFAULT,
        COUNT     INT
    );

-- #treatmentCountMap

    INSERT INTO #treatmentCountMap (TREATMENT, COUNT)
    SELECT CASE t.TREATMENT_ID
               WHEN '1001' THEN '一般輔導'
               WHEN '1002' THEN '自殺評估'
               WHEN '1003' THEN '危機介入'
               WHEN '1004' THEN '自殺通報'
               WHEN '1005' THEN '提供心理輔導單位資訊'
               WHEN '1006' THEN '提供醫療衛生單位資訊'
               WHEN '1007' THEN '提供社福單位資訊'
               WHEN '1008' THEN '提供就業輔導單位資訊'
               WHEN '1009' THEN '提供其他資源訊息'
               WHEN '1010' THEN '通知專職人員安排面談'
               WHEN '1011' THEN '建議中心建檔'
               WHEN '1012' THEN '建議中心追蹤'
               WHEN '1013' THEN '新增資料'
               WHEN '1014' THEN '其他'
               WHEN '1015' THEN '通知專職人員評估安排轉介其他單位'
               END AS 'TREATMENT',
           COUNT(1)
    FROM #treatmentMappingList t
    GROUP BY TREATMENT_ID


--@isCrisisCount
    DECLARE
        @isCrisisCount INT
    SELECT @isCrisisCount = COUNT(1)
    FROM #treatmentMappingList t
    WHERE t.TREATMENT_ID = '3'

--#recordList
    SELECT [SKEY],
           [CASE_NUMBER],
           [START_DATETIME],
           [HANDLE_DEPT_ID],
           [AGENT_NAME],
           [SEAT_ID],
           [END_DATETIME],
           [WORK_SHIFT_ID],
           [CASE_PERSON_NAME],
           CUS_CALL_RECORD.[CASE_PHONE_NUMBER],
           [AGE_ID],
           [SEX_ID],
           [MONITOR_CASE_ID],
           [SERVICE_TARGET_ID],
           [SUICIDE_INTENT_ID],
           [SUICIDE_RISK_ID],
           [LOCATION_ID],
           [MEDICAL_HIS_ID],
           [CONSULT_ID],
           [CASE_NOTE],
           [CALL_ID],
           [CREATE_DATETIME],
           [AGENT_ID],
           [BSRS5_TOTAL],
           [SOURCE_TYPE],
           ''      AS [TREATMENT_HTML],
           CASE
               WHEN CASE_PHONE_NUMBER_COUNT = 1 THEN 0
               ELSE 1
               END AS [FIRST_CALL_IN]
    INTO #recordList
    FROM CUS_CALL_RECORD WITH (NOLOCK)
             JOIN (SELECT CCR.CASE_PHONE_NUMBER AS CASE_PHONE_NUMBER, COUNT(1) AS CASE_PHONE_NUMBER_COUNT
                   FROM CUS_CALL_RECORD CCR WITH (NOLOCK)
                   WHERE START_DATETIME BETWEEN CONVERT(DATE, CONVERT(VARCHAR, :startDate), 101) AND CONVERT(DATE, CONVERT(VARCHAR, :endDate), 101)
                   GROUP BY CCR.CASE_PHONE_NUMBER) AS CUS_CALL_RECORD_2
                  ON (CUS_CALL_RECORD.CASE_PHONE_NUMBER = CUS_CALL_RECORD_2.CASE_PHONE_NUMBER)
    WHERE START_DATETIME BETWEEN CONVERT(DATE, CONVERT(VARCHAR, :startDate), 101) AND CONVERT(DATE, CONVERT(VARCHAR, :endDate), 101)

    BEGIN
        --@totalCalls_count
        DECLARE
            @totalCalls_count INT
        SELECT @totalCalls_count = COUNT(1)
        FROM #recordList

--@effective_count
        DECLARE
            @effective_count INT
        SELECT @effective_count = @totalCalls_count

--@suicideIntent_count
        DECLARE
            @suicideIntent_count INT
        SELECT @suicideIntent_count = 0

--@activeSuicide_count
        DECLARE
            @activeSuicide_count INT
        SELECT @activeSuicide_count = 0

--@callInAgainCount
        DECLARE
            @callInAgainCount INT
        SELECT @callInAgainCount = 0

--@firstCallInCount
        DECLARE
            @firstCallInCount INT
        SELECT @firstCallInCount = 0
    END

    BEGIN

        CREATE TABLE #TempMap
        (
            MapName NVARCHAR(255),
            map_key NVARCHAR(255),
            value   INT
        )

    END

    BEGIN
        DECLARE
            TREATMENT_MAPPING CURSOR FOR
                (
                    SELECT CASE WHEN t.CONSULT_ID <> 25 THEN 0 ELSE 1 END                   AS isEffective,
                           t.FIRST_CALL_IN                                                 AS FirstCallIn,
                           CASE WHEN t.SUICIDE_INTENT_ID IN ('1001', '1002', '1003', '1004') THEN 0 ELSE 1 END AS isSuicideIntent,
                           CASE WHEN t.SUICIDE_INTENT_ID IN ('1004') THEN 0 ELSE 1 END          AS isActiveSuicide,
                           CASE WHEN t.SEX_ID = '1001' THEN 0 ELSE 1 END                        AS isMale,
                           CASE WHEN t.SEX_ID = '1000' THEN 0 ELSE 1 END                        AS isFemale,
                           CASE t.AGE_ID
                               WHEN '1001' THEN 'below14'
                               WHEN '1002' THEN '15to24'
                               WHEN '1003' THEN '24to44'
                               WHEN '1004' THEN '45to64'
                               WHEN '1005' THEN '65up'
                               WHEN '1006' THEN 'unknown'
                               END                                                         as AGE_INTERVAL,
                           CASE t.WORK_SHIFT_ID
                               WHEN '1001' THEN '7to11'
                               WHEN '1002' THEN '11to15'
                               WHEN '1003' THEN '23to7'
                               END                                                         as WORKSHIFT_INTERVAL,
                           t.SKEY                                                          AS SKEY,
                           CASE t.SERVICE_TARGET_ID
                               WHEN '1000' THEN 'self'
                               WHEN '1001' THEN 'familyMember'
                               WHEN '1002' THEN 'friend'
                               WHEN '1003' THEN 'other'
                               WHEN '1004' THEN 'unknown'
                               END                                                         AS ServiceTargetDescription,
                           CASE t.CONSULT_ID
                               WHEN '1001' THEN '夫妻問題'
                               WHEN '1002' THEN '家庭成員問題'
                               WHEN '1003' THEN '感情因素(如男女朋友)'
                               WHEN '1004' THEN '重要親友亡故'
                               WHEN '1005' THEN '憂鬱傾向、罹患憂鬱症或其他精神疾病'
                               WHEN '1006' THEN '物質濫用(酒、藥、毒品)'
                               WHEN '1007' THEN '職場工作壓力'
                               WHEN '1008' THEN '失業'
                               WHEN '1009' THEN '債務'
                               WHEN '1010' THEN '慢性化的疾病問題'
                               WHEN '1011' THEN '急性化的疾病問題'
                               WHEN '1012' THEN '學校適應問題(如課業壓力、體罰、霸凌等)'
                               WHEN '1013' THEN '生涯規劃因素'
                               WHEN '1014' THEN '遭受騷擾'
                               WHEN '1015' THEN '遭受暴力'
                               WHEN '1016' THEN '遭受詐騙'
                               WHEN '1017' THEN '兵役因素'
                               WHEN '1018' THEN '畏罪自殺、官司問題'
                               WHEN '1019' THEN '社會抱怨'
                               WHEN '1020' THEN '資料查詢'
                               WHEN '1025' THEN '自殺通報'
                               WHEN '1026' THEN '其他人際關係'
                               WHEN '1027' THEN '經濟困難'
                               WHEN '1028' THEN '其他'
                               END

                               AS ConsultDescription
                    FROM #recordList t WITH (NOLOCK))

        OPEN TREATMENT_MAPPING
        BEGIN
            DECLARE
                @isEffective BIT;
            DECLARE
                @FirstCallIn BIT;
            DECLARE
                @isSuicideIntent BIT;
            DECLARE
                @isActiveSuicide BIT;
            DECLARE
                @isMale BIT;
            DECLARE
                @isFemale BIT;
            DECLARE
                @AGE_INTERVAL NVARCHAR(255);
            DECLARE
                @WORKSHIFT_INTERVAL NVARCHAR(255);
            DECLARE
                @sKey int;
            DECLARE
                @ServiceTargetDescription NVARCHAR(255);
            DECLARE
                @ConsultDescription NVARCHAR(255);
        END


        FETCH NEXT FROM TREATMENT_MAPPING INTO @isEffective,@FirstCallIn,@isSuicideIntent,@isActiveSuicide,@isMale,@isFemale,@AGE_INTERVAL,@WORKSHIFT_INTERVAL,@sKey,@ServiceTargetDescription,@ConsultDescription
        WHILE @@FETCH_STATUS = 0
            BEGIN

                IF
                    @isEffective = 1
                    BEGIN
                        SET
                            @effective_count = @effective_count - 1;
                        CONTINUE
                    END

                IF
                    @FirstCallIn IS NULL
                    BEGIN
                        SET
                            @effective_count = @effective_count - 1;
                        PRINT
                            N'異常資料：沒有是否初次進線欄位，callRecordId:' + @sKey;
                        CONTINUE
                    END

                IF
                    @FirstCallIn = 0
                    BEGIN
                        SET
                            @firstCallInCount = @firstCallInCount + 1;
                    END
                ELSE
                    BEGIN
                        SET
                            @callInAgainCount = @callInAgainCount + 1;
                    END

                IF
                    @isSuicideIntent = 0
                    BEGIN
                        SET
                            @suicideIntent_count = @suicideIntent_count + 1;
                    END

                IF
                    @isActiveSuicide = 0
                    BEGIN
                        SET
                            @activeSuicide_count = @activeSuicide_count + 1;
                    end

                IF
                    @isMale = 0
                    BEGIN
                        INSERT INTO #TempMap
                        SELECT 'genderCountMap', 'male', 1
                    end
                ELSE
                    IF @isFemale = 0
                        BEGIN
                            INSERT INTO #TempMap
                            SELECT 'genderCountMap', 'female', 1
                        end
                    ELSE
                        BEGIN
                            INSERT INTO #TempMap
                            SELECT 'genderCountMap', 'unknown', 1
                        end

                IF
                    @AGE_INTERVAL IS NOT NULL
                    BEGIN
                        INSERT INTO #TempMap
                        SELECT 'ageCountMap', @AGE_INTERVAL, 1
                    END

                IF
                    @WORKSHIFT_INTERVAL IS NOT NULL
                    BEGIN
                        INSERT INTO #TempMap
                        SELECT 'workShiftCountMap', @WORKSHIFT_INTERVAL, 1
                    END

                IF
                    @isMale = 0
                    BEGIN
                        INSERT INTO #TempMap
                        SELECT 'commonConsultMap',
                               @ConsultDescription,
                               1
                        INSERT
                        INTO #TempMap
                        SELECT 'maleConsultMap', @ConsultDescription, 1
                    END
                ELSE
                    IF @isFemale = 0
                        BEGIN
                            INSERT INTO #TempMap
                            SELECT 'commonConsultMap',
                                   @ConsultDescription,
                                   1
                            INSERT
                            INTO #TempMap
                            SELECT 'femaleConsultMap', @ConsultDescription, 1
                        END
                    ELSE
                        BEGIN
                            INSERT INTO #TempMap
                            SELECT 'commonConsultMap',
                                   @ConsultDescription,
                                   1
                            INSERT
                            INTO #TempMap
                            SELECT 'unknownConsultMap', @ConsultDescription, 1
                        END

                IF
                    @isSuicideIntent = 0
                    BEGIN
                        IF
                            @ServiceTargetDescription IS NOT NULL
                            BEGIN
                                INSERT INTO #TempMap
                                SELECT 'suicide_serviceTargetCountMap', @ServiceTargetDescription, 1
                            END

                        INSERT INTO #TempMap
                        SELECT 'suicide_workShiftCountMap',
                               @WORKSHIFT_INTERVAL,
                               1
                        INSERT
                        INTO #TempMap
                        SELECT 'suicide_ageCountMap',
                               @AGE_INTERVAL,
                               1
                        IF @isMale = 0
                            BEGIN
                                INSERT INTO #TempMap
                                SELECT 'suicide_genderCountMap', 'male', 1
                            END
                        ELSE
                            IF @isFemale = 0
                                BEGIN
                                    INSERT INTO #TempMap
                                    SELECT 'suicide_genderCountMap', 'female', 1
                                END
                            ELSE
                                BEGIN
                                    INSERT INTO #TempMap
                                    SELECT 'suicide_genderCountMap', 'unknown', 1
                                END

                    END

                FETCH NEXT FROM TREATMENT_MAPPING INTO @isEffective,@FirstCallIn,@isSuicideIntent,@isActiveSuicide,@isMale,@isFemale,@AGE_INTERVAL,@WORKSHIFT_INTERVAL,@sKey,@ServiceTargetDescription,@ConsultDescription
            END
        CLOSE TREATMENT_MAPPING DEALLOCATE TREATMENT_MAPPING

        DECLARE
            @ineffectiveService INT;
        SET
            @ineffectiveService = @totalCalls_count - @effective_count;

        SELECT @ineffectiveService    AS ineffectiveService,
               @effective_count       AS effective_count,
               @firstCallInCount      AS firstCallInCount,
               @callInAgainCount      AS callInAgainCount,
               @suicideIntent_count   AS suicideIntent_count,
               @activeSuicide_count   AS activeSuicide_count,
               (SELECT t.map_key AS [key], sum(t.value) AS [value]
                FROM #TempMap t WITH (NOLOCK)
                WHERE t.MapName = 'genderCountMap'
                GROUP BY t.map_key
                FOR XML PATH ('row')) AS GenderCountMap,
               (SELECT t.map_key AS [key], sum(t.value) AS [value]
                FROM #TempMap t WITH (NOLOCK)
                WHERE t.MapName = 'ageCountMap'
                GROUP BY t.map_key
                FOR XML PATH ('row')) AS AgeCountMap,
               (SELECT t.map_key , sum(t.value)
                FROM #TempMap t WITH (NOLOCK)
                WHERE t.MapName = 'workShiftCountMap'
                GROUP BY t.map_key
                FOR XML PATH ('row')) AS workShiftCountMap,
               (SELECT t.map_key AS [key], sum(t.value) AS [value]
                FROM #TempMap t WITH (NOLOCK)
                WHERE t.MapName = 'commonConsultMap'
                GROUP BY t.map_key
                FOR XML PATH ('row')) AS CommonConsultMap,
               (SELECT t.map_key AS [key], sum(t.value) AS [value]
                FROM #TempMap t WITH (NOLOCK)
                WHERE t.MapName = 'maleConsultMap'
                GROUP BY t.map_key
                FOR XML PATH ('row')) AS MaleConsultMap,
               (SELECT t.map_key AS [key], sum(t.value) AS [value]
                FROM #TempMap t WITH (NOLOCK)
                WHERE t.MapName = 'femaleConsultMap'
                GROUP BY t.map_key
                FOR XML PATH ('row')) AS FemaleConsultMap,
               (SELECT t.map_key AS [key], sum(t.value) AS [value]
                FROM #TempMap t WITH (NOLOCK)
                WHERE t.MapName = 'unknownConsultMap'
                GROUP BY t.map_key
                FOR XML PATH ('row')) AS UnknownConsultMap,
               (SELECT t.map_key AS [key], sum(t.value) AS [value]
                FROM #TempMap t WITH (NOLOCK)
                WHERE t.MapName = 'suicide_serviceTargetCountMap'
                GROUP BY t.map_key
                FOR XML PATH ('row')) AS Suicide_serviceTargetCountMap,
               (SELECT t.map_key AS [key], sum(t.value) AS [value]
                FROM #TempMap t WITH (NOLOCK)
                WHERE t.MapName = 'suicide_workShiftCountMap'
                GROUP BY t.map_key
                FOR XML PATH ('row')) AS Suicide_workShiftCountMap,
               (SELECT t.map_key AS [key], sum(t.value) AS [value]
                FROM #TempMap t WITH (NOLOCK)
                WHERE t.MapName = 'suicide_ageCountMap'
                GROUP BY t.map_key
                FOR XML PATH ('row')) AS Suicide_ageCountMap,
               (SELECT t.map_key AS [key], sum(t.value) AS [value]
                FROM #TempMap t WITH (NOLOCK)
                WHERE t.MapName = 'suicide_genderCountMap'
                GROUP BY t.map_key
                FOR XML PATH ('row')) AS Suicide_genderCountMap

    END

END

