CREATE TABLE dbo.OperationLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ExecutionTime DATETIME DEFAULT GETDATE(),
    TableName NVARCHAR(255),
    Action NVARCHAR(50),
    RowsInserted INT,
    RowsDeleted INT,
    Result NVARCHAR(50),
    ErrorMessage NVARCHAR(MAX) NULL
);

EXEC sp_addextendedproperty 'MS_Description', N'紀錄AgentStatus_每月擷轉的log表', 'SCHEMA', 'dbo', 'TABLE', 'tblAddressBook'
go
