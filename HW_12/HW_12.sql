/* 
1. Создать базу данных.
2. 3-4 основные таблицы для своего проекта.
Первичные и внешние ключи для всех созданных таблиц.
3. 1-2 индекса на таблицы.
4. Наложите по одному ограничению в каждой таблице на ввод данных. 
В качестве проекта вы можете взять любую идею, которая вам близка.
Это может быть какая-то часть вашего рабочего проекта, которую вы хотите переосмыслить.
Если есть идея, но не понятно как ее уложить в рамки учебного проекта, напишите преподавателю и мы поможем. 
 Проект мы будем делать весь курс и защищать его в самом конце, он будет заключаться в созданной БД со схемой,
описанием проекта, и необходимыми процедурами\функциями или SQL кодом для демонстрации
основного функционала системы. Создать в github папку с проектом, создать 
там описание проекта - о чем он, какие функции будут реализованы, основные сущности, 
которые затем будут созданы (просто описание текстом). */


--1 Создание базы данных
CREATE DATABASE ESResinRecyclingProcess;
GO

use ESResinRecyclingProcess;


CREATE TABLE [dbo].[rectification_columns]
(
 [id]     int NOT NULL ,
 [number] int NOT NULL ,
 CONSTRAINT [PK_rectification_columns] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT CHK_Number CHECK ([number] Like '[0-5]')
);
GO

EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Список ректификационных колонн', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'rectification_columns';
GO

CREATE TABLE [dbo].[rectification_column_parameters]
(
 [id]                      int NOT NULL ,
 [rectification_column_id] int NOT NULL ,
 [name]                    varchar(200) NOT NULL ,
 [description]             nvarchar(4000) NOT NULL ,

 CONSTRAINT [PK_rectification_column_parameters] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_rectification_column_parameters_rectification_column_id_rectification_columns] FOREIGN KEY ([rectification_column_id])  REFERENCES [dbo].[rectification_columns]([id]),
 CONSTRAINT CHK_Name CHECK (name LIKE '%[a-d]%') 
);
GO

EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Справочник параметров ректификационной колонны', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'rectification_column_parameters';
GO


CREATE TABLE [dbo].[naphthalene_fraction_temperatures]
(
 [id]                      bigint NOT NULL ,
 [measured_at]             datetime2(3) NOT NULL ,
 [value]                   real NOT NULL ,
 [rectification_column_id] int NOT NULL ,

 CONSTRAINT [PK_naphthalene_fraction_temperatures] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_naphthalene_fraction_temperatures_rectification_column_id_rectification_columns] FOREIGN KEY ([rectification_column_id])  REFERENCES [dbo].[rectification_columns]([id])
);
GO

CREATE TABLE [dbo].[naphthalene_fraction_consumptions]
(
 [id]                      bigint NOT NULL ,
 [measured_at]             datetime2(3) NOT NULL ,
 [value]                   real NOT NULL ,
 [rectification_column_id] int NOT NULL ,


 CONSTRAINT [PK_naphthalene_fraction_consumptions] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_naphthalene_fraction_consumptions_rectification_column_id_rectification_columns] FOREIGN KEY ([rectification_column_id])  REFERENCES [dbo].[rectification_columns]([id])
);
GO

CREATE TABLE [dbo].[marks_catalog]
(
 [id]          int NOT NULL ,
 [name]        nvarchar(150) NOT NULL ,
 [lower_bound] int NOT NULL ,
 [upper_bound] int NOT NULL ,


 CONSTRAINT [PK_marks_catalog] PRIMARY KEY CLUSTERED ([id] ASC)
);
GO


CREATE TABLE [dbo].[grid_search_parameters]
(
 [id]                   bigint NOT NULL ,
 [parameter_id]         int NOT NULL ,
 [chemical_analysis_id] int NOT NULL ,
 [value]                real NOT NULL ,


 CONSTRAINT [PK_grid_search_parameters] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_grid_search_parameters_chemical_analysis_id_chemical_analysis] FOREIGN KEY ([chemical_analysis_id])  REFERENCES [dbo].[chemical_analysis]([id]),
 CONSTRAINT [FK_grid_search_parameters_parameter_id_rectification_column_parameters] FOREIGN KEY ([parameter_id])  REFERENCES [dbo].[rectification_column_parameters]([id])
);
GO



