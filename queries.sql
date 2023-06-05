-- #1 --
explain analyze
select "Н_ТИПЫ_ВЕДОМОСТЕЙ"."ИД", "Н_ВЕДОМОСТИ"."ЧЛВК_ИД"
from "Н_ТИПЫ_ВЕДОМОСТЕЙ"
join "Н_ВЕДОМОСТИ" on "Н_ТИПЫ_ВЕДОМОСТЕЙ"."ИД" = "Н_ВЕДОМОСТИ"."ВЕД_ИД"
where "Н_ТИПЫ_ВЕДОМОСТЕЙ"."НАИМЕНОВАНИЕ" > 'Ведомость' and "Н_ВЕДОМОСТИ"."ЧЛВК_ИД" < 163249 and "Н_ВЕДОМОСТИ"."ЧЛВК_ИД" > 142390;


Hash Join  (cost=623.44..5484.01 rows=1 width=8) (actual time=16.605..16.608 rows=0 loops=1)
"  Hash Cond: (""Н_ВЕДОМОСТИ"".""ВЕД_ИД"" = ""Н_ТИПЫ_ВЕДОМОСТЕЙ"".""ИД"")"
"  ->  Bitmap Heap Scan on ""Н_ВЕДОМОСТИ""  (cost=622.39..5364.62 rows=45082 width=8) (actual time=2.130..10.094 rows=45611 loops=1)"
"        Recheck Cond: ((""ЧЛВК_ИД"" < 163249) AND (""ЧЛВК_ИД"" > 142390))"
        Heap Blocks: exact=1652
