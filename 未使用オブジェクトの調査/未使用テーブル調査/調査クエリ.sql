/* 
@threasholdDate:
未使用の判断につかう日付。
各テーブルごとに、全インデックスのlast_user_seek/last_user_scan/last_user_lookup/last_user_updateの
最新日付が@threasholdDateより前のものを「未使用」と判断して抽出する。
@oldestDate:
isnullの処理用に用意しためちゃ古い日付
*/
declare @threasholdDate datetime = dateadd(MONTH, -3, getdate())
declare @oldestDate datetime = '1900/01/01'

select
  TableName
  ,case when latest_last_user_seek = @oldestDate then null else latest_last_user_seek end as latest_last_user_seek
  ,case when latest_last_user_scan = @oldestDate then null else latest_last_user_scan end as latest_last_user_scan
  ,case when latest_last_user_lookup = @oldestDate then null else latest_last_user_lookup end as latest_last_user_lookup
  ,case when latest_last_user_update = @oldestDate then null else latest_last_user_update end as latest_last_user_update
from
(
  select
    OBJECT_NAME(sys.indexes.object_id) as TableName
    ,max(isnull(last_user_seek, @oldestDate)) as latest_last_user_seek
    ,max(isnull(last_user_scan, @oldestDate)) as latest_last_user_scan
    ,max(isnull(last_user_lookup, @oldestDate)) as latest_last_user_lookup
    ,max(isnull(last_user_update, @oldestDate)) as latest_last_user_update
  from
    sys.dm_db_partition_stats
  left join sys.indexes on sys.dm_db_partition_stats.object_id = sys.indexes.object_id
                        and sys.dm_db_partition_stats.index_id = sys.indexes.index_id
  left join sys.dm_db_index_usage_stats on sys.dm_db_partition_stats.object_id = sys.dm_db_index_usage_stats.object_id
                                        and sys.dm_db_partition_stats.index_id = sys.dm_db_index_usage_stats.index_id
  where exists (
      --ユーザーテーブルに限定
      select * from sys.objects where sys.objects.object_id = sys.indexes.object_id and sys.objects.type = 'U'
  )
  group by
    OBJECT_NAME(sys.indexes.object_id)
  having
      max(isnull(last_user_seek, @oldestDate)) < @threasholdDate
  and max(isnull(last_user_scan, @oldestDate)) < @threasholdDate
  and max(isnull(last_user_lookup, @oldestDate)) < @threasholdDate
  and max(isnull(last_user_update, @oldestDate)) < @threasholdDate
) as a
order by
  TableName
