/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/
INSERT INTO [Purchasing].[Suppliers]
           ([SupplierID]
           ,[SupplierName]
           ,[SupplierCategoryID]
           ,[PrimaryContactPersonID]
           ,[AlternateContactPersonID]
           ,[DeliveryMethodID]
           ,[DeliveryCityID]
           ,[PostalCityID]
           ,[SupplierReference]
           ,[BankAccountName]
           ,[BankAccountBranch]
           ,[BankAccountCode]
           ,[BankAccountNumber]
           ,[BankInternationalCode]
           ,[PaymentDays]
           ,[InternalComments]
           ,[PhoneNumber]
           ,[FaxNumber]
           ,[WebsiteURL]
           ,[DeliveryAddressLine1]
           ,[DeliveryAddressLine2]
           ,[DeliveryPostalCode]
           ,[DeliveryLocation]
           ,[PostalAddressLine1]
           ,[PostalAddressLine2]
           ,[PostalPostalCode]
           ,[LastEditedBy])
SELECT TOP (5) [SupplierID] + 10000 AS SupplierID
      ,CONCAT('Test_', [SupplierName]) AS SupplierName
      ,[SupplierCategoryID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[SupplierReference]
      ,[BankAccountName]
      ,[BankAccountBranch]
      ,[BankAccountCode]
      ,[BankAccountNumber]
      ,[BankInternationalCode]
      ,[PaymentDays]
      ,[InternalComments]
      ,'(999) 555-0100' [PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
  FROM [WideWorldImporters].[Purchasing].[Suppliers]

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM [WideWorldImporters].[Purchasing].[Suppliers]
WHERE SupplierID = 10001

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE [WideWorldImporters].[Purchasing].[Suppliers]
SET PhoneNumber  = '(777) 920-0212' WHERE SupplierID = 10002

/*
4. Написать MERGE, который вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/
MERGE [WideWorldImporters].[Purchasing].[Suppliers] as target_t
USING [WideWorldImporters].[Purchasing].[Suppliers] as source_t
ON (target_t.SupplierID = source_t.SupplierID)
WHEN MATCHED THEN 
	UPDATE SET SupplierName = source_t.SupplierName, PhoneNumber  = source_t.PhoneNumber
WHEN NOT MATCHED THEN 
	INSERT (SupplierName, PhoneNumber)
	VALUES (source_t.SupplierName, source_t.PhoneNumber)

	OUTPUT deleted.*, $action, inserted.*;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert

*/

-- выгрузка в файл работает только через cmd. 
exec master..xp_cmdshell 'bcp WideWorldImporters.Sales.InvoiceLines out C:\Users\user\Desktop\InvoiceLines.txt -T -w -t, -S KorshunovaA\SQL2017'

drop table if exists [Sales].[InvoiceLines_BulkDemo];

CREATE TABLE [Sales].[InvoiceLines_BulkDemo](
	[InvoiceLineID] [int] NOT NULL,
	[InvoiceID] [int] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[PackageTypeID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[TaxAmount] [decimal](18, 2) NOT NULL,
	[LineProfit] [decimal](18, 2) NOT NULL,
	[ExtendedPrice] [decimal](18, 2) NOT NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Sales_InvoiceLines_BulkDemo] PRIMARY KEY CLUSTERED 
(
	[InvoiceLineID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [USERDATA]
) ON [USERDATA]
----



	BULK INSERT [WideWorldImporters].[Sales].[InvoiceLines_BulkDemo]
				   FROM "C:\Users\user\Desktop\InvoiceLines.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = '@eu&$1&',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );


select Count(*) from [Sales].[InvoiceLines_BulkDemo];