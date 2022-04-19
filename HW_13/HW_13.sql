/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "20 - Индексы".
*/

DROP INDEX [NCLIDX_recommended_parameters_current_mark_id_and_grid_parameter_id] ON dbo.[recommended_parameters];
GO

CREATE NONCLUSTERED INDEX [NCLIDX_recommended_parameters_current_mark_id_and_grid_parameter_id] 
ON [dbo].[recommended_parameters] 
 ([current_mark_id], [grid_parameter_id])
GO

select *
from dbo.recommended_parameters rp
join dbo.current_selected_mark csm on csm.mark_id = rp.current_mark_id
join dbo.grid_search_parameters gsp on gsp.parameter_id = rp.grid_parameter_id
where current_mark_id = 1 and grid_parameter_id = 1