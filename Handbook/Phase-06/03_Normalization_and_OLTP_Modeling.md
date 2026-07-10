# Normalization and OLTP Modeling

> Part of the **Enterprise Data & AI Architecture Handbook** · Phase-06 - Data Modeling & Warehousing · Chapter 03.
> Estimated study time: **45 min reading + ~3h labs**.
> **Prerequisite:** read [Dimensional Modeling](01_Dimensional_Modeling.md) first.

---

## Executive Summary

Normalization and OLTP modeling exist to preserve business correctness under concurrent change. They are not primarily about elegance, and they are not primarily about storage savings. They are about ensuring that when thousands of users, services, and workflows create, update, and cancel business transactions at the same time, the database remains the authoritative arbiter of truth. The central design question is not whether a schema looks academically pure. The central design question is whether the data model enforces the invariants that the business cannot afford to violate.

In normalized transactional systems, the most important decisions are identity, functional dependency boundaries, transaction scope, constraint design, and index design. Normal forms reduce update anomalies, but they do not eliminate the need for judgment. A design can be technically in third normal form and still be operationally poor if it causes lock amplification, forces too many cross-service transactions, or obscures the aggregate boundary that the application actually needs. Good OLTP modeling therefore balances formal normalization with workload reality.

In Azure-first enterprises, normalized OLTP systems commonly run on Azure SQL Database, Azure SQL Managed Instance, or Azure Database for PostgreSQL Flexible Server, backed by application tiers on App Service, AKS, Functions, or container platforms. The platform question is not simply SQL Server versus PostgreSQL. The bigger question is which service tier, isolation model, connection strategy, indexing posture, and schema-governance discipline fit the business transaction profile. OLTP success is usually decided by a handful of things: narrow transactions, trustworthy keys, correct constraints, predictable indexes, and strict migration discipline.

This chapter treats normalization as a production engineering tool, not as a classroom ritual. It covers 1NF through BCNF, keys and constraints, indexing, OLTP versus OLAP access patterns, denormalization trade-offs, and practical Azure SQL and PostgreSQL modeling. It also makes the boundary explicit: transactional models are optimized for state transitions and integrity, while analytical models such as [Dimensional Modeling](01_Dimensional_Modeling.md) are optimized for business comprehension and read efficiency. Conflating those roles is one of the most expensive recurring data architecture mistakes.

## Learning Objectives

By the end of this chapter you should be able to:

1. Explain why normalization exists and when its benefits materially outweigh denormalized convenience.
2. Apply 1NF, 2NF, 3NF, and BCNF to real transactional schemas instead of textbook toy examples.
3. Choose primary, foreign, candidate, surrogate, and natural keys appropriately for OLTP systems.
4. Design constraints and indexes that enforce business correctness without collapsing write performance.
5. Distinguish OLTP access patterns from OLAP access patterns and route them to different serving models.
6. Decide when limited denormalization is justified for transactional read paths.
7. Model Azure SQL and PostgreSQL transactional schemas with concurrency, cost, and fault tolerance in mind.
8. Recognize anti-patterns such as entity-attribute-value tables, missing foreign keys, and over-indexed hot paths.
9. Build schema migration, observability, and governance controls for production transactional databases.
10. Defend OLTP data-model design decisions in engineer, staff engineer, architect, and CTO reviews.

## Business Motivation

- Businesses lose money faster from incorrect transactions than from slow dashboards.
- Order capture, payment authorization, entitlement changes, claims updates, ledger postings, and inventory reservations require strict integrity under concurrency.
- Product teams need application schemas that survive feature growth without turning every change into a table rewrite or data backfill incident.
- Security and compliance teams need explicit keys, constraints, audit paths, and referential boundaries for regulated systems.
- Platform teams need predictable write latency and lock behavior so customer-facing workflows do not degrade during peak periods.
- Azure FinOps teams need to control transactional storage, compute, backup, and high-availability spend separately from analytical warehouse cost.
- Enterprises need a clear separation between systems that capture truth and systems that summarize truth.

## History and Evolution

- E. F. Codd formalized the relational model to reduce redundancy and improve logical consistency relative to file-based and hierarchical systems.
- Normal forms emerged as a practical way to reason about update anomalies, dependency structure, and lossless decomposition.
- Enterprise OLTP systems on mainframes and early RDBMS platforms proved that normalized designs could preserve correctness across large transactional workloads.
- The rise of client-server applications and later web systems exposed new operational stresses: hot rows, lock contention, retry storms, and schema-evolution pressure.
- ORMs made relational access more productive but often obscured the physical implications of joins, indexes, and transaction boundaries.
- Cloud databases shifted some concerns from server management to service selection, connection scaling, availability zones, and managed backup policies.
- Modern architecture now treats normalized OLTP models as one layer in a broader estate that also includes event streams, caches, search indexes, and analytical models.

## Why This Technology Exists

Normalization exists because data changes are expensive when information is duplicated in many places. If a customer address is copied into five tables and must be updated consistently, the system either pays a heavy transactional coordination cost or tolerates inconsistent truth. Normal forms reduce that risk by placing each fact where it functionally belongs and relating entities through keys rather than repeating mutable attributes.

OLTP modeling exists because business processes are sequences of small, correctness-sensitive state changes. When an order is placed, a seat is reserved, a payment is authorized, or a patient appointment is confirmed, the system must enforce rules immediately. Those rules include uniqueness, referential existence, valid state transitions, and concurrency expectations. A normalized relational design is the most battle-tested mechanism for expressing many of those rules close to the data.

This technology also exists because application-serving workloads are different from analytical workloads. OLTP systems optimize for short writes, point lookups, narrow updates, and bounded transactional consistency. OLAP and dimensional systems optimize for scans, aggregations, and business-oriented slicing. Systems that try to satisfy both with one schema typically satisfy neither well.

## Problems It Solves

| Problem | Normalization and OLTP modeling response | Enterprise signal that it is working |
|---|---|---|
| duplicate mutable data causes inconsistent updates | isolate facts into the right entities and relate them by keys | one business change updates one authoritative row set |
| concurrent writes violate business rules | express uniqueness, referential integrity, and check constraints in the database | duplicate orders, overlapping bookings, and invalid states are blocked |
| application teams add features without schema discipline | use normal forms and migration review to preserve dependency clarity | schema growth remains understandable and testable |
| operational workloads suffer from table scans | align indexes to point lookups and narrow range access | p95 transactional latency remains stable under peak load |
| analytical queries disrupt production writes | separate OLTP and OLAP patterns and publish downstream read models | dashboard usage no longer locks or saturates the order database |
| source-of-truth logic is duplicated across services | place critical invariants in the database as well as application code | services converge on the same constraints |
| denormalized shortcuts create silent anomalies | keep denormalization intentional and bounded | performance gains do not come with recurring correction scripts |

