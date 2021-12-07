/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName
FROM Warehouse.StockItems
WHERE StockItemName like '%urgent%' or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT ps.SupplierID, ps.SupplierName from Purchasing.Suppliers ps
LEFT JOIN Purchasing.PurchaseOrders pp on pp.SupplierID = ps.SupplierID
WHERE pp.PurchaseOrderID is null
/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT so.OrderID, CONVERT(NVARCHAR, OrderDate, 104) OrderDate, DATENAME(month, OrderDate) OrderMonth, 
DATEPART(quarter, OrderDate) OrderQuarter, 
(case 
when MONTH(OrderDate) between 1 and 4 then 1 
when MONTH(OrderDate) between 5 and 8 then 2
when MONTH(OrderDate) between 9 and 12 then 3
else 0 end) OrderThirdOfTheYear, sc.CustomerName
FROM Sales.Orders so 
JOIN Sales.OrderLines sol on sol.OrderID = so.OrderID
JOIN Sales.Customers sc on sc.CustomerID = so.CustomerID
WHERE (sol.UnitPrice > 100 or sol.Quantity > 20) and so.PickingCompletedWhen is not NULL
ORDER BY OrderQuarter, OrderThirdOfTheYear, OrderDate
-- Опционально
OFFSET 1000 ROWS 
FETCH NEXT 100 ROWS ONLY;


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
WHERE po.ExpectedDeliveryDate between convert(date, '2013-01-01') and convert(date, '2013-02-01')
and (dm.DeliveryMethodName = 'Air Freight' or  dm.DeliveryMethodName = 'Refrigerated Air Freight')
and IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP(10) so.OrderID, so.OrderDate, sc.CustomerName, ap.FullName from Sales.Orders so
JOIN Sales.Customers sc on sc.CustomerID = so.CustomerID
JOIN Application.People ap on ap.PersonID = SalespersonPersonID
ORDER BY OrderDate desc


/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT sc.CustomerID, sc.CustomerName, sc.PhoneNumber FROM Sales.Invoices si
JOIN Sales.Customers sc ON sc.CustomerID = si.CustomerID
JOIN Sales.InvoiceLines sil on si.InvoiceID = sil.InvoiceID
JOIN Warehouse.StockItems wsi on wsi.StockItemID = sil.StockItemID
WHERE StockItemName = 'Chocolate frogs 250g'
ORDER BY CustomerID

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT si.InvoiceDate, 
YEAR(si.InvoiceDate) OrderYear, 
MONTH(si.InvoiceDate) OrderMonth, 
AVG(sil.UnitPrice) over (partition by MONTH(si.InvoiceDate)) AvgPriceInMonth,
SUM(sil.Quantity * sil.UnitPrice) over (partition by MONTH(si.InvoiceDate)) SumPriceInMonth
FROM Sales.Invoices si
JOIN Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
WHERE si.ConfirmedDeliveryTime is not null

 
/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT YEAR(si.InvoiceDate) InvoiceYear, MONTH(si.InvoiceDate) InvoiceMonth,
SUM(sil.Quantity * sil.UnitPrice) SumPrice
FROM Sales.Invoices si
JOIN Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
WHERE si.ConfirmedDeliveryTime is not null 
GROUP BY YEAR(si.InvoiceDate), MONTH(si.InvoiceDate)
HAVING SUM(sil.Quantity * sil.UnitPrice) > 10000
ORDER BY InvoiceYear, InvoiceMonth


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

SELECT distinct InvoiceYear, InvoiceMonth, StockItemName, FirstDate, SumInvoice, SumQuantity FROM (
SELECT si.InvoiceDate,
YEAR(si.InvoiceDate) InvoiceYear,
MONTH(si.InvoiceDate) InvoiceMonth, wsi.StockItemName,
FIRST_VALUE(si.InvoiceDate) OVER (ORDER BY YEAR(si.InvoiceDate), MONTH(si.InvoiceDate), wsi.StockItemName) FirstDate,
SUM(sil.Quantity * sil.UnitPrice) OVER (PARTITION BY YEAR(si.InvoiceDate), MONTH(si.InvoiceDate), wsi.StockItemName) SumInvoice,
SUM(sil.Quantity) OVER (PARTITION BY YEAR(si.InvoiceDate), MONTH(si.InvoiceDate), wsi.StockItemName) SumQuantity
FROM Sales.Invoices si
JOIN Sales.InvoiceLines sil on si.InvoiceID = sil.InvoiceID
JOIN Warehouse.StockItems wsi on wsi.StockItemID = sil.StockItemID
WHERE ConfirmedDeliveryTime is not null) a
WHERE SumQuantity < 50
ORDER BY  InvoiceYear, InvoiceMonth, StockItemName
