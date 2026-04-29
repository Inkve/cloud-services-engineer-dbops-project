# dbops-project
Исходный репозиторий для выполнения проекта дисциплины "DBOps"

Создайте нового пользователя PostgreSQL и выдайте ему права на все таблицы в базе store
```sql
CREATE DATABASE store;
CREATE USER "system_user" WITH PASSWORD 'system_password';
ALTER DATABASE store OWNER TO "system_user";
```

---

Напишите запрос, который покажет, какое количество сосисок было продано за каждый день предыдущей недели.

```sql
SELECT o.date_created, SUM(op.quantity)
FROM orders AS o
JOIN order_product AS op ON o.id = op.order_id
WHERE o.status = 'shipped'
  AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created;
```

---

Замер времени до создания индексов (миграции №1-3)

Время выполнения:
```sql
Time: 32397.393 ms (00:32.397)
```

EXPLAIN (ANALYZE):
```sql
Finalize GroupAggregate  (cost=266142.37..266165.43 rows=91 width=12) (actual time=32643.710..32651.386 rows=7 loops=
1)
   Group Key: o.date_created
   ->  Gather Merge  (cost=266142.37..266163.61 rows=182 width=12) (actual time=32643.677..32651.350 rows=21 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=265142.35..265142.58 rows=91 width=12) (actual time=32609.957..32609.961 rows=7 loops=3)
               Sort Key: o.date_created
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=265138.48..265139.39 rows=91 width=12) (actual time=32609.922..32609.927 rows=7 loops=3)
                     Group Key: o.date_created
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Parallel Hash Join  (cost=148322.65..264621.14 rows=103467 width=8) (actual time=15861.158..32589.161 rows=83424 loops=3)
                           Hash Cond: (op.order_id = o.id)
                           ->  Parallel Seq Scan on order_product op  (cost=0.00..105361.13 rows=4166613 width=12) (actual time=1.335..15564.355 rows=3333333 loops=3)
                           ->  Parallel Hash  (cost=147029.29..147029.29 rows=103469 width=12) (actual time=15858.797..15858.798 rows=83424 loops=3)
                                 Buckets: 262144  Batches: 1  Memory Usage: 13824kB
                                 ->  Parallel Seq Scan on orders o  (cost=0.00..147029.29 rows=103469 width=12) (actual time=17.392..15814.179 rows=83424 loops=3)
                                       Filter: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                                       Rows Removed by Filter: 3249909
 Planning Time: 0.298 ms
 JIT:
   Functions: 54
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 4.972 ms, Inlining 0.000 ms, Optimization 1.733 ms, Emission 46.668 ms, Total 53.373 ms
 Execution Time: 32652.663 ms
```

В миграции migrations/V004__create_index.sql созданы два индекса:

```sql
CREATE INDEX IF NOT EXISTS idx_orders_status_date_created
    ON orders (status, date_created) INCLUDE (id);

CREATE INDEX IF NOT EXISTS idx_order_product_order_id
    ON order_product (order_id) INCLUDE (quantity);
```

Замер после применения миграции №4

Время выполнения:
```sql
Time: 1721.000 ms (00:01.721)
```

EXPLAIN (ANALYZE):
```sql
Finalize GroupAggregate  (cost=1001.02..143466.19 rows=91 width=12) (actual time=3118.591..3122.144 rows=7 loops=1)
   Group Key: o.date_created
   ->  Gather Merge  (cost=1001.02..143464.37 rows=182 width=12) (actual time=3117.809..3122.106 rows=16 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial GroupAggregate  (cost=1.00..142443.34 rows=91 width=12) (actual time=1212.821..2439.985 rows=5 loops=3)
               Group Key: o.date_created
               ->  Nested Loop  (cost=1.00..141925.09 rows=103468 width=8) (actual time=30.209..2430.842 rows=83424 loops=3)
                     ->  Parallel Index Only Scan using idx_orders_status_date_created on orders o  (cost=0.56..29984.42 rows=103468 width=12) (actual time=6.162..898.532 rows=83424 loops=3)
                           Index Cond: ((status = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                           Heap Fetches: 22365
                     ->  Index Only Scan using idx_order_product_order_id on order_product op  (cost=0.43..1.07 rows=1 width=12) (actual time=0.018..0.018 rows=1 loops=250272)
                           Index Cond: (order_id = o.id)
                           Heap Fetches: 0
 Planning Time: 27.294 ms
 JIT:
   Functions: 27
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 30.505 ms, Inlining 0.000 ms, Optimization 0.592 ms, Emission 12.361 ms, Total 43.458 ms
 Execution Time: 3122.654 ms
```

По `EXPLAIN (ANALYZE)` время выполнения сократилось с 32652.663 ms до 3122.654 ms

По `\timing` время выполнения сократилось с 32397.393 ms до 1721.000 ms