## Problems It Cannot Solve

- It cannot eliminate the need for good aggregate boundaries and service design.
- It is not the best model for analytical reporting, wide aggregates, or executive dashboards.
- It cannot rescue an application that opens long transactions, retries blindly, or holds locks across network calls.
- It does not automatically make queries fast; incorrect indexing and poor access patterns still fail.
- It should not be used as the only serving model for search-heavy, graph-like, or document-first experiences.
- It cannot replace domain stewardship for code tables, state machines, and reference semantics.
- It does not remove the need for eventing, caching, or asynchronous integration where those patterns fit better.

## Core Concepts

### 8.1 Relational entities, attributes, and dependencies

An OLTP schema starts by identifying entities that change independently and the functional dependencies that govern them. A customer has identifying attributes. An order has a lifecycle and business invariants. An order line depends on an order and a product. A payment authorization depends on an order and an external processor response. The model is correct when each attribute is stored in the relation whose key actually determines it.

Functional dependencies are not academic decoration. They are the reason the schema can reject anomalies. If `CustomerTier` really depends on `CustomerId`, storing it on `OrderHeader` creates duplicated mutable state. If `WarehouseTimezone` depends on `WarehouseId`, storing it on every inventory movement row invites inconsistency. Normalization exists to keep these dependencies honest.

### 8.2 First normal form (1NF)

First normal form requires atomic values and a consistent relation structure. No repeating groups. No comma-separated IDs. No multi-valued cell pretending to be a set. A table that stores `PhoneNumbers = '123,456,789'` is not merely untidy. It is operationally hostile because it blocks indexing, constraint enforcement, and reliable querying.

In production OLTP systems, 1NF also means resisting the temptation to encode structured payloads as generic text when the data participates in transactional rules. JSON columns can be useful for optional adjunct data, but they are poor substitutes for core relational attributes when those attributes must be keyed, validated, and joined.

### 8.3 Second normal form (2NF)

Second normal form removes partial dependency on part of a composite key. It matters most when a relation uses a composite primary key and some attributes depend on only one component of that key. For example, if `OrderLine` uses `(OrderId, LineNumber)` as key, product description does not belong on the line merely because the line references a product. Product description depends on `ProductId`, not on the full line key.

In practice, 2NF thinking stops teams from hiding master-data attributes inside transactional detail tables. That matters because partial dependency creates repeated updates and unpredictable correction cost.

### 8.4 Third normal form (3NF)

Third normal form removes transitive dependency. If `PostalCode` determines `City` and `State`, then storing `City` and `State` redundantly on a table keyed by `AddressId` may be justified only if the business intends those values to be captured as entered, not inferred from reference data. The modeler must know whether a value is authoritative, derived, or merely a denormalized convenience.

3NF is usually the practical baseline for transactional systems because it separates reference data from transaction data while keeping joins manageable. It does not imply that every code table needs its own theoretical micro-table. The point is dependency clarity, not table maximalism.

### 8.5 Boyce-Codd normal form (BCNF)

BCNF strengthens 3NF by requiring that every determinant be a candidate key. It becomes important when overlapping candidate keys or domain-specific rules create anomalies that 3NF can still allow. A classic example is a scheduling or assignment table where one business rule determines another attribute in a way not captured by the chosen primary key.

BCNF is useful because it surfaces hidden business rules. It can also be over-applied if teams ignore workload shape and force awkward decompositions that complicate every transaction path. The right approach is to treat BCNF as a diagnostic tool: use it to expose ambiguous determinants, then decide whether the additional decomposition improves the system enough to justify the operational cost.

### 8.6 Keys, constraints, and indexing

Keys identify rows and define relationships. Candidate keys represent valid ways to identify a row. The primary key is the chosen physical identifier. Foreign keys enforce relational existence. Surrogate keys simplify joins and stable identity, while natural keys preserve business meaning and often require unique constraints even when not selected as the primary key.

Constraints are the database's executable statement of business law:

- primary and unique constraints preserve identity,
- foreign keys preserve referential existence,
- check constraints preserve domain validity,
- default constraints preserve explicit initialization behavior.

Indexes are access-path structures, not integrity structures. They should reflect query and update patterns. In OLTP systems, the usual winning posture is a small clustered or primary access path, a limited set of narrow nonclustered indexes for hot queries, and ruthless suspicion toward every extra write-amplifying index.

### 8.7 OLTP versus OLAP access patterns

OLTP workloads are dominated by point lookups, narrow range reads, inserts, small updates, and short transactions. OLAP workloads are dominated by scans, joins across large historical volumes, group by operations, and aggregated reads. Normalized schemas fit OLTP because they minimize write anomalies. Analytical models such as [Dimensional Modeling](01_Dimensional_Modeling.md) fit OLAP because they minimize business-query complexity and scan cost.

If a team asks whether the order-entry schema should also power executive revenue reporting, the answer is usually no. Route the transaction workload and the analytical workload to separate serving paths.

### 8.8 Denormalization trade-offs

Denormalization is not heresy. It is a costed decision. It can reduce join count, simplify read paths, and improve latency for specific high-value queries. It also increases write complexity, data drift risk, and correction cost. The correct question is not whether denormalization is allowed. The correct question is which invariant is being traded for which latency benefit, and whether the trade is bounded and observable.

Valid denormalization patterns include read-only projections, computed summary tables, cached search documents, and carefully maintained redundant attributes with strong refresh rules. Invalid denormalization is ungoverned duplication that no one owns.

## Internal Working

### 9.1 Transaction path and state change

An OLTP request typically arrives from an application service, resolves one or more keys, validates business state, executes a narrow transaction, updates indexes and the transaction log, commits, and returns a result to the caller. The schema's job is to make the legal state transition easy and the illegal state transition impossible or immediately visible.

### 9.2 Constraint evaluation

When an insert or update occurs, the database enforces uniqueness, foreign-key existence, and check constraints before commit. This is one reason transactional schemas should not offload all validation to the application. Application validation improves user experience. Database validation preserves truth under concurrency and multi-client access.

### 9.3 Index maintenance and write amplification

Every insert or update on an indexed column must update the corresponding index structures. That is why over-indexing punishes OLTP systems. The more secondary indexes a hot table has, the more work every write does. Good OLTP design treats index count as a recurring operational budget, not a free optimization knob.

### 9.4 Locking, versioning, and contention

