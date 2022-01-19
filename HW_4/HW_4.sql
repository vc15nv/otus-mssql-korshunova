/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

SELECT *
FROM (
SELECT convert(varchar, DATEFROMPARTS(YEAR(InvoiceDate), MONTH(InvoiceDate), 1), 104) StartDateOfMonth,
SUBSTRING(CustomerName, CHARINDEX('(', CustomerName) + 1, CHARINDEX(')', CustomerName) - CHARINDEX('(', CustomerName) - 1) AS CustomerName,
COUNT(InvoiceId) as cnt
FROM Sales.Invoices si
JOIN Sales.Customers sc on sc.CustomerID = si.CustomerID and sc.CustomerID between 2 and 6
GROUP BY DATEFROMPARTS(YEAR(InvoiceDate),MONTH(InvoiceDate),1), CustomerName
) AS SourceTable  
PIVOT(
	SUM(cnt) FOR CustomerName IN ([Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Jessie, ND])
	) AS PivotTable


/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38 
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/
SELECT CustomerName, AddressLine FROM
(
SELECT CustomerName, PostalAddressLine1, PostalAddressLine2, DeliveryAddressLine1, DeliveryAddressLine2
FROM Sales.Customers
WHERE CustomerName like '%Tailspin Toys%'
) AS SourceTable
UNPIVOT(
	AddressLine for col in (PostalAddressLine1, PostalAddressLine2, DeliveryAddressLine1, DeliveryAddressLine2)
	) AS UnpivotTable 
/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT CountryID, CountryName, Code
FROM (
SELECT CountryID, 
CAST(CountryName AS nvarchar) AS CountryName, 
CAST(ISNULL(IsoAlpha3Code, '') AS nvarchar) AS IsoAlpha3Code, 
CAST(ISNULL(IsoNumericCode, -1) AS nvarchar) IsoNumericCode 
FROM Application.Countries
) AS SourceTable
UNPIVOT(Code FOR val IN (IsoAlpha3Code, IsoNumericCode)
) AS UnpivotTable
ORDER BY CountryID;

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

	SELECT C.CustomerID, C.CustomerName, O.*
	FROM Sales.Customers C
	CROSS APPLY (SELECT TOP 2 CustomerID, StockItemID, Min(InvoiceDate) InvoiceDate, Max(UnitPrice) UnitPrice
                FROM Sales.Invoices si
				JOIN Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID 
                WHERE si.CustomerID = C.CustomerID
				GROUP BY si.CustomerID, StockItemID
				ORDER BY  CustomerID, UnitPrice desc
				) AS O
	ORDER BY C.CustomerID;