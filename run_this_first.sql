--Author: Rajesh Thampi
--Materialized view for receipts until sysdate -1
--Adjust transaction_type_id as per your setup

CREATE OR REPLACE VIEW OMS_AGING_RECEIPTS_MV# AS
SELECT 
       mmt.organization_id, 
       mmt.transaction_date AS receipt_date,
       mmt.inventory_item_id,
       mmt.transaction_quantity
    FROM mtl_material_transactions mmt
     WHERE 
    1=1
      AND transaction_type_id IN (12, 15, 18, 40, 41, 42)
      AND TRUNC(TRANSACTION_DATE) < TRUNC(SYSDATE)
/

BEGIN
ad_zd_mview.upgrade('APPS','OMS_AGING_RECEIPTS_MV');
END;
/

--Refresh the MV everyday once during off hours.
--We work from 7AM-8PM everyday and a concurrent program is scheduled to refresh all MVs around 6AM everyday

BEGIN
DBMS_MVIEW.REFRESH ('OMS_AGING_RECEIPTS_MV');
END;
/

--Global temporary tables for hosting receipts and onhand quantities
--This approach dramatically improves the query performance
--Receipts GTT
CREATE GLOBAL TEMPORARY TABLE XXAGEING_RCPTS_GTT (
    organization_id    NUMBER,
    transaction_date DATE,
    inventory_item_id NUMBER,
    transaction_quantity      NUMBER
) ON COMMIT DELETE ROWS
/
--on-hand quantities GTT
CREATE GLOBAL TEMPORARY TABLE XXAGEING_OHQTY_GTT (
--    organization_id    NUMBER, --not mandatory for the current requirement
    inventory_item_id NUMBER,
    current_on_hand      NUMBER
) ON COMMIT DELETE ROWS
/