Transactional databases coordinate concurrent access using locks, row versions, or both depending on engine settings and isolation level. A logically correct schema can still behave poorly if a hot counter row, monotonically increasing clustered key hotspot, or long-running transaction causes contention. Modeling and access pattern design must therefore consider not only logical dependencies but also concurrency shape.

### 9.5 Query planning and access paths

The optimizer chooses plans based on statistics, indexes, and predicates. Poorly selective indexes, implicit conversions, and non-SARGable predicates can turn point lookups into scans. In normalized models, where joins are expected, good statistics and join-key indexing are essential. If the physical access path is weak, teams often blame normalization for problems actually caused by poor indexing or ORM-generated SQL.

### 9.6 Schema evolution

Schema changes in OLTP systems must preserve backward compatibility long enough for applications to roll safely. Adding nullable columns is easy. Changing key semantics is not. Mature teams use migration workflows that expand first, migrate data second, switch application behavior third, and contract only after all callers are aligned.

## Architecture

### 10.1 Azure-first reference architecture

The common Azure pattern is a transactional database on Azure SQL Database, Azure SQL Managed Instance, or Azure Database for PostgreSQL Flexible Server; application services on App Service, AKS, or Functions; secrets in Key Vault; connectivity through private endpoints; and telemetry through Azure Monitor, Log Analytics, and OpenTelemetry-enabled application traces. Read replicas, caches, or projection stores may sit alongside the primary OLTP database, but the normalized core remains the source of transactional truth.

### 10.2 Why this architecture works

This architecture separates transactional correctness from downstream read specialization. The OLTP database enforces invariants and commits state transitions. Projection paths handle search, analytics, and reporting. The platform scales operationally because each layer can be tuned for its real job rather than asking one schema to satisfy every latency and query-shape requirement.

### 10.3 ADR example: keep the transactional core normalized and publish read models separately

**Context:** A growing commerce platform has an order-entry system on Azure SQL Database. Product teams want faster account screens and executive reporting from the same schema. Some teams propose denormalizing order, customer, payment, and fulfillment attributes into a single large table to reduce application joins.

**Decision:** Keep the write model normalized to 3NF with explicit constraints and targeted indexes. Publish account-summary and reporting projections separately for read-heavy paths. Allow limited denormalization only in derived read models, not in the source-of-truth transaction tables.

**Consequences:** Write correctness, schema clarity, and change safety improve. Read-heavy use cases gain specialized projections. The organization must invest in projection pipelines and disciplined data contracts between OLTP and downstream consumers.

**Alternatives considered:**

1. Keep one denormalized operational table for everything: rejected because update anomalies and locking risk were too high.
2. Push all read optimization into the ORM layer: rejected because the root issue was data-model role confusion, not object mapping convenience.
3. Move the whole workload to an analytical model: rejected because analytical models are poor fits for transactional writes and state transitions.

## Components

| Component | Role | Azure-first implementation choices | Common failure mode |
|---|---|---|---|
| entity table | stores one business concept with its key and attributes | Azure SQL or PostgreSQL table | mixed responsibilities and duplicated mutable attributes |
| reference table | governs allowed codes, statuses, or types | same database or controlled shared schema | reference data changes without steward ownership |
| junction table | represents many-to-many relationships | narrow table with composite or surrogate key | hidden business rules omitted from the relationship grain |
| primary key | stable row identity | bigint identity, sequence, GUID, ULID pattern if justified | random wide keys as clustered path with no reason |
| unique constraint | preserves business uniqueness | alternate key on natural identifier | uniqueness enforced only in application code |
| foreign key | preserves referential existence | trusted FK with matching index posture | omitted for convenience, causing orphaned data |
| check constraint | enforces domain rules | simple value or range validation | complex business logic forced into brittle expression |
| index | accelerates point and range access | clustered or heap plus selective nonclustered indexes | index sprawl and write amplification |
| transaction log or WAL | durability and recovery | managed by Azure SQL or PostgreSQL engine | ignored until latency or storage alarms escalate |
| migration pipeline | evolves schema safely | DACPAC, Flyway-style process, Liquibase-style process, CI/CD | direct manual production edits |

## Metadata

Transactional models need operational metadata, not only column definitions.

| Metadata class | What to record | Why it matters |
|---|---|---|
| entity ownership | business owner and technical owner per schema area | supports change review and incident routing |
| key semantics | primary, candidate, natural, and surrogate key rationale | prevents accidental key drift |
| constraint inventory | unique, foreign-key, and check rules | makes invariants explicit and auditable |
| index purpose | which query or workflow each index supports | stops forgotten indexes from multiplying |
| retention and archive policy | how long hot transactional data remains in primary store | controls storage and performance drift |
| PII and sensitivity labels | customer, payment, HR, regulated flags | drives security controls and masking |
| migration history | who changed what and when | supports rollback planning and RCA |
| workload metadata | expected TPS, latency SLO, read/write mix | aligns schema choices to actual behavior |

If the platform cannot explain why a unique constraint or index exists, it will eventually either remove something critical or carry dead structures forever.

## Storage

OLTP storage design is about page efficiency, log pressure, and predictable hot-path access.

| Storage concern | Recommended posture | Notes |
|---|---|---|
| primary data layout | rowstore by default for OLTP | columnstore is usually wrong for hot write tables |
| key width | keep clustered or primary access path narrow | wide random keys increase index size and fragmentation |
| transaction log or WAL | monitor growth, flush latency, and backup behavior | write latency often appears here first |
| hot versus cold history | archive or partition old data deliberately | keeping ten years of hot OLTP detail in one table is rarely wise |
| fill factor and page splits | tune only where evidence justifies it | unnecessary tuning folklore causes churn |
| TOAST or overflow behavior in PostgreSQL | keep oversized text or JSON away from hot rows where possible | large row size hurts cache density |

Azure SQL and PostgreSQL both reward compact hot rows, predictable key patterns, and disciplined history management.

## Compute

| Workload class | Best Azure-first surface | Why it fits | Wrong default |
|---|---|---|---|
| small to medium application OLTP | Azure SQL Database General Purpose or Business Critical | managed operations and predictable relational behavior | deploying a large distributed data engine for simple order capture |
| application requiring near-instance SQL Server compatibility | Azure SQL Managed Instance | easier migration path and feature compatibility | forcing code to rewrite around missing edge features |
| PostgreSQL-first product workload | Azure Database for PostgreSQL Flexible Server | managed Postgres operations and HA options | self-hosting too early without an operational reason |
| bursty dev or low-volume workload | Azure SQL serverless or Burstable PostgreSQL where appropriate | cost-efficient non-prod or sporadic usage | using burstable tiers for mission-critical sustained TPS |
| read-heavy projection or reporting | separate read model, cache, or analytical store | protects write path | pushing executive reporting into the primary OLTP node |

