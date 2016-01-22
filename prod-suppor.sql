--------------------------------------------------------------------------------------------------------------------------
/*
	Useful SQLCODE
*/
--------------------------------------------------------------------------------------------------------------------------

select * from ALL_TAB_COLUMNS where column_name like '%VOID%';
select * from ALL_TAB_COLUMNS where table_name like '%VOID%';

--------------------------------------------------------------------------------------------------------------------------
/*
	Daily checks
*/
--------------------------------------------------------------------------------------------------------------------------

-- STUCK WORK QUEUE ITEMS
select * from DATA_SEM.TBL_WORK_QUEUE where RETRY_COUNT = 10  order by 4 desc;

select * from DATA_SEM.tbl_work_type;

select b.WORK_GROUP_ID,	b.DESCRIPTION, a.*
from DATA_SEM.TBL_WORK_QUEUE a inner join DATA_SEM.tbl_work_type b on a.work_type_id = b.work_type_id where RETRY_COUNT = 10  order by a.SUBMIT_DATE desc;

-- COMISSION REPORTS for each day (Sogei_return_code must be 1024 or 3205(duplicate))
select * from DATA_SEM.TBL_COMMISSION_REPORT order by 3 desc;

-- SIMONS QUEURY FOR ANY SETTLEMENT REPORTS THAT NEED SENDING - may contain stuff not in the JMX call – change the two dates accordingly
SELECT market_id
              FROM data_sem.tbl_event  e
                  ,data_sem.tbl_market m
             WHERE TRUNC(accounting_dt) = TO_DATE('14-JAN-2016', 'DD-MON-YYYY')
               AND e.sogei_schedule_code = m.sogei_schedule_code
               AND e.sogei_event_code = m.sogei_event_code
               AND m.betfair_product_id = 1
               AND EXISTS (SELECT NULL
                      FROM data_sem.tbl_matched_bet mb
                     WHERE mb.market_id = m.market_id
                          --AND mb.sogei_reference IS NOT NULL
                       AND mb.back_account_id != mb.lay_account_id)
            MINUS
            SELECT market_id
              FROM data_sem.tbl_settlement_report
             WHERE settlement_report_id IN (SELECT MAX(settlement_report_id)
                                              FROM data_sem.tbl_settlement_report
                                             WHERE market_id IN (SELECT market_id
                                                                   FROM data_sem.tbl_event  e
                                                                       ,data_sem.tbl_market m
                                                                  WHERE TRUNC(accounting_dt) = TO_DATE('14-JAN-2016', 'DD-MON-YYYY')
                                                                    AND e.sogei_schedule_code = m.sogei_schedule_code
                                                                    AND e.sogei_event_code = m.sogei_event_code
                                                                    AND m.betfair_product_id = 1
                                                                    AND EXISTS (SELECT NULL
                                                                           FROM data_sem.tbl_matched_bet mb
                                                                          WHERE mb.market_id = m.market_id
                                                                               --AND mb.sogei_reference IS NOT NULL
                                                                            AND mb.back_account_id != mb.lay_account_id)
                                                                    AND EXISTS (SELECT NULL
                                                                           FROM data_sem.tbl_settlement_report sr
                                                                          WHERE sr.market_id = m.market_id))
                                               AND settlement_report_type = 'S'
                                               AND sogei_return_code = 1024
                                             GROUP BY market_id
                                                     ,settlement_report_type
                                                     ,account_id);


-- sportex
select * from source_sportex.tbl_acc_stat_summ where event_id = 122181341;


--------------------------------------------------------------------------------------------------------------------------
/*
	SEM Checks
*/
--------------------------------------------------------------------------------------------------------------------------

-- Use the settlement reader to get the sogei coordinates that have issues
select  B.CODE AS BF_STATUS, C.CODE AS SOGE_STATUS, A.BETFAIR_MARKET_ID, a.CP_MARKET_YN, a.* from data_sem.tbl_market A
LEFT JOIN data_sem.Tbl_Market_States B ON A.MARKET_STATE_ID = B.MARKET_STATE_ID
LEFT JOIN data_sem.Tbl_Sogei_Market_Statuses C ON A.SOGEI_MARKET_STATUS_ID = C.SOGEI_MARKET_STATUS_ID
where (SOGEI_SCHEDULE_CODE, SOGEI_EVENT_CODE, SOGEI_MARKET_CODE) in (
(19375,52,130), (19375,52,129)
) and betfair_product_id = 1 order by A.BETFAIR_MARKET_ID;

