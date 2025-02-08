--[EXEC]
ALTER TABLE [dbo].[tblCfg_Person]
    ADD [EmailSignature] [nvarchar](4000) NULL;
go

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Ã±¦WÀÉ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tblCfg_Person', @level2type=N'COLUMN',@level2name=N'EmailSignature'
GO

--[ROLLBACK]
-- §R°£©µ¦ùÄÝ©Ê
EXEC sys.sp_dropextendedproperty 
@name=N'MS_Description', 
@level0type=N'SCHEMA', 
@level0name=N'dbo', 
@level1type=N'TABLE',
@level1name=N'tblCfg_Person', 
@level2type=N'COLUMN',
@level2name=N'EmailSignature'
GO

-- §R°£¦C
ALTER TABLE [dbo].[tblCfg_Person]
DROP COLUMN [EmailSignature];
GO