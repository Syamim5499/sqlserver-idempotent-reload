IF SCHEMA_ID('portfolio_reload') IS NULL EXEC('CREATE SCHEMA portfolio_reload');
DROP PROCEDURE IF EXISTS portfolio_reload.reload_batch;
DROP TABLE IF EXISTS portfolio_reload.reload_audit;
DROP TABLE IF EXISTS portfolio_reload.target_item;
DROP TABLE IF EXISTS portfolio_reload.stage_item;
CREATE TABLE portfolio_reload.stage_item (
  batch_id int NOT NULL, source_id varchar(20) NOT NULL, amount decimal(12,2) NOT NULL
);
CREATE TABLE portfolio_reload.target_item (
  batch_id int NOT NULL, source_id varchar(20) NOT NULL, amount decimal(12,2) NOT NULL,
  CONSTRAINT PK_portfolio_reload_target PRIMARY KEY(batch_id,source_id)
);
CREATE TABLE portfolio_reload.reload_audit (
  audit_id int IDENTITY PRIMARY KEY, batch_id int NOT NULL, deleted_rows int NOT NULL,
  inserted_rows int NOT NULL, completed_at datetime2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
CREATE PROCEDURE portfolio_reload.reload_batch @batch_id int AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;
  DECLARE @deleted int, @inserted int;
  BEGIN TRY
    BEGIN TRAN;
    IF EXISTS (SELECT 1 FROM portfolio_reload.stage_item WHERE batch_id=@batch_id
               GROUP BY source_id HAVING COUNT(*)>1)
      THROW 51000, 'Duplicate source_id in batch', 1;
    DELETE FROM portfolio_reload.target_item WHERE batch_id=@batch_id;
    SET @deleted=@@ROWCOUNT;
    INSERT portfolio_reload.target_item(batch_id,source_id,amount)
      SELECT batch_id,source_id,amount FROM portfolio_reload.stage_item WHERE batch_id=@batch_id;
    SET @inserted=@@ROWCOUNT;
    INSERT portfolio_reload.reload_audit(batch_id,deleted_rows,inserted_rows)
      VALUES(@batch_id,@deleted,@inserted);
    COMMIT;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
  END CATCH
END;
GO
INSERT portfolio_reload.stage_item VALUES (101,'A',10),(101,'B',20),(101,'C',30);
INSERT portfolio_reload.target_item VALUES (100,'OLDER',5);
EXEC portfolio_reload.reload_batch 101;
EXEC portfolio_reload.reload_batch 101;
SELECT batch_id, COUNT(*) AS rows_loaded, SUM(amount) AS total_amount
FROM portfolio_reload.target_item GROUP BY batch_id ORDER BY batch_id;
SELECT batch_id,deleted_rows,inserted_rows FROM portfolio_reload.reload_audit ORDER BY audit_id;
