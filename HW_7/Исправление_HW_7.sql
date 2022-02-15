SELECT * FROM (
SELECT
si.StockItemID,
si.StockItemName,
t.value as tag
FROM Warehouse.StockItems si
CROSS APPLY OPENJSON(si.CustomFields,'$.Tags') as t
) as tab
WHERE tab.tag = 'Vintage'

SELECT DISTINCT sti2.StockItemID, sti2.StockItemName,
    SUBSTRING(
        (
            SELECT ',' + t.value  AS [text()]
            FROM Warehouse.StockItems sti1
			CROSS APPLY OPENJSON(sti1.CustomFields,'$.Tags') as t
            WHERE sti1.StockItemID = sti2.StockItemID
            ORDER BY sti1.StockItemID
            FOR XML PATH ('')
        ), 2, 1000) [Tags]
FROM Warehouse.StockItems sti2
WHERE sti2.StockItemID in (64, 65, 73, 74)