Compute selection should follow transaction profile, compatibility needs, and operational maturity, not fashion.

## Networking

- Use private endpoints or private networking for Azure SQL, PostgreSQL Flexible Server, Key Vault, and monitoring sinks.
- Keep application services and databases region-aligned to minimize latency and cross-zone variance.
- Use connection pooling in the application tier; databases are not infinite socket brokers.
- For PostgreSQL, plan for a pooler such as pgBouncer where connection fan-out would otherwise overwhelm the server.
- Separate east-west service calls from database transactions so long network paths do not hold locks open.
- Document failover DNS behavior and client retry rules before a real incident happens.

Many "database problems" in OLTP systems are actually network and connection-management problems wearing SQL-shaped clothing.

## Security

| Concern | Recommended control |
|---|---|
| authentication | Microsoft Entra authentication where supported, or tightly managed database principals |
| secrets | Key Vault and managed identities instead of embedded connection strings |
| data at rest | TDE by default on Azure SQL; encrypted storage and TLS on PostgreSQL |
| sensitive columns | masking, application-layer tokenization, or Always Encrypted where justified |
| row access | row-level security only when business semantics truly require it |
| audit | SQL auditing, PostgreSQL logs, DDL history, and access trace retention |
| least privilege | separate migration, application, reporting, and operational roles |

The main security principle is simple: transactional systems contain the most business-critical and often most regulated truth. They deserve narrower access than downstream read models.

## Performance

Normalized schemas are not slow by definition. They become slow when the physical design ignores the transactional path.

- Index the actual lookup and join keys used in hot paths.
- Keep transactions short and free of network chatter.
- Avoid reading large object payloads on hot request paths unless necessary.
- Watch for ORM-generated N+1 query patterns and implicit full-table reads.
- Use covering or included columns only where a high-value query justifies extra write cost.
- Treat every added index as a write tax that must earn its keep.

| Pattern | Azure recommendation | Why |
|---|---|---|
| order lookup by customer and recent date | composite nonclustered index on `(CustomerId, OrderDate desc)` with selective includes | fast account screen without scanning |
| uniqueness on external payment ID | unique index on the processor reference | prevents duplicate charge records |
| soft-deleted data exclusion | filtered index in Azure SQL or partial index in PostgreSQL | avoids bloating active path indexes |
| high-contention queue or reservation table | narrow key, targeted covering index, and strict transaction scope | reduces latch and lock contention |

## Scalability

Scalability in OLTP systems is usually won by disciplined scope, not by wishful thinking.

- Scale up first when the workload is truly relational and consistency-sensitive.
- Split read models from write models before splitting the source-of-truth schema arbitrarily.
- Partition or archive history when table growth threatens maintenance windows and cache density.
- Shard only when one database boundary no longer fits and the domain model supports it.
- Keep cross-database or cross-shard transactions rare and explicit.

Many teams attempt premature horizontal partitioning because it sounds modern. Most would be better served by a cleaner normalized model, better indexes, and projection separation.

## Fault Tolerance

Fault tolerance for OLTP systems is about durability, recoverability, and predictable failover behavior.

- use built-in backups and test restore procedures regularly,
- choose zone-redundant or high-availability deployment where business RTO and RPO justify it,
- keep migration scripts idempotent and reversible where possible,
- separate operational failover from analytical replay,
- validate application retry behavior so failover does not become duplicate-write chaos.

Azure SQL active geo-replication, zone redundancy, and point-in-time restore capabilities are valuable only if the application layer knows how to reconnect safely and preserve idempotency semantics. PostgreSQL Flexible Server high availability and read replicas are similarly helpful only when operational runbooks and client behaviors are correct.

## Cost Optimization

The cheapest transactional database is not the smallest SKU. It is the one that preserves correctness without chronic firefighting, over-provisioning, or avoidable read abuse.

- Match Azure SQL tier to write latency, IO, and HA need instead of buying Business Critical by reflex.
- Use Azure SQL serverless or lower PostgreSQL tiers for development and sporadic internal workloads, not always-on hot production paths.
- Archive cold transactional history out of the hot serving path.
- Remove unused indexes and oversized included columns.
- Offload reporting and broad search queries to dedicated read models.

Worked FinOps example: suppose an order service runs on Azure SQL Database Business Critical 8 vCore because reporting queries and customer account pages share the same primary database. If that workload costs roughly $2,400 per month at an illustrative rate and the team can move reporting to a separate read model, trim unused indexes, and prove that the write path fits General Purpose 4 vCore plus a modest projection store, monthly platform cost may drop to roughly $1,100 to $1,400 while improving write latency consistency. The biggest savings often come from separating read abuse from the transaction core, not from heroic SQL micro-tuning.

## Monitoring

| Metric | Why it matters | Typical threshold |
|---|---|---|
| p95 and p99 transaction latency | user-facing health of the write path | alert when breaching SLO |
| deadlock count | reveals conflicting access patterns | low steady state, immediate investigation on spike |
| lock wait duration | shows contention and transaction scope issues | alert on sustained increase |
| CPU, memory, and log write pressure | core resource saturation indicators | alert before saturation causes queuing |
| index fragmentation and bloat trend | maintenance and storage efficiency | review on schedule, not by superstition |
| connection count and pool exhaustion | detects application-side misuse | alert when pool pressure nears limit |
| failed constraints and duplicate key errors | indicates caller bugs or attack/noise patterns | track by workflow and source |

## Observability

Observability should answer which business transaction slowed down, which query or lock caused it, and which deployment or workload change preceded it.

- Correlate application trace IDs with SQL statements or stored-procedure calls.
- Record migration version, application version, and schema version in deployment telemetry.
- Capture deadlock graphs, blocked-process reports, or wait-event distributions.
- Preserve business context in logs without leaking sensitive values.

### Operational response playbooks

| Signal | Detection query or rule | Likely cause | First remediation |
|---|---|---|---|
| deadlocks spike after a deployment | monitor deadlock count and blocked statements per release | changed access order or widened transaction scope | inspect changed code path, standardize access order, rollback if necessary |
| duplicate key violations surge on order insert | track unique constraint failures by endpoint | caller retry bug or missing idempotency token | disable aggressive retries, inspect request dedupe, protect downstream charge path |
| connection pool saturation occurs while CPU is modest | pool exhaustion metric and session count | leaked connections or long-running transactions | restart leaking application instance if needed, fix connection lifecycle, shorten transaction scope |

## Governance

Transactional schema governance is not bureaucracy. It is risk control.

