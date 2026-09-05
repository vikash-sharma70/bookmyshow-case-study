# BookMyShow Problem Solving Case Study

Coaching class assignment: entity/schema design (1NF → BCNF) and SQL for a
BookMyShow-style "pick theatre → pick date → see shows" flow.

- **Write-up (P1 + P2, tables, sample data, normalization proof):** [`ANSWER.md`](ANSWER.md)
- **Schema:** [`sql/01_schema.sql`](sql/01_schema.sql)
- **Sample data:** [`sql/02_sample_data.sql`](sql/02_sample_data.sql)
- **P2 query:** [`sql/03_p2_query.sql`](sql/03_p2_query.sql)

All SQL verified against a real MySQL 8.0 instance.

Run it yourself:

```bash
mysql -u root -p < sql/01_schema.sql
mysql -u root -p < sql/02_sample_data.sql
mysql -u root -p < sql/03_p2_query.sql
```
