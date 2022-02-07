/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

with cte as(
SELECT distinct
MAX(si.InvoiceID) over (partition by InvoiceDate) InvoiceID, 
MAX(si.CustomerID) over (partition by InvoiceDate) CustomerID, 
InvoiceDate, 
SUM(sil.ExtendedPrice) over (partition by Year(InvoiceDate), Month(InvoiceDate)) SumInvoices
FROM Sales.Invoices si
JOIN Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
WHERE InvoiceDate > '2015-01-01'
),
uniq_sum as(
SELECT distinct YEAR(InvoiceDate) InvoiceYear, 
MONTH(InvoiceDate) InvoiceMonth, SumInvoices 
FROM cte 
),
cusum as (
select t1.InvoiceYear, t1.InvoiceMonth, Sum(t2.SumInvoices) as CUSUM
from uniq_sum t1 
inner join uniq_sum t2 on t1.InvoiceYear >= t2.InvoiceYear and t1.InvoiceMonth >= t2.InvoiceMonth
group by t1.InvoiceYear, t1.InvoiceMonth)

select InvoiceID, CustomerName, InvoiceDate, CUSUM
from cte
LEFT JOIN cusum on Year(cte.InvoiceDate) = cusum.InvoiceYear and MONTH(cte.InvoiceDate) = cusum.InvoiceMonth
JOIN Sales.Customers sc on sc.CustomerID = cte.CustomerID
order by InvoiceDate, InvoiceID

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

with cte as(
SELECT distinct
MAX(si.InvoiceID) over (partition by InvoiceDate) InvoiceID, 
MAX(si.CustomerID) over (partition by InvoiceDate) CustomerID, 
InvoiceDate, 
SUM(sil.ExtendedPrice) over (partition by Year(InvoiceDate), Month(InvoiceDate)) SumInvoices
FROM Sales.Invoices si
JOIN Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
WHERE InvoiceDate > '2015-01-01'
),
uniq_sum as(
SELECT distinct YEAR(InvoiceDate) InvoiceYear, 
MONTH(InvoiceDate) InvoiceMonth, SumInvoices 
FROM cte 
),
cusum as (
select InvoiceYear, InvoiceMonth, 
SUM(SumInvoices) OVER(ORDER BY InvoiceYear, InvoiceMonth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CUSUM
from uniq_sum)

select InvoiceID, CustomerName, InvoiceDate, CUSUM
from cte
LEFT JOIN cusum on Year(cte.InvoiceDate) = cusum.InvoiceYear and MONTH(cte.InvoiceDate) = cusum.InvoiceMonth
JOIN Sales.Customers sc on sc.CustomerID = cte.CustomerID
order by InvoiceDate, InvoiceID

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/
with cte as (
SELECT ROW_NUMBER() OVER (partition by InvoiceYEAR, InvoiceMONTH ORDER BY Quantity DESC) as rn, * FROM (
SELECT distinct 
StockItemName, 
YEAR(InvoiceDate) InvoiceYEAR, MONTH(InvoiceDate) InvoiceMONTH,
sil.Quantity
FROM Sales.Invoices si
JOIN Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID 
JOIN Sales.Customers sc on sc.CustomerID = si.CustomerID
JOIN Warehouse.StockItems wsi on wsi.StockItemID = sil.StockItemID
WHERE InvoiceDate >= '2016-01-01')
as tab
)
SELECT StockItemName, InvoiceYEAR, InvoiceMONTH, Quantity FROM cte
where rn <= 2


/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

-- НЕ ПОНЯТНО: названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items" 
SELECT StockItemID, StockItemName, Brand, UnitPrice, TypicalWeightPerUnit,
ROW_NUMBER() OVER (PARTITION BY LEFT(StockItemName, 1) ORDER BY StockItemName asc) AS numStockName,
COUNT(StockItemID) OVER () AS cntStokItem,
COUNT(StockItemID) OVER (PARTITION BY LEFT(StockItemName, 1)) as cntByStockName,
LEAD(StockItemID) OVER (ORDER BY StockItemName asc) as follow,
LAG(StockItemID) OVER (ORDER BY StockItemName asc) as previous,
NTILE(30) OVER (order by TypicalWeightPerUnit) groups,
LAG(StockItemName, 2) OVER (ORDER BY StockItemName asc) as name_two_lines_back
FROM Warehouse.StockItems
WHERE StockItemName LIKE '[a-z]%' 
ORDER BY name_two_lines_back


/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

SELECT SalespersonPersonID, FullName, CustomerID, CustomerName, InvoiceDate, TotalSum
FROM (
SELECT distinct si.InvoiceID,
MAX(si. InvoiceID) OVER (PARTITION BY si.SalespersonPersonID) MaxInvoiceID, 
si.SalespersonPersonID, ap.FullName, si.CustomerID, sc.CustomerName, si.InvoiceDate,
MAX(InvoiceDate) OVER (PARTITION BY si.SalespersonPersonID) MaxInvoiceDate,
SUM(sil.Quantity * sil.UnitPrice) OVER (PARTITION BY si.SalespersonPersonID, sc.CustomerID, InvoiceDate) AS TotalSum
FROM Sales.Invoices si
JOIN Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
JOIN Sales.Customers sc on sc.CustomerID = si.CustomerID
JOIN Application.People ap on ap.PersonID = si.SalespersonPersonID
) AS tab
WHERE InvoiceDate = MaxInvoiceDate and InvoiceID = MaxInvoiceID
ORDER BY SalespersonPersonID, InvoiceID, InvoiceDate desc 

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
	SELECT CustomerID, CustomerName, StockItemID, InvoiceDate, UnitPrice FROM (
	SELECT ROW_NUMBER() OVER(PARTITION BY si.CustomerID ORDER BY si.CustomerID) AS rn, 
	si.CustomerID, sc.CustomerName, StockItemID, Min(InvoiceDate) InvoiceDate, Max(UnitPrice) UnitPrice
    FROM Sales.Invoices si
	JOIN Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID 
	JOIN Sales.Customers sc on sc.CustomerID = si.CustomerID
	GROUP BY si.CustomerID, sc.CustomerName, StockItemID
	) AS tab
	WHERE rn <= 2
	ORDER BY  CustomerID, UnitPrice desc