- Require schema-review approval for new keys, dropped constraints, and denormalization requests.
- Keep DDL in source control and deploy through repeatable pipelines only.
- Assign stewardship for reference data and state machines.
- Record why each denormalized attribute or projection exists and when it may be removed.
- Separate production break-glass access from routine developer permissions.
- Review whether application code and database constraints express the same business invariants.

The most expensive governance failure is silent schema drift created by ad hoc production fixes that never flow back into versioned migrations.

## Trade-offs

| Choice | Advantages | Disadvantages | When to prefer it |
|---|---|---|---|
| highly normalized OLTP schema | strong integrity, low redundancy, clear write semantics | more joins, more modeling discipline, harder ad hoc reporting | transaction-heavy core systems |
| lightly denormalized transactional schema | simpler selected reads, fewer joins for hot screens | higher update anomaly risk and maintenance cost | bounded read optimization with explicit ownership |
| document-style flexible schema | fast iteration for sparse or variable payloads | weaker relational integrity and reporting difficulty | truly document-centric domains |
| analytical star schema | strong reporting usability | poor transactional fit | downstream OLAP, not write capture |

The right trade-off is role clarity. Use normalized OLTP for truth capture, not for every read experience.

## Decision Matrix

| Requirement | Normalized OLTP model | Denormalized OLTP-ish table | Dimensional model | Document model |
|---|---|---|---|---|
| transactional correctness | strong | medium | weak | medium |
| self-service analytics | weak | weak | strong | weak |
| schema evolution under strict invariants | strong | medium | medium | weak to medium |
| broad aggregate queries | weak directly | medium | strong | weak |
| auditability of state transitions | strong | medium | medium | medium |
| concurrency under many small writes | strong | medium | weak | medium |
| simplicity for one hot read path | medium | strong initially | weak | strong for document access |

Choose normalized OLTP when state transitions and integrity dominate. Choose dimensional models when business analytics dominate. Use denormalization only when the read benefit is specific, measured, and governable.

## Design Patterns

1. **Header and line pattern:** separate order header from order lines and keep line-level facts at the right grain.
2. **Reference table pattern:** move small controlled code sets into stewarded lookup tables with constraints.
3. **Junction table pattern:** model many-to-many relationships explicitly instead of encoding lists in one column.
4. **Outbox pattern:** persist integration events transactionally alongside state changes, then publish asynchronously.
5. **Optimistic concurrency token:** use `rowversion` in Azure SQL or an explicit version column in PostgreSQL-sensitive paths.
6. **Soft delete with filtered or partial indexes:** preserve history without polluting active-path access.
7. **Read projection pattern:** keep the normalized write model and publish a query-optimized read model separately.
8. **Natural key plus surrogate key pattern:** keep business uniqueness visible while using a stable narrow primary key.

## Anti-patterns

- One table containing order, customer, payment, shipment, and support attributes because it makes one screen easier.
- Entity-attribute-value schema for core transactional entities with strict business rules.
- Comma-separated foreign keys or JSON arrays standing in for junction tables.
- Missing foreign keys because the application "already validates that."
- Indexing every column used in any query without measuring write cost.
- GUID clustering on hot append tables without understanding fragmentation and page-split consequences.
- Reporting queries running directly on the primary OLTP database during peak business hours.
- Allowing ORMs to dictate schema boundaries instead of domain and workload design.

## Common Mistakes

- Treating every lookup table as if it deserves full normalization even when it creates needless join depth with no integrity gain.
- Using surrogate keys only and forgetting to preserve business uniqueness with alternate keys.
- Putting status-transition logic only in application code while the database accepts illegal states.
- Confusing archiving with deletion and keeping all historical detail hot forever.
- Designing indexes from ER diagrams instead of real query patterns.
- Ignoring the effect of long transactions on lock contention.
- Denormalizing first and discovering later that correction workflows are unmanageable.

## Best Practices

- Model the business transaction and aggregate boundary before designing tables.
- Normalize until update anomalies are controlled, then denormalize only with evidence.
- Enforce business uniqueness and referential rules in the database.
- Keep hot rows narrow and transactions short.
- Review every index as an ongoing write-cost commitment.
- Separate analytical and reporting read paths from the OLTP core.
- Use expand-migrate-contract schema evolution instead of breaking changes.
- Benchmark with production-like concurrency and data skew, not only isolated query timing.
- Document which invariants live in constraints, which in code, and why.

## Enterprise Recommendations

1. Standardize schema-review criteria for keys, constraints, and denormalization exceptions.
2. Treat the primary OLTP database as a protected system of record, not a general-purpose query endpoint.
3. Default to Azure SQL Database or Azure Database for PostgreSQL Flexible Server for new transactional workloads unless a stronger compatibility reason requires Managed Instance or self-hosting.
4. Require alternate keys for important business identifiers even when surrogate keys are used physically.
5. Use projection stores, caches, or downstream marts for heavy reads and analytics.
6. Instrument connection pools, deadlocks, and unique-constraint failures as first-class operational signals.
7. Keep production schema changes fully automated and versioned.
8. Review hot-table index posture and archive strategy quarterly.

## Azure Implementation

### 31.1 Recommended Azure service map

| Layer | Preferred Azure service | Notes |
|---|---|---|
| core transactional database | Azure SQL Database or Azure SQL Managed Instance | choose by compatibility and operational need |
| PostgreSQL-first transactional database | Azure Database for PostgreSQL Flexible Server | managed Postgres with HA and read replicas |
| application tier | App Service, AKS, Container Apps, or Functions | keep transaction scope in service layer disciplined |
| secrets and identity | Key Vault and managed identity | avoid embedded credentials |
| connectivity | private endpoints and VNet integration | reduce exposure and latency variance |
| observability | Azure Monitor, Log Analytics, Application Insights, OpenTelemetry | correlate app and DB signals |
| read projections | Azure Cache for Redis, separate SQL read model, or downstream analytical store | protect primary OLTP path |

### 31.2 Example Azure SQL transactional schema

