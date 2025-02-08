USE [stage]
GO

/****** Object:  StoredProcedure [stage].[sp_cons_hcount]    Script Date: 2024/9/30 上午 09:31:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [stage].[sp_cons_hcount] (@comp_id nvarchar(40) )
as
/*
   create 2440 2014018 for CONS Add
*/

    CREATE TABLE #temp_cons_hcount (
                                       [comp_id] [nvarchar](40) NOT NULL,
                                       [dblink_id] [nvarchar](40) NOT NULL,
                                       [group_id] [nvarchar](10) NOT NULL,
                                       [upper_group] [nvarchar](10) NOT NULL,
                                       [upper_comp] [nvarchar](20) NOT NULL,
                                       [lower_comp] [nvarchar](20) NOT NULL,
                                       [yyyymm] [nvarchar](6) NOT NULL,
                                       [cons_lev] [int] NOT NULL,
                                       [lower_group] [nvarchar](10) NOT NULL,
                                       [hcount] [numeric](10, 0) NULL,
                                       [sum_hcount] [numeric](10, 0) NULL,
                                       [cons_hcount] [numeric](10, 0) NULL,
                                       [upper_cons_yn] [nvarchar](1) NULL,
                                       PRIMARY KEY
                                           (
                                            [comp_id] ASC,
                                            [dblink_id] ASC,
                                            [group_id] ASC,
                                            [upper_group] ASC,
                                            [upper_comp] ASC,
                                            [lower_comp] ASC,
                                            [yyyymm] ASC
                                               ))


    CREATE TABLE #temp_cons_hcount_t (
                                         [comp_id] [nvarchar](40) NOT NULL,
                                         [dblink_id] [nvarchar](40) NOT NULL,
                                         [group_id] [nvarchar](10) NOT NULL,
                                         [upper_group] [nvarchar](10) NOT NULL,
                                         [upper_comp] [nvarchar](20) NOT NULL,
                                         [lower_comp] [nvarchar](20) NOT NULL,
                                         [yyyymm] [nvarchar](6) NOT NULL,
                                         [cons_lev] [int] NOT NULL,
                                         [lower_group] [nvarchar](10) NOT NULL,
                                         [hcount] [numeric](10, 0) NULL,
                                         [sum_hcount] [numeric](10, 0) NULL,
                                         [cons_hcount] [numeric](10, 0) NULL,
                                         [upper_cons_yn] [nvarchar](1) NULL,
                                         PRIMARY KEY
                                             (
                                              [comp_id] ASC,
                                              [dblink_id] ASC,
                                              [group_id] ASC,
                                              [upper_group] ASC,
                                              [upper_comp] ASC,
                                              [lower_comp] ASC,
                                              [yyyymm] ASC
                                                 ))


/*log記錄用----------------*/
declare @rowcount int,
@info_type varchar(200) ,
@msg varchar(200),
@star_date datetime

    SET @rowcount=0
    SET @star_date=getdate()
    SET @info_type='EXEC SP: stage.sp_cons_hcount'

/*log---------------------*/

declare
    @etl_date_fm numeric(8,0),--ETL起始日
    @etl_date_to numeric(8,0),--ETL截止日
    @cons_lev_max numeric(8,0),
    @min_txn_date numeric(8,0)
    --

--test
--	declare	@comp_id nvarchar(40)
--	set @comp_id='WFGP316'

--取得執行區間
select  @etl_date_fm=convert(nvarchar(6),etl_date_fm),@etl_date_to=convert(nvarchar(6),etl_date_to) from stage.fn_get_etldate(@comp_id) where dtsx_id='CONS'

--0.truncate temp table
    truncate table stage.temp_cons_hcount

--1.抓取所有時期所有集團樹的數據
insert into #temp_cons_hcount(comp_id,dblink_id,group_id,upper_comp,upper_group,lower_comp,lower_group,cons_lev,upper_cons_yn ,yyyymm)
select comp_id,dblink_id,group_id,upper_comp,upper_group,lower_comp,lower_group,cons_lev,upper_flag ,dc.yyyymm
from stage.stage.temp_cons_group gp
         cross join (
    select distinct yyyymm  as yyyymm
    from stage.stage.of_cons_hcountb
    where yyyymm between @etl_date_fm and @etl_date_to
) dc


--1.2 insert temp 末階資料
insert into #temp_cons_hcount_t(comp_id,dblink_id,group_id,upper_comp,upper_group,lower_comp,lower_group,cons_lev,upper_cons_yn ,yyyymm,hcount)
select c.comp_id,c.dblink_id,c.group_id as group_id,c.upper_comp,c.upper_group,a.cons_comp  as lower_comp,a.group_id as lower_group,c.cons_lev,c.upper_flag,b.yyyymm,b.hcount
from stage.stage.of_cons_hcounta  a
         inner join stage.stage.of_cons_hcountb b on a.group_id=b.group_id and a.cons_comp=b.cons_comp
         inner join stage.stage.temp_cons_group c on c.lower_group=b.group_id and c.lower_comp=b.cons_comp
where c.upper_flag='N'


--1.3 更新末階資料
update #temp_cons_hcount
set
    hcount = #temp_cons_hcount_t.hcount
from #temp_cons_hcount_t
where #temp_cons_hcount.comp_id=#temp_cons_hcount_t.comp_id
  and #temp_cons_hcount.dblink_id=#temp_cons_hcount_t.dblink_id
  and #temp_cons_hcount.group_id=#temp_cons_hcount_t.group_id
  and  #temp_cons_hcount.lower_comp=#temp_cons_hcount_t.lower_comp
  and  #temp_cons_hcount.lower_group=#temp_cons_hcount_t.lower_group
  and  #temp_cons_hcount.upper_comp=#temp_cons_hcount_t.upper_comp
  and  #temp_cons_hcount.upper_group=#temp_cons_hcount_t.upper_group
  and  #temp_cons_hcount.yyyymm=#temp_cons_hcount_t.yyyymm

--1.4 取的最底層級
select @cons_lev_max=max(cons_lev) from #temp_cons_hcount

--2.迴圈
    while @cons_lev_max>0
        BEGIN
            update a set a.hcount=b.hcount
            from #temp_cons_hcount a
                     left join(
                select group_id,upper_comp,upper_group,yyyymm,sum(isnull(hcount,0)) as hcount
                from #temp_cons_hcount where cons_lev=@cons_lev_max
                group by  group_id,upper_comp,upper_group,yyyymm
            ) b on a.group_id=b.group_id and a.lower_comp=b.upper_comp and a.lower_group=b.upper_group and a.yyyymm=b.yyyymm
            where a.cons_lev=@cons_lev_max-1 and upper_cons_yn='Y'
            --取下一階
            set @cons_lev_max=@cons_lev_max-1
        end

--3.insert temp_cons_hcount
insert into stage.stage.temp_cons_hcount(comp_id,dblink_id,group_id,upper_comp,upper_group,lower_comp,lower_group,cons_lev,upper_cons_yn ,yyyymm,hcount)
select comp_id,dblink_id,group_id,upper_comp,upper_group,lower_comp,lower_group,cons_lev,upper_cons_yn ,yyyymm,hcount from #temp_cons_hcount

--4.drop temp table
    drop table #temp_cons_hcount,#temp_cons_hcount_t

/*log記錄用----------------*/
    SET @rowcount=(select count(1) FROM stage.temp_cons_hcount )
    SET @msg= convert(nchar(10),@comp_id)+stage.fn_get_message('SPSUUC',null)
    PRINT @msg
/*log記錄用----------------*/

insert into dtsx_log values('2','sp_cons_hcount',@comp_id,'',@star_date,getdate(),@rowcount,@rowcount,0,0,'Y',@info_type,@msg)
/*---------------*/
    SET NOCOUNT OFF

GO


