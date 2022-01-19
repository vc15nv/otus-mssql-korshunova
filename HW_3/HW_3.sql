/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT PersonID, FullName
FROM Application.People
WHERE IsSalesperson = 1 AND 
PersonID NOT IN (
		SELECT DISTINCT SalespersonPersonID
		FROM Sales.Invoices
		WHERE InvoiceDate = '2015-07-04'
		)

;WITH InvoicesCTE AS (
	SELECT DISTINCT SalespersonPersonID
		FROM Sales.Invoices
		WHERE InvoiceDate = '2015-07-04'
)

SELECT PersonID, FullName, SalespersonPersonID
FROM Application.People
LEFT JOIN InvoicesCTE on InvoicesCTE.SalespersonPersonID = People.PersonID
WHERE IsSalesperson = 1 AND SalespersonPersonID IS NULL

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
SELECT StockItemID, StockItemName, UnitPrice	
FROM Warehouse.StockItems 
WHERE UnitPrice = (SELECT MIN(UnitPrice) FROM Warehouse.StockItems)

SELECT StockItemID, StockItemName, UnitPrice	
FROM Warehouse.StockItems
WHERE UnitPrice <= ALL(
	SELECT UnitPrice 
	FROM Warehouse.StockItems)

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

SELECT c.CustomerID, c.CustomerName, ct.TransactionAmount
FROM Sales.CustomerTransactions ct
LEFT JOIN Sales.Customers c on ct.CustomerID = c.CustomerID
WHERE ct.TransactionAmount IN (
								SELECT TOP(5) TransactionAmount
								FROM Sales.CustomerTransactions ct
								ORDER BY TransactionAmount DESC
							  )

WITH TransactionCTE AS (
SELECT TOP(5) CustomerID, TransactionAmount
								FROM Sales.CustomerTransactions ct
								ORDER BY TransactionAmount DESC
)
SELECT c.CustomerID, c.CustomerName, t.TransactionAmount
FROM TransactionCTE t
JOIN Sales.Customers c on c.CustomerID = t.CustomerID

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

SELECT CityID, CityName, si.StockItemName, si.UnitPrice, ap.FullName
FROM Sales.Orders so
JOIN Sales.OrderLines sol on so.OrderID = sol.OrderID
JOIN (SELECT TOP(3) * 
	  FROM Warehouse.StockItems
	  ORDER BY UnitPrice DESC
	) si on si.StockItemID = sol.StockItemID
JOIN Application.People ap on ap.PersonID = so.PickedByPersonID
JOIN Sales.Customers sc on sc.CustomerID = so.CustomerID
JOIN Application.Cities ac on ac.CityID = sc.DeliveryCityID
ORDER BY CityID, CityName, si.UnitPrice



-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