-- Use the settlement reader to get the sogei coordinates that have issues (with event details)
select d.BETFAIR_EVENT_ID, d.SOGEI_EVENT_DT,d.sogei_event_status_id,  B.CODE AS BF_STATUS, C.CODE AS SOGE_STATUS, A.BETFAIR_MARKET_ID, a.CP_MARKET_YN, a.* from data_sem.tbl_market A
LEFT JOIN data_sem.Tbl_Market_States B ON A.MARKET_STATE_ID = B.MARKET_STATE_ID
LEFT JOIN data_sem.Tbl_Sogei_Market_Statuses C ON A.SOGEI_MARKET_STATUS_ID = C.SOGEI_MARKET_STATUS_ID
LEFT JOIN data_sem.tbl_event d on a.SOGEI_SCHEDULE_CODE = d.SOGEI_SCHEDULE_CODE and a.SOGEI_EVENT_CODE = d.SOGEI_EVENT_CODE
where (a.SOGEI_SCHEDULE_CODE, a.SOGEI_EVENT_CODE, a.SOGEI_MARKET_CODE) in (
(19375,52,130), (19375,52,129)
) and a.betfair_product_id = 1 order by d.BETFAIR_EVENT_ID, A.BETFAIR_MARKET_ID;


select B.CODE AS BF_STATUS, C.CODE AS SOGE_STATUS, A.BETFAIR_MARKET_ID as BF_MARKET_ID, a.CP_MARKET_YN
, (select count(*) from data_sem.tbl_matched_bet where market_id = a.MARKET_ID) as MATCHED_BETS 
, (select case when count(*) = 0 then 'N' else 'Y' end from data_sem.tbl_settlement_report where market_id = a.MARKET_ID and SOGEI_RETURN_CODE	= 1024 and SETTLEMENT_REPORT_TYPE = 'S') as REPORT_SENT
, a.*
,(select 'http://tools.dev.betfair:8080/?scheduleId=' || a.SOGEI_SCHEDULE_CODE || '&' || 'eventId=' || a.SOGEI_EVENT_CODE from dual) as SOGEI_URL 
,(select 'https://www.betfair.it/exchange/football/market?id=1.' || A.BETFAIR_MARKET_ID from dual) as WEB_URL 
--select B.CODE AS BF_STATUS, C.CODE AS SOGE_STATUS, A.BETFAIR_MARKET_ID, a.CP_MARKET_YN, a.*
from DATA_SEM.TBL_MARKET A
       left join data_sem.tbl_market_states B 
              ON a.market_state_id = B.market_state_id 
       left join data_sem.tbl_sogei_market_statuses C 
              ON a.sogei_market_status_id = C.sogei_market_status_id 
--WHERE MARKET_ID IN(2216920)
WHERE A.BETFAIR_MARKET_ID IN ( 
 122651681, 122651682
)
--WHERE A.BETFAIR_MARKET_ID IN (122026113 )
--and betfair_product_id = 1
--and CP_MARKET_YN = 'N'
order by A.BETFAIR_MARKET_ID,a.CP_MARKET_YN 
;

-- check if the settlement report has been sent
select * from data_sem.tbl_settlement_report where market_id in (2428477) order by 1 asc;    
-- check if there is time based void for a market
select * from DATA_SEM.TBL_TIMEBASED_VOID_NOTIF where MARKET_ID in (2429217,2446174);
-- Check if there is issue with selections to compare with SPORTEX
select * from DATA_SEM.tbl_selection where MARKET_ID = 2419921 and BETFAIR_SELECTION_ID in (30246,30247) order by sogei_selection_code;

select a.*
, (select b.code from data_sem.TBL_SETTLED_STATUSES b where a.SETTLED_STATUS_ID = b.settled_status_id ) as betfair_status
, (select c.code from data_sem.TBL_SETTLED_STATUSES c where a.SOGEI_SETTLED_STATUS_ID = c.settled_status_id ) as sogie_status
--, b.code as betfair_status , c.code as sogie_status  
from DATA_SEM.tbl_selection a
where MARKET_ID = 2289198 and BETFAIR_SELECTION_ID in (1485567,1485568) order by sogei_selection_code;

