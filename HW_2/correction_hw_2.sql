/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT DeliveryMethodName, ExpectedDeliveryDate, SupplierName, ap.FullName
FROM Purchasing.Suppliers ps
JOIN Purchasing.PurchaseOrders po ON po.SupplierID = ps.SupplierID
JOIN Application.DeliveryMethods dm ON dm.DeliveryMethodID = po.DeliveryMethodID
JOIN Application.People ap ON ap.PersonID = po.ContactPersonID
WHERE po.ExpectedDeliveryDate between '2013-01-01' and  '2013-01-31'
and (dm.DeliveryMethodName = 'Air Freight' or  dm.DeliveryMethodName = 'Refrigerated Air Freight')
and IsOrderFinalized = 1
order by ExpectedDeliveryDate


/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT YEAR(si.InvoiceDate) AS InvoiceYear,
MONTH(si.InvoiceDate) InvoiceMonth,
AVG(sil.UnitPrice) AvgPriceInMonth,
SUM(sil.Quantity * sil.UnitPrice) SumPriceInMonth
FROM Sales.Invoices si
JOIN Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
WHERE si.ConfirmedDeliveryTime is not null
GROUP BY YEAR(si.InvoiceDate), MONTH(si.InvoiceDate)
order by InvoiceYear, InvoiceMonth


/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT YEAR(si.InvoiceDate) InvoiceYear,
MONTH(si.InvoiceDate) InvoiceMonth,
wsi.StockItemName,
MIN(si.InvoiceDate) FirstDate,
SUM(sil.Quantity * sil.UnitPrice) SumInvoice,
SUM(sil.Quantity) SumQuantity
FROM Sales.Invoices si
JOIN Sales.InvoiceLines sil on si.InvoiceID = sil.InvoiceID
JOIN Warehouse.StockItems wsi on wsi.StockItemID = sil.StockItemID
WHERE ConfirmedDeliveryTime is not null
GROUP BY YEAR(si.InvoiceDate), MONTH(si.InvoiceDate), wsi.StockItemName
HAVING SUM(sil.Quantity) < 50
ORDER BY StockItemName, YEAR(si.InvoiceDate), MONTH(si.InvoiceDate)