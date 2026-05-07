/*
  Update MauCauChuc for all remaining templates that still use:
  "$Gender$ $ChucVu$"
  Convert to:
  "$Gender$ $TenNV$"
*/

BEGIN TRAN;

UPDATE T
SET
  T.MauCauChuc = REPLACE(T.MauCauChuc, N'$Gender$ $ChucVu$', N'$Gender$ $TenNV$'),
    T.Editer = N'fptadmin',
    T.EditTime = GETDATE()
FROM TS_tblThietLapCauChucMungTheoChucVu AS T
WHERE T.MauCauChuc LIKE N'%$Gender$ $ChucVu%';

-- Preview rows changed in this run
SELECT
    T.ThietLapCauChucID,
    T.LSChucVuID,
    T.MauCauChuc,
    T.Editer,
    T.EditTime
FROM TS_tblThietLapCauChucMungTheoChucVu AS T
WHERE T.MauCauChuc LIKE N'%$Gender$ $TenNV%'
ORDER BY T.ThietLapCauChucID;

-- Remaining rows not fixed (should return 0 rows)
SELECT
  T.ThietLapCauChucID,
  T.LSChucVuID,
  T.MauCauChuc
FROM TS_tblThietLapCauChucMungTheoChucVu AS T
WHERE T.MauCauChuc LIKE N'%$Gender$ $ChucVu%'
ORDER BY T.ThietLapCauChucID;

-- COMMIT;
ROLLBACK;

/*
  How to run:
  1) Run script once to review with ROLLBACK.
  2) If OK, replace ROLLBACK with COMMIT and run again.
*/