CREATE TABLE [dbo].[current_selected_mark]
(
 [id]        int NOT NULL ,
 [timestamp] datetime2(7) NOT NULL ,
 [mark_id]   int NOT NULL ,

 CONSTRAINT [PK_current_selected_marks] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_current_selected_marks_mark_id_marks_catalog] FOREIGN KEY ([mark_id])  REFERENCES [dbo].[marks_catalog]([id])
);
GO

CREATE TABLE [dbo].[chemical_parameters]
(
 [id]                      int NOT NULL ,
 [name]                    varchar(200) NOT NULL ,
 [description]             nvarchar(4000) NOT NULL ,
 [rectification_column_id] int NOT NULL ,


 CONSTRAINT [PK_chemical_parameters] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_chemical_parameters_rectification_column_id_rectification_columns] FOREIGN KEY ([rectification_column_id])  REFERENCES [dbo].[rectification_columns]([id])
);
GO

CREATE TABLE [dbo].[chemical_analysis]
(
 [id]                    int NOT NULL ,
 [measured_at]           datetime2(3) NOT NULL ,
 [mark_id]               int NOT NULL ,
 [chemical_parameter_id] int NOT NULL ,
 [value]                 real NOT NULL ,


 CONSTRAINT [PK_chemical_analysis] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_chemical_analysis_chemical_parameter_id_chemical_parameters] FOREIGN KEY ([chemical_parameter_id])  REFERENCES [dbo].[chemical_parameters]([id]),
 CONSTRAINT [FK_chemical_analysis_mark_id_marks_catalog] FOREIGN KEY ([mark_id])  REFERENCES [dbo].[marks_catalog]([id])
);
GO

CREATE TABLE [dbo].[absorption_fraction_temperatures]
(
 [id]                      bigint NOT NULL ,
 [rectification_column_id] int NOT NULL ,
 [measured_at]             datetime2(3) NOT NULL ,
 [value]                   real NOT NULL ,


 CONSTRAINT [PK_absorption_fraction_temperatures] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_absorption_fraction_temperatures_rectification_column_id_rectification_columns] FOREIGN KEY ([rectification_column_id])  REFERENCES [dbo].[rectification_columns]([id])
 
);
GO

CREATE TABLE [dbo].[absorption_fraction_consumptions]
(
 [id]                      bigint NOT NULL ,
 [rectification_column_id] int NOT NULL ,
 [measured_at]             datetime2(3) NOT NULL ,
 [value]                   real NOT NULL ,


 CONSTRAINT [PK_absorption_fraction_consumptions] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_absorption_fraction_consumptions_rectification_column_id_rectification_columns] FOREIGN KEY ([rectification_column_id])  REFERENCES [dbo].[rectification_columns]([id])
);
GO


CREATE TABLE [dbo].[recommended_parameters]
(
 [id]                int NOT NULL ,
 [current_mark_id]   int NOT NULL ,
 [grid_parameter_id] bigint NOT NULL ,
 [created_at]        datetime2(3) NOT NULL ,


 CONSTRAINT [PK_recommended_parameters] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_recommended_parameters_current_mark_id_current_selected_mark] FOREIGN KEY ([current_mark_id])  REFERENCES [dbo].[current_selected_mark]([id]),
 CONSTRAINT [FK_recommended_parameters_grid_parameter_id_grid_search_parameters] FOREIGN KEY ([grid_parameter_id])  REFERENCES [dbo].[grid_search_parameters]([id])
);
GO

CREATE NONCLUSTERED INDEX [IDX_recommended_parameters_current_mark_id_and_grid_parameter_id] 
ON [dbo].[recommended_parameters] 
 ([current_mark_id] ASC, [grid_parameter_id])
GO


-- удаление базы данных
--drop database ESResinRecyclingProcess;
