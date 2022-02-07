/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Опционально - если вы знакомы с insert, update, merge, то загрузить эти данные в таблицу Warehouse.StockItems.
Существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 
*/

DECLARE @xmlDocument  xml

SET @xmlDocument = (
SELECT * FROM OPENROWSET (
			  BULK 'C:\Users\user\Documents\GitHub\otus-mssql-korshunova\HW_7\StockItems.xml',  SINGLE_CLOB
			  ) as data )

SELECT  
  t.item.value('(@Name)[1]', 'varchar(100)') as [StockItemName],
  t.item.value('(SupplierID)[1]', 'int') as [SupplierID],
  t.item.value('(Package/UnitPackageID)[1]', 'int') as [UnitPackageID],
  t.item.value('(Package/OuterPackageID)[1]', 'int') as [OuterPackageID],
  t.item.value('(Package/QuantityPerOuter)[1]', 'int') as [QuantityPerOuter],
  t.item.value('(Package/TypicalWeightPerUnit)[1]', 'decimal(18,3)') as [TypicalWeightPerUnit],
  t.item.value('(LeadTimeDays)[1]', 'int') as [LeadTimeDays],
  t.item.value('(IsChillerStock)[1]', 'bit') as [IsChillerStock],
  t.item.value('(TaxRate)[1]', 'decimal(18,3)') as [TaxRate],
  t.item.value('(UnitPrice)[1]', 'decimal(18,2)') as [UnitPrice]

FROM @xmlDocument.nodes('/StockItems/Item') as t(item)



/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

SELECT 
StockItemName as '@Name',
SupplierID as 'SupplierID', 
UnitPackageID as 'Package/UnitPackageID', 
OuterPackageID as 'Package/OuterPackageID', 
QuantityPerOuter as 'Package/QuantityPerOuter', 
TypicalWeightPerUnit as 'Package/TypicalWeightPerUnit',  
LeadTimeDays as 'LeadTimeDays', 
IsChillerStock as 'IsChillerStock', 
TaxRate as 'TaxRate', 
UnitPrice as 'UnitPrice'
FROM Warehouse.StockItems
FOR XML PATH('Item'), ROOT ('StockItems');



/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT StockItemID, StockItemName, CustomFields,
JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
JSON_VALUE(CustomFields, '$.Tags[0]') AS FirstTag
FROM Warehouse.StockItems



/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


-- НЕ понятно:  (опционально) все теги (из CustomFields) через запятую в одном поле
SELECT StockItemID, StockItemName, CustomFields
FROM Warehouse.StockItems
WHERE JSON_VALUE(CustomFields, '$.Tags[0]') = 'Vintage'