"        ->  Bitmap Index Scan on ""ВЕД_ЧЛВК_FK_IFK""  (cost=0.00..611.11 rows=45082 width=0) (actual time=1.905..1.905 rows=45611 loops=1)"
"              Index Cond: ((""ЧЛВК_ИД"" < 163249) AND (""ЧЛВК_ИД"" > 142390))"
  ->  Hash  (cost=1.04..1.04 rows=1 width=4) (actual time=0.020..0.021 rows=2 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 9kB
"        ->  Seq Scan on ""Н_ТИПЫ_ВЕДОМОСТЕЙ""  (cost=0.00..1.04 rows=1 width=4) (actual time=0.014..0.016 rows=2 loops=1)"
"              Filter: ((""НАИМЕНОВАНИЕ"")::text > 'Ведомость'::text)"
              Rows Removed by Filter: 1
Planning Time: 0.167 ms
Execution Time: 16.650 ms


-- #2 --
explain analyze
select "Н_ЛЮДИ"."ИМЯ", "Н_ОБУЧЕНИЯ"."ЧЛВК_ИД", "Н_УЧЕНИКИ"."НАЧАЛО"
from "Н_ЛЮДИ"
right join "Н_ОБУЧЕНИЯ" on "Н_ЛЮДИ"."ИД" = "Н_ОБУЧЕНИЯ"."ЧЛВК_ИД"
right join "Н_УЧЕНИКИ" on "Н_ОБУЧЕНИЯ"."ВИД_ОБУЧ_ИД" = "Н_УЧЕНИКИ"."ИД"
where "Н_ЛЮДИ"."ОТЧЕСТВО" > 'Сергеевич' and "Н_ОБУЧЕНИЯ"."НЗК" < '933232';

Nested Loop  (cost=169.65..308.01 rows=281 width=25) (actual time=2.997..5.021 rows=284 loops=1)
  ->  Hash Join  (cost=169.35..297.91 rows=281 width=21) (actual time=2.966..4.856 rows=284 loops=1)
"        Hash Cond: (""Н_ОБУЧЕНИЯ"".""ЧЛВК_ИД"" = ""Н_ЛЮДИ"".""ИД"")"
"        ->  Seq Scan on ""Н_ОБУЧЕНИЯ""  (cost=0.00..119.76 rows=3346 width=8) (actual time=0.012..1.514 rows=3347 loops=1)"
"              Filter: ((""НЗК"")::text < '933232'::text)"
              Rows Removed by Filter: 1674
        ->  Hash  (cost=163.97..163.97 rows=430 width=17) (actual time=2.890..2.891 rows=430 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 30kB
"              ->  Seq Scan on ""Н_ЛЮДИ""  (cost=0.00..163.97 rows=430 width=17) (actual time=0.023..2.798 rows=430 loops=1)"
"                    Filter: ((""ОТЧЕСТВО"")::text > 'Сергеевич'::text)"
                    Rows Removed by Filter: 4688
  ->  Memoize  (cost=0.30..1.04 rows=1 width=12) (actual time=0.000..0.000 rows=1 loops=284)
"        Cache Key: ""Н_ОБУЧЕНИЯ"".""ВИД_ОБУЧ_ИД"""
        Cache Mode: logical
        Hits: 282  Misses: 2  Evictions: 0  Overflows: 0  Memory Usage: 1kB
"        ->  Index Scan using ""УЧЕН_PK"" on ""Н_УЧЕНИКИ""  (cost=0.29..1.03 rows=1 width=12) (actual time=0.014..0.014 rows=1 loops=2)"
"              Index Cond: (""ИД"" = ""Н_ОБУЧЕНИЯ"".""ВИД_ОБУЧ_ИД"")"
Planning Time: 1.942 ms
Execution Time: 5.126 ms


---------------------------------

explain analyze
with max_score as (
select max(case в."ОЦЕНКА" when 'зачет' then 5 when 'незач' then 2 end) as max_score
from "Н_УЧЕНИКИ" у
inner join "Н_ОБУЧЕНИЯ" о on о."ЧЛВК_ИД" = у."ЧЛВК_ИД"
inner join "Н_ВЕДОМОСТИ" в on в."ЧЛВК_ИД" = о."ЧЛВК_ИД"
where у."ГРУППА" = '3100'
)

select
у."ИД",
concat(л."ФАМИЛИЯ", ' ', л."ИМЯ", ' ', л."ОТЧЕСТВО") AS "ФИО",
avg(case в."ОЦЕНКА" when 'зачет' then 5 when 'незач' then 2 end) as "Ср_оценка"
from "Н_УЧЕНИКИ" у
inner join "Н_ОБУЧЕНИЯ" о on о."ЧЛВК_ИД" = у."ЧЛВК_ИД"
inner join "Н_ЛЮДИ" л on л."ИД" = о."ЧЛВК_ИД"
inner join "Н_ВЕДОМОСТИ" в on в."ЧЛВК_ИД" = л."ИД"
where у."ГРУППА" = '4100'
group by у."ИД", л."ФАМИЛИЯ", л."ИМЯ", л."ОТЧЕСТВО"
having avg(case в."ОЦЕНКА" when 'зачет' then 5 when 'незач' then 2 end) <= (
select max_score.max_score from max_score
)
order by у."ИД";

-- №2

explain analyze
with tempt as (
select case в."ОЦЕНКА" when 'зачет' then 5 when 'незач' then 2 end as score,
       у."ИД",
concat(л."ФАМИЛИЯ", ' ', л."ИМЯ", ' ', л."ОТЧЕСТВО") AS "ФИО", у."ГРУППА"
from "Н_УЧЕНИКИ" у
inner join "Н_ОБУЧЕНИЯ" о on о."ЧЛВК_ИД" = у."ЧЛВК_ИД"
inner join "Н_ВЕДОМОСТИ" в on в."ЧЛВК_ИД" = о."ЧЛВК_ИД"
inner join "Н_ЛЮДИ" л on л."ИД" = у."ИД"
where у."ГРУППА" IN ('3100','4100')
)

select
"ИД",
 "ФИО",
avg(score) as "Ср_оценка"
from tempt
where  "ГРУППА"= '4100'
group by "ИД", "ФИО"
having avg(case score when 5 then 5 when 2 then 2 end) <= (
select max(tempt.score) from tempt where "ГРУППА" = '3100'
)
order by "ИД";

-------------======== ОЖИДАНИЕ ========----------------

--      С " where у."ГРУППА" IN ('3100','4100') "       --

-- Сканирование Н_УЧЕНИКИ.ГРУППА + фильтр ('3100','4100')
-- Сканирование Н_ЛЮДИ
-- Джоин Н_ЛЮДИ.ИД = Н_УЧЕНИКИ.ИД
-- Джоин Н_ВЕДОМОСТИ.ЧЛВК_ИД = Н_ОБУЧЕНИЯ.ЧЛВК_ИД
-- Джоин Н_ОБУЧЕНИЯ.ЧЛВК_ИД = Н_УЧЕНИКИ.ЧЛВК_ИД
--
-- Агрегейт max - фильтр (tempt.score) для ГРУППА = '3100'
-- Фильтр? Сорт? - фильтр ГРУППА = '4100'




--      Без " where у."ГРУППА" IN ('3100','4100') "      --

-- Сканирование Н_ЛЮДИ
-- Сканирование Н_УЧЕНИКИ
-- Джоин Н_ЛЮДИ.ИД = Н_УЧЕНИКИ.ИД
-- Джоин Н_ВЕДОМОСТИ.ЧЛВК_ИД = Н_ОБУЧЕНИЯ.ЧЛВК_ИД
-- Джоин Н_ОБУЧЕНИЯ.ЧЛВК_ИД = Н_УЧЕНИКИ.ЧЛВК_ИД
--
-- Агрегейт max - фильтр (tempt.score) для ГРУППА = '3100'
-- Фильтр? Сорт? - фильтр ГРУППА = '4100'




-------------======== РЕАЛЬНОСТЬ ========----------------

--      С " where у."ГРУППА" IN ('3100','4100') "       --

GroupAggregate  (cost=1505.55..1506.34 rows=7 width=68) (actual time=4.838..4.841 rows=1 loops=1)
"  Group Key: tempt.""ИД"", tempt.""ФИО"""
  Filter: (avg(CASE tempt.score WHEN 5 THEN 5 WHEN 2 THEN 2 ELSE NULL::integer END) <= ($3)::numeric)
  CTE tempt
    ->  Nested Loop  (cost=555.28..1315.94 rows=4202 width=44) (actual time=0.829..3.847 rows=1440 loops=1)
          ->  Nested Loop  (cost=554.99..761.83 rows=94 width=65) (actual time=0.801..1.850 rows=13 loops=1)
                ->  Hash Join  (cost=554.71..719.32 rows=92 width=61) (actual time=0.772..1.777 rows=13 loops=1)
"                      Hash Cond: (""л"".""ИД"" = ""у"".""ИД"")"
"                      ->  Seq Scan on ""Н_ЛЮДИ"" ""л""  (cost=0.00..151.18 rows=5118 width=53) (actual time=0.007..0.485 rows=5118 loops=1)"
                      ->  Hash  (cost=549.44..549.44 rows=421 width=12) (actual time=0.588..0.588 rows=421 loops=1)
                            Buckets: 1024  Batches: 1  Memory Usage: 28kB
"                            ->  Bitmap Heap Scan on ""Н_УЧЕНИКИ"" ""у""  (cost=11.83..549.44 rows=421 width=12) (actual time=0.276..0.502 rows=421 loops=1)"
"                                  Recheck Cond: ((""ГРУППА"")::text = ANY ('{3100,4100}'::text[]))"
                                  Heap Blocks: exact=107
"                                  ->  Bitmap Index Scan on ""УЧЕН_ГП_FK_I""  (cost=0.00..11.72 rows=421 width=0) (actual time=0.257..0.257 rows=421 loops=1)"
"                                        Index Cond: ((""ГРУППА"")::text = ANY ('{3100,4100}'::text[]))"
"                ->  Index Only Scan using ""ОБУЧ_ЧЛВК_FK_I"" on ""Н_ОБУЧЕНИЯ"" ""о""  (cost=0.28..0.45 rows=1 width=4) (actual time=0.005..0.005 rows=1 loops=13)"
"                      Index Cond: (""ЧЛВК_ИД"" = ""у"".""ЧЛВК_ИД"")"
                      Heap Fetches: 0
"          ->  Index Scan using ""ВЕД_ЧЛВК_FK_IFK"" on ""Н_ВЕДОМОСТИ"" ""в""  (cost=0.29..4.88 rows=68 width=10) (actual time=0.008..0.090 rows=111 loops=13)"
"                Index Cond: (""ЧЛВК_ИД"" = ""о"".""ЧЛВК_ИД"")"
  InitPlan 2 (returns $3)
    ->  Aggregate  (cost=94.60..94.61 rows=1 width=4) (actual time=0.316..0.316 rows=1 loops=1)
          ->  CTE Scan on tempt tempt_1  (cost=0.00..94.55 rows=21 width=4) (actual time=0.001..0.230 rows=1337 loops=1)
"                Filter: ((""ГРУППА"")::text = '3100'::text)"
                Rows Removed by Filter: 103
  ->  Sort  (cost=95.01..95.06 rows=21 width=40) (actual time=4.481..4.487 rows=103 loops=1)
"        Sort Key: tempt.""ИД"", tempt.""ФИО"""
        Sort Method: quicksort  Memory: 39kB
        ->  CTE Scan on tempt  (cost=0.00..94.55 rows=21 width=40) (actual time=2.573..4.439 rows=103 loops=1)
"              Filter: ((""ГРУППА"")::text = '4100'::text)"
              Rows Removed by Filter: 1337
Planning Time: 1.072 ms
Execution Time: 5.008 ms


--      Без " where у."ГРУППА" IN ('3100','4100') "      --

GroupAggregate  (cost=23376.45..23419.58 rows=379 width=68) (actual time=105.516..105.524 rows=1 loops=1)
"  Group Key: tempt.""ИД"", tempt.""ФИО"""
  Filter: (avg(CASE tempt.score WHEN 5 THEN 5 WHEN 2 THEN 2 ELSE NULL::integer END) <= ($1)::numeric)
  CTE tempt
    ->  Hash Join  (cost=1362.60..12838.93 rows=232785 width=44) (actual time=10.228..87.814 rows=33275 loops=1)
"          Hash Cond: (""в"".""ЧЛВК_ИД"" = ""о"".""ЧЛВК_ИД"")"
"          ->  Seq Scan on ""Н_ВЕДОМОСТИ"" ""в""  (cost=0.00..6290.40 rows=222440 width=10) (actual time=0.008..20.946 rows=222440 loops=1)"
          ->  Hash  (cost=1297.84..1297.84 rows=5181 width=65) (actual time=10.189..10.194 rows=364 loops=1)
                Buckets: 8192  Batches: 1  Memory Usage: 101kB
                ->  Hash Join  (cost=385.13..1297.84 rows=5181 width=65) (actual time=4.529..10.051 rows=364 loops=1)
"                      Hash Cond: (""у"".""ЧЛВК_ИД"" = ""о"".""ЧЛВК_ИД"")"
                      ->  Hash Join  (cost=215.16..1050.47 rows=5118 width=61) (actual time=3.097..8.482 rows=360 loops=1)
"                            Hash Cond: (""у"".""ИД"" = ""л"".""ИД"")"
"                            ->  Seq Scan on ""Н_УЧЕНИКИ"" ""у""  (cost=0.00..774.11 rows=23311 width=12) (actual time=0.004..2.230 rows=23311 loops=1)"
                            ->  Hash  (cost=151.18..151.18 rows=5118 width=53) (actual time=2.215..2.216 rows=5118 loops=1)
                                  Buckets: 8192  Batches: 1  Memory Usage: 503kB
"                                  ->  Seq Scan on ""Н_ЛЮДИ"" ""л""  (cost=0.00..151.18 rows=5118 width=53) (actual time=0.006..1.102 rows=5118 loops=1)"
                      ->  Hash  (cost=107.21..107.21 rows=5021 width=4) (actual time=1.418..1.419 rows=5021 loops=1)
                            Buckets: 8192  Batches: 1  Memory Usage: 241kB
"                            ->  Seq Scan on ""Н_ОБУЧЕНИЯ"" ""о""  (cost=0.00..107.21 rows=5021 width=4) (actual time=0.005..0.763 rows=5021 loops=1)"
  InitPlan 2 (returns $1)
    ->  Aggregate  (cost=5240.57..5240.58 rows=1 width=4) (actual time=4.251..4.252 rows=1 loops=1)
          ->  CTE Scan on tempt tempt_1  (cost=0.00..5237.66 rows=1164 width=4) (actual time=0.158..4.157 rows=1337 loops=1)
"                Filter: ((""ГРУППА"")::text = '3100'::text)"
                Rows Removed by Filter: 31938
  ->  Sort  (cost=5296.94..5299.85 rows=1164 width=40) (actual time=101.215..101.222 rows=103 loops=1)
"        Sort Key: tempt.""ИД"", tempt.""ФИО"""
        Sort Method: quicksort  Memory: 39kB
        ->  CTE Scan on tempt  (cost=0.00..5237.66 rows=1164 width=40) (actual time=28.549..101.139 rows=103 loops=1)
"              Filter: ((""ГРУППА"")::text = '4100'::text)"
              Rows Removed by Filter: 33172
Planning Time: 1.078 ms
Execution Time: 106.123 ms