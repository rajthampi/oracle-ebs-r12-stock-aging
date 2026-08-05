--Author: Rajesh Thampi
--
--
--CASE #2 When you don't have the privileges to create custom objects
--Please note, based on the volume of data, this approach could seriously compromise the performance for your LIVE/PRODUCTION
--Consider running this only when least transactions are expected.

WITH receipt_data AS (
    SELECT 
        mmt.organization_id, 
        mmt.transaction_date,
        mmt.inventory_item_id,
        mmt.transaction_quantity
        FROM mtl_material_transactions mmt
        where 
        1=1
        AND ORGANIZATION_ID IN (:p_org_id, :l_warehouse_orgid)
        AND mmt.inventory_item_id IN (Select DISTINCT inventory_item_id 
        from mtl_onhand_quantities_detail where organization_id IN (:p_org_id, :l_warehouse_orgid))
        AND mmt.transaction_type_id in (12,15,18,40,41,42) 
        --adjust the transaction_type_id specific to your reporting requirements
        --avoid sub-inventory-transfers and move orders which logical transfers
  ),
on_hand AS (
    -- Input parameters: item_id and current stock on hand
        SELECT 
        moq.inventory_item_id, SUM(moq.transaction_quantity) AS current_on_hand
        FROM mtl_onhand_quantities_detail moq
        WHERE moq.organization_id IN (:p_org_id, :l_warehouse_orgid)
        GROUP by moq.inventory_item_id
 ),
running_totals AS (
    SELECT 
    r.organization_id, r.transaction_date,r.inventory_item_id,r.transaction_quantity,h.current_on_hand,
        -- Running cumulative sum of receipts ordered from NEWEST to OLDEST
        SUM(r.transaction_quantity) OVER (PARTITION BY r.inventory_item_id ORDER BY r.transaction_date DESC) AS cum_qty,
        -- Cumulative total PRIOR to the current receipt
        NVL(SUM(r.transaction_quantity) OVER (PARTITION BY r.inventory_item_id ORDER BY r.transaction_date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0) AS prev_cum_qty
    FROM receipt_data r 
    JOIN on_hand h ON r.inventory_item_id = h.inventory_item_id 
),
allocated_stock AS (
    SELECT 
    organization_id,
        transaction_date,
        inventory_item_id,
        transaction_quantity,
        -- Calculate remaining quantity from this receipt
        LEAST(
            transaction_quantity, 
            GREATEST(0, current_on_hand - prev_cum_qty)
        ) AS remaining_qty,
        -- Calculate days aged relative to current date (TRUNC(SYSDATE))
        TRUNC(SYSDATE) - TRUNC(transaction_date) AS age_in_days
    FROM running_totals
    WHERE current_on_hand - prev_cum_qty > 0 -- Exclude receipts with 0 remaining stock
)
--Bottom most query
--Uncomment for master items table hook-up for code, description etc
--SELECT 
--ad.organization_id,
--ad.inventory_item_id,
--msi.segment1||'.'||msi.segment2 item_code,
--msi.description,
--msi.primary_uom_code uom,
--ad.onhand_qty,
--ad.BUCKET1,
--ad.BUCKET2,
--ad.BUCKET3,
--ad.BUCKET4,
--ad.BUCKET5,
--ad.BUCKET6,
--ad.BUCKET7 from (
SELECT 
CASE WHEN organization_id IN (110,245) then 110 else organization_id END organization_id,
inventory_item_id,
SUM(nvl(remaining_qty,0)) as onhand_qty,
SUM(CASE WHEN age_in_days <= 120 THEN remaining_qty else 0 END) BUCKET1,
SUM(CASE WHEN age_in_days BETWEEN 121 and  180 THEN remaining_qty else 0 END) BUCKET2,
SUM(CASE WHEN age_in_days BETWEEN 181 and 365 THEN remaining_qty else 0 END) BUCKET3,
SUM(CASE WHEN age_in_days BETWEEN 366 and 730 THEN remaining_qty else 0 END) BUCKET4,
SUM(CASE WHEN age_in_days BETWEEN 731 and 1095 THEN remaining_qty else 0 END) BUCKET5,
SUM(CASE WHEN age_in_days BETWEEN 1096 and 1825 THEN remaining_qty else 0 END) BUCKET6,
SUM(CASE WHEN age_in_days > 1825 THEN remaining_qty else 0 END) BUCKET7
FROM allocated_stock 
where 
1=1
GROUP BY CASE WHEN organization_id IN (110,245) then 110 else organization_id END,
inventory_item_id
--) ad
--JOIN MTL_SYSTEM_ITEMS msi on ad.inventory_item_id=msi.inventory_item_id and msi.organization_id=123 --master inventory organization
--ORDER BY msi.segment1
/	  