```sql
create schema sales;
go

create table sales.Customer (
    CustomerId bigint identity(1,1) not null,
    CustomerNumber varchar(30) not null,
    EmailAddress varchar(320) not null,
    FullName nvarchar(200) not null,
    CustomerStatusCode varchar(20) not null,
    CreatedUtc datetime2 not null constraint DF_Customer_CreatedUtc default sysutcdatetime(),
    RowVersion rowversion not null,
    constraint PK_Customer primary key clustered (CustomerId),
    constraint UQ_Customer_CustomerNumber unique (CustomerNumber),
    constraint UQ_Customer_EmailAddress unique (EmailAddress)
);

create table sales.[Order] (
    OrderId bigint identity(1,1) not null,
    CustomerId bigint not null,
    OrderNumber varchar(30) not null,
    OrderStatusCode varchar(20) not null,
    OrderUtc datetime2 not null,
    CurrencyCode char(3) not null,
    TotalAmount decimal(18,2) not null,
    RowVersion rowversion not null,
    constraint PK_Order primary key clustered (OrderId),
    constraint UQ_Order_OrderNumber unique (OrderNumber),
    constraint FK_Order_Customer foreign key (CustomerId)
        references sales.Customer(CustomerId),
    constraint CK_Order_TotalAmount check (TotalAmount >= 0)
);

create table sales.OrderLine (
    OrderId bigint not null,
    LineNumber int not null,
    ProductId bigint not null,
    Quantity int not null,
    UnitPrice decimal(18,2) not null,
    constraint PK_OrderLine primary key clustered (OrderId, LineNumber),
    constraint FK_OrderLine_Order foreign key (OrderId)
        references sales.[Order](OrderId),
    constraint CK_OrderLine_Quantity check (Quantity > 0),
    constraint CK_OrderLine_UnitPrice check (UnitPrice >= 0)
);

create nonclustered index IX_Order_Customer_OrderUtc
    on sales.[Order] (CustomerId, OrderUtc desc)
    include (OrderNumber, OrderStatusCode, TotalAmount);

create nonclustered index IX_Order_ActiveStatus
    on sales.[Order] (OrderStatusCode, OrderUtc desc)
    where OrderStatusCode in ('Pending', 'Paid', 'ReadyToShip');
```

### 31.3 Example transactional write pattern

```sql
set xact_abort on;
begin tran;

declare @OrderId bigint;

insert into sales.[Order]
    (CustomerId, OrderNumber, OrderStatusCode, OrderUtc, CurrencyCode, TotalAmount)
values
    (@CustomerId, @OrderNumber, 'Pending', sysutcdatetime(), @CurrencyCode, @TotalAmount);

set @OrderId = scope_identity();

insert into sales.OrderLine (OrderId, LineNumber, ProductId, Quantity, UnitPrice)
select @OrderId, LineNumber, ProductId, Quantity, UnitPrice
from @OrderLines;

commit tran;
```

This pattern is intentionally narrow. It does not call an external payment API while the transaction is open.

### 31.4 Example PostgreSQL schema on Azure Database for PostgreSQL Flexible Server

```sql
create schema billing;

create table billing.account (
    account_id bigint generated always as identity primary key,
    account_number text not null unique,
    account_status_code text not null,
    created_utc timestamptz not null default now()
);

create table billing.subscription (
    subscription_id bigint generated always as identity primary key,
    account_id bigint not null references billing.account(account_id),
    external_subscription_id text not null,
    plan_code text not null,
    start_utc timestamptz not null,
    end_utc timestamptz null,
    is_deleted boolean not null default false,
    unique (external_subscription_id)
);

create index ix_subscription_account_start
    on billing.subscription (account_id, start_utc desc);

create index ix_subscription_active
    on billing.subscription (account_id)
    where is_deleted = false;
```

### 31.5 Example Bicep and CLI

```bicep
param location string = resourceGroup().location
param sqlAdminLogin string
@secure()
param sqlAdminPassword string

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: 'sql-oltp-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    publicNetworkAccess: 'Disabled'
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  name: '${sqlServer.name}/sqldb-orders-prod'
  location: location
  sku: {
    name: 'GP_S_Gen5_2'
    tier: 'GeneralPurpose'
  }
  properties: {
    zoneRedundant: false
  }
}
```

```bash
az group create --name rg-edai-oltp-prod --location westeurope
az sql server create --resource-group rg-edai-oltp-prod --name sql-oltp-prod-01 --location westeurope --admin-user sqladmin --admin-password <Password>
az sql db create --resource-group rg-edai-oltp-prod --server sql-oltp-prod-01 --name sqldb-orders-prod --service-objective GP_S_Gen5_2
az postgres flexible-server create --resource-group rg-edai-oltp-prod --name pg-orders-prod-01 --location westeurope --tier GeneralPurpose --sku-name Standard_D4ds_v5
```

### 31.6 Service-tier guidance

- Azure SQL General Purpose is the default starting point for many transactional systems with moderate IO and latency needs.
- Azure SQL Business Critical is justified when low-latency local SSD behavior, higher resilience, or peak write performance materially matter.
- Azure SQL serverless is usually for dev, test, or low-duty-cycle workloads rather than hot production order paths.
- Azure Database for PostgreSQL Flexible Server Burstable fits low-throughput environments; General Purpose or Memory Optimized fits sustained production workloads.
- Managed Instance is justified when SQL Server compatibility or cross-database feature needs are hard constraints.

## Open Source Implementation

An enterprise open-source OLTP stack usually centers on PostgreSQL with disciplined operational tooling rather than on a distributed data engine.

| Layer | Open-source choice | Notes |
|---|---|---|
| database | PostgreSQL | default relational engine for many product workloads |
| container runtime | Docker | consistent local and CI execution |
| orchestration | Kubernetes | only when operational scale justifies it |
| connection pooling | pgBouncer | protects PostgreSQL from excessive client fan-out |
| observability | Prometheus, Grafana, OpenTelemetry | capture wait, lock, replication, and app latency signals |
| infrastructure as code | Terraform | standardize database and network provisioning |
| CI/CD | GitHub Actions or Azure DevOps | apply migration pipelines and smoke tests |

Example PostgreSQL DDL for an operational booking model:

```sql
create table reservation.resource (
    resource_id bigint generated always as identity primary key,
    resource_code text not null unique,
    capacity integer not null check (capacity > 0)
);

create table reservation.booking (
    booking_id bigint generated always as identity primary key,
    resource_id bigint not null references reservation.resource(resource_id),
    booking_reference text not null unique,
    start_utc timestamptz not null,
    end_utc timestamptz not null,
    status_code text not null,
    check (end_utc > start_utc)
);

create index ix_booking_resource_time
    on reservation.booking (resource_id, start_utc);
```

Example GitHub Actions migration step:

```yaml
name: oltp-schema-validate
on:
  pull_request:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Start PostgreSQL
        run: docker run -d --name pg -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:16
      - name: Apply schema
        run: psql postgresql://postgres:postgres@localhost:5432/postgres -f db/schema.sql
      - name: Run smoke queries
        run: psql postgresql://postgres:postgres@localhost:5432/postgres -f db/smoke_tests.sql
```

## AWS Equivalent (comparison only)

