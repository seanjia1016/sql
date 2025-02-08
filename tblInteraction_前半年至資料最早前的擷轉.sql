SET NOCOUNT ON;

SELECT * INTO tblInteraction_new FROM tblInteraction WITH(NOLOCK) WHERE CONVERT(CHAR(6), StartDate, 112) >= CONVERT(CHAR(6), DATEADD(m,-6,GETDATE(), 112);

EXEC sp_rename 'tblInteraction', 'tblInteraction_old';