-- Various ways to check the event details
select * from DATA_SEM.TBL_EVENT  where BETFAIR_EVENT_ID = 27641097;
select * from DATA_SEM.TBL_EVENT  where SOGEI_SCHEDULE_CODE = 19346 and SOGEI_EVENT_CODE = 3;
select SOGEI_SCHEDULE_CODE, SOGEI_EVENT_CODE from DATA_SEM.TBL_EVENT  where BETFAIR_EVENT_ID = 27641097;
select * from DATA_SEM.TBL_EVENT  where BETFAIR_EVENT_ID = 27647820;

--------------------------------------------------------------------------------------------------------------------------
/*
	Sportex checks
*/
--------------------------------------------------------------------------------------------------------------------------

-- Get market and event details
select c.SPORT_ID, c.SPORT_NAME, '..............',a.PARENT_ID, b.event_name, a.EVENT_ID,	a.EVENT_NAME	,	a.EXP_OPEN_DT	,	a.EXP_CLOSE_DT	,	a.EXP_SETTLE_DT	,	a.OPENED_DATE	,	a.CLOSED_DATE	,	a.SETTLED_DATE
,(select 'select * from source_sportex.tbl_event_log where market_id in (' || a.EVENT_ID || ' ) and  event_id = ' || a.PARENT_ID  || '  order by  MARKET_ID,LOG_SEQ; ' from dual) as SOGEI_URL 
--, d.*
from SOURCE_SPORTEX.TBL_MARKETS a 
inner join SOURCE_SPORTEX.TBL_EVENT_STRUCTURES b on a.PARENT_ID = b.event_id
--inner join source_sportex.tbl_event_log d on d.MARKET_ID = a.EVENT_ID
inner join SOURCE_SPORTEX.TBL_SPORTS c on a.sport_id = c.sport_id
where a.event_id in ( 
122651653
) 
--where SETTLED_DATE  is null
order by c.SPORT_NAME, EXP_OPEN_DT, b.EVENT_NAME, a.EVENT_NAME desc
;

-- Check the Sportex Logs
select * from source_sportex.tbl_event_log where market_id in (122544928)  and  event_id = '27647820'  order by  MARKET_ID,LOG_SEQ;

-- Get the selection details SELECT b.SELECTION_NAME,	b.SPORT_ID, a.EVENT_ID,	a.SELECTION_ID	,	a.WIN_LOSE	,	a.SETTLED_DATE	,	a.COMMISSION	,	a.PRODUCT_ID	,	a.RESULT	,	a.ORDER_ID
 SELECT b.SELECTION_NAME,	b.SPORT_ID, a.EVENT_ID,	a.SELECTION_ID	,	a.WIN_LOSE	,	a.SETTLED_DATE	,	a.COMMISSION	,	a.PRODUCT_ID	,	a.RESULT	,	a.ORDER_ID
 ,(select nvl(WHAT_HAPPENED, 0)  from source_sportex.tbl_event_log where WHAT_HAPPENED like '%Winning selection%' and MARKET_ID = a.event_id and rownum <= 1 ) as selection_result
 FROM source_sportex.tbl_runners_hist a
 inner join source_sportex.tbl_selections b on a.selection_id = b.selection_id
 WHERE a.event_id in (   
 122568540 -- done
 );
  SELECT b.SELECTION_NAME,	b.SPORT_ID, a.EVENT_ID,	a.*
 ,(select nvl(WHAT_HAPPENED, 0)  from source_sportex.tbl_event_log where WHAT_HAPPENED like '%Winning selection%' and MARKET_ID = a.event_id and rownum <= 1) as selection_result
 FROM source_sportex.tbl_runners_xpltfm a
 inner join source_sportex.tbl_selections b on a.selection_id = b.selection_id
 WHERE a.event_id in (
122568540 -- done
 ) ;

 -- some extra useful checks
select * from 	SOURCE_SPORTEX.TBL_EVENT_INFO where EVENT_ID in ( 27619776);
select * from 	SOURCE_SPORTEX.TBL_EVENT_STRUCTURES	where EVENT_ID in ( 27619776);
select * from SOURCE_SPORTEX.TBL_MARKETS where PARENT_ID = 27619776 and event_id in ( 122267296) ;
select * from SOURCE_SPORTEX.tbl_selections where selection_id in (30246,30247);
select * from source_sportex.tbl_acc_stat_summ where event_id = 122179173;

 