| Azure pattern | AWS equivalent | Advantages | Disadvantages | Migration note |
|---|---|---|---|---|
| Azure SQL Database | Amazon RDS for SQL Server or Amazon Aurora where engine change is acceptable | mature managed relational offerings | engine semantics and feature compatibility differ | separate logical model from engine-specific features |
| Azure SQL Managed Instance | Amazon RDS for SQL Server | strong managed SQL Server option | less Azure-style identity and network integration if moving cloud | benchmark agent jobs, compatibility features, and HA behavior |
| Azure Database for PostgreSQL Flexible Server | Amazon RDS for PostgreSQL or Aurora PostgreSQL | broad ecosystem and strong Postgres support | parameter and replication behavior may differ | preserve schema and constraint intent, then retune indexes and settings |

The core migration principle is to move the logical transaction model first and the engine optimizations second.

## GCP Equivalent (comparison only)

| Azure pattern | GCP equivalent | Advantages | Disadvantages | Migration note |
|---|---|---|---|---|
| Azure SQL Database | Cloud SQL for SQL Server | managed SQL Server option on GCP | fewer feature and scale envelopes than some Azure SQL tiers | validate compatibility and failover behavior carefully |
| Azure Database for PostgreSQL Flexible Server | Cloud SQL for PostgreSQL or AlloyDB | strong Postgres path, especially AlloyDB for higher performance | operational posture and cost model differ | retest connection pooling, latency, and HA choices |
| Azure read projection patterns | GCP Memorystore or dedicated read services | similar separation of write and read concerns | cross-service integration details differ | keep projection contracts engine-agnostic |

GCP migration decisions should still preserve normalized write semantics and separate analytical read models from the OLTP core.

## Migration Considerations

- From legacy denormalized schemas: identify the true business entities and dependencies before decomposing tables.
- From on-premises SQL Server: decide whether compatibility requirements justify Managed Instance or whether Azure SQL Database is sufficient.
- From self-managed PostgreSQL: inventory extensions, HA patterns, and pooler assumptions before moving to Flexible Server.
- During decomposition: support dual-write or projection backfills cautiously; source-of-truth transitions are risky.
- For application cutovers: use expand-migrate-contract releases and preserve backward-compatible reads during rollout.
- For reporting consumers: redirect them to read models or analytical stores before tightening OLTP constraints.

## Mermaid Architecture Diagrams

```mermaid
flowchart LR
    A[Web Mobile API Clients] --> B[App Service or AKS Application Tier]
    B --> C[Azure SQL Database or PostgreSQL Flexible Server]
    B --> D[Redis Cache or Read Projection]
    C --> E[Private Endpoint and VNet]
    C --> F[Azure Monitor and Logs]
    C --> G[Backup and HA Services]
    C --> H[Downstream Event or Projection Pipeline]
```

```mermaid
erDiagram
    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ ORDER_LINE : contains
    ORDER ||--o{ PAYMENT_AUTHORIZATION : authorizes
    CUSTOMER {
        bigint CustomerId
        string CustomerNumber
        string EmailAddress
        string CustomerStatusCode
    }
    ORDER {
        bigint OrderId
        bigint CustomerId
        string OrderNumber
        string OrderStatusCode
        datetime OrderUtc
    }
    ORDER_LINE {
        bigint OrderId
        int LineNumber
        bigint ProductId
        int Quantity
        decimal UnitPrice
    }
```

```mermaid
sequenceDiagram
    participant U as User Request
    participant A as Application Service
    participant D as OLTP Database
    participant P as Projection or Event Handler

    U->>A: Submit order
    A->>D: Begin transaction and validate customer state
    A->>D: Insert order header and lines
    D-->>A: Commit success
    A->>P: Publish outbox event after commit
    P->>P: Update read model or downstream integration
    A-->>U: Return order confirmation
```

## End-to-End Data Flow

1. A client request enters the application tier with an idempotency token or business reference where appropriate.
2. The application resolves required keys and validates domain state.
3. The database transaction inserts or updates normalized entities and enforces constraints.
4. Indexes and log records are updated as part of the commit path.
5. The committed transaction returns success to the caller.
6. An outbox event or asynchronous projection process updates read models, search documents, or downstream consumers.
7. Monitoring records latency, lock behavior, and error outcomes.
8. Analytical or reporting consumers use downstream models instead of the primary OLTP tables for broad queries.

## Real-world Business Use Cases

| Use case | Why normalized OLTP fits | Typical downstream read path |
|---|---|---|
| e-commerce checkout | many short writes, strong order and payment invariants | order history projection and analytical sales mart |
| digital banking ledger postings | strict balance and state-transition integrity | reporting warehouse and regulatory extracts |
| claims intake and adjudication | controlled workflow state and referential rules | claims analytics mart and document search |
| SaaS subscription billing | entitlements, plans, invoices, and retries require consistent state | customer account read model and finance warehouse |
| appointment scheduling | uniqueness, overlap control, and cancellation semantics matter | operational dashboards and utilization analytics |
| inventory reservation | stock availability changes rapidly and must remain correct | fulfillment projections and supply-chain analytics |

## Industry Examples

| Industry | Typical normalized entities | Frequent indexing focus | Common modeling pitfall |
|---|---|---|---|
| retail | customer, order, order_line, payment, shipment | order lookup, customer recent activity | copying customer profile data onto every order row |
| banking | account, ledger_entry, transaction, counterparty | account history and status lookup | mixing balance snapshots with transaction rows |
| insurance | policy, claim, claimant, coverage, payment | policy status and claim workflow | embedding many mutable policy attributes on claim rows |
| healthcare | patient, encounter, appointment, provider | patient timeline and appointment lookup | storing repeated provider details in encounter rows |
| manufacturing | work_order, part, station, quality_event | work-order status and recent events | wide tables containing both master data and event data |

## Case Studies

### Case study 1: order platform recovery from denormalized sprawl

A retail platform stored order header data, customer contact details, fulfillment status, and payment state in one large operational table because the first account screen was easy to build that way. As the business grew, each order update rewrote many unrelated attributes, duplicate email corrections became painful, and report queries on the same table triggered lock escalation and latency spikes.

The redesign split customer, order, order line, and payment authorization into normalized entities with alternate keys and selective nonclustered indexes. Read projections served the account screen. The write path became simpler, duplicate corrections disappeared, and incident response improved because the ownership of each attribute became obvious.

### Case study 2: Azure SQL billing platform with targeted denormalization

A SaaS billing team used Azure SQL Database with a normalized core for account, subscription, invoice, and payment entities. Early complaints about slow account pages led some developers to propose copying subscription summary data back into the account row. Instead, the team kept the write model normalized and added a separately refreshed account summary table plus targeted covering indexes for recent activity.

This preserved write integrity while achieving the required p95 latency. The lesson was that many denormalization pressures are really read-model problems.

### Case study 3: failure story from missing foreign keys

A logistics application removed foreign keys during a migration because bulk loads were failing and developers wanted "more flexibility." Within weeks, orphaned shipment-stop records appeared, downstream invoices referenced non-existent shipments, and correction scripts became a weekly ritual. The platform had traded immediate convenience for systemic mistrust.

The recovery involved restoring referential constraints, fixing load ordering, and adding staging-validation steps for bulk import. The problem was not relational rigidity. The problem was operational impatience.

## Hands-on Labs

1. **Normalize an order system:** decompose a wide order table into customer, order, order line, and payment tables through 3NF.
2. **Constraint lab:** add primary, unique, foreign-key, and check constraints to an initially permissive schema, then test invalid inserts.
3. **Index lab:** benchmark a recent-orders account screen before and after selective composite indexes in Azure SQL or PostgreSQL.
4. **Projection lab:** publish a read-optimized account summary table without changing the normalized write model.

Acceptance criteria:

- every business identifier has an alternate-key decision,
- at least one check constraint and one foreign key actively reject bad data,
- hot queries use indexes instead of broad scans,
- heavy reporting queries are routed away from the primary OLTP path.

## Exercises

1. Decompose a table that stores customer name, customer address, order header, and order line data into 1NF through 3NF.
2. Identify whether a given dependency violates 2NF, 3NF, or BCNF.
3. Choose a primary key strategy for a subscription table and justify surrogate plus natural key handling.
4. Design a filtered index in Azure SQL or a partial index in PostgreSQL for active records only.
5. Explain why a ledger balance should not be stored only as an updatable column with no transaction detail.
6. Decide whether a reference code list belongs in a table or an enum-like application constant.
7. Explain when denormalizing customer tier onto an order table is acceptable and what controls are required.
8. Write a migration plan that renames a status column without breaking old application code.
9. Compare the OLTP schema with the corresponding analytical design you would publish to [Dimensional Modeling](01_Dimensional_Modeling.md).
10. Identify three signs that a slow transactional system has a workload-shape problem rather than a normalization problem.

## Mini Projects

1. **Commerce core:** build a normalized checkout schema with orders, lines, payments, and shipment entities plus projection tables for account screens.
2. **Subscription platform:** design accounts, subscriptions, plans, invoices, and payment retries on Azure SQL or PostgreSQL with constraint-driven integrity.
3. **Scheduling engine:** model resources, bookings, cancellations, and availability rules, then expose a denormalized search projection.

## Capstone Integration

This chapter fits into the handbook as the transactional counterpart to analytical modeling.

- Use normalized OLTP schemas to capture and protect business truth under concurrency.
- Use [Dimensional Modeling](01_Dimensional_Modeling.md) to publish analytical facts and dimensions derived from that truth.
- Keep the boundary explicit so transactional correctness does not get diluted by reporting convenience.
- Let projections, events, caches, and marts solve read specialization instead of corrupting the write model.

## Interview Questions

1. What problem does normalization solve in a transactional system?
2. Explain 1NF, 2NF, 3NF, and BCNF with operational examples.
3. Why should a surrogate primary key not replace the need for business uniqueness?
4. What is the difference between a foreign key and an index?
5. When is denormalization justified in an OLTP system?
6. Why are OLTP and OLAP access patterns poor roommates in the same schema?
7. What kinds of anomalies appear when foreign keys are omitted?
8. How would you detect that an index is helping reads but hurting writes too much?
9. Why should transactions stay short?
10. What is the purpose of a read projection or outbox pattern?

## Staff Engineer Questions

1. How do you decide whether a domain model should remain in one database or split across bounded contexts?
2. Under what conditions would you choose Azure SQL Managed Instance over Azure SQL Database?
3. How do you standardize index review so teams stop accumulating dead write-cost structures?
4. How would you benchmark whether a denormalization request solves the right problem?
5. How do you coordinate expand-migrate-contract releases across many application services?
6. What signals tell you an ORM-generated access pattern is undermining an otherwise good schema?
7. How would you design a multi-tenant transactional schema without compromising noisy-neighbor isolation?
8. When should the database enforce a rule, and when should the application own it?

## Architect Questions

1. Where should normalized OLTP systems sit relative to caches, event streams, search indexes, and analytical warehouses in the enterprise architecture?
2. Which business domains require strong relational integrity and which may tolerate more flexible persistence?
3. How do you keep product teams from using the transactional database as a reporting platform?
4. What migration path do you choose for a legacy denormalized monolith moving to Azure-managed relational services?
5. How do you make denormalization exceptions explicit and governable across many teams?
6. When does sharding become a data-model problem rather than only an infrastructure problem?
7. How do you align OLTP schema governance with privacy, retention, and regulatory requirements?
8. How do you ensure transactional models and downstream analytical models stay semantically aligned?

## CTO Review Questions

1. Which revenue-critical workflows currently depend on fragile or weakly constrained transactional schemas?
2. How much operational cost is being created by reporting and search queries running on the primary OLTP system?
3. Which data-correctness incidents could have been prevented by stronger keys or constraints?
4. Is the organization paying for oversized database tiers because the write model and read model are poorly separated?
5. Which domains justify investment in stricter relational modeling because correctness failure is commercially unacceptable?
6. What governance mechanism prevents ad hoc production schema changes from becoming permanent hidden debt?

## References

- Internal prerequisite chapter:
- [Dimensional Modeling](01_Dimensional_Modeling.md)
- Canonical sources to study separately:
- E. F. Codd, *A Relational Model of Data for Large Shared Data Banks*.
- C. J. Date, *An Introduction to Database Systems*.
- Fabian Pascal and related normalization literature for deeper dependency reasoning.
- Microsoft documentation for Azure SQL Database, Azure SQL Managed Instance, Azure Database for PostgreSQL Flexible Server, and Azure Monitor.
- PostgreSQL documentation for constraints, indexing, MVCC, and vacuum behavior.

## Further Reading

- Revisit [Dimensional Modeling](01_Dimensional_Modeling.md) to understand how transactional truth is reshaped into business-friendly analytical structures.
- Study database isolation levels, optimistic concurrency patterns, and outbox/event publication for transactional systems at scale.
- Study index internals, statistics maintenance, and query-plan analysis in both SQL Server and PostgreSQL.
- Study archival and retention strategies so OLTP systems do not become accidental historical warehouses.
- Study domain-driven aggregate design because a good normalized schema still depends on a coherent domain boundary.