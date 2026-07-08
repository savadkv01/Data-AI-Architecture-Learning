#requires -Version 5.1
<#
    generate_curriculum.ps1
    ------------------------
    Single source-of-truth generator for the
    "Enterprise Data & AI Architecture Handbook" GitHub Copilot prompt library.

    It emits:
      - .github/prompts/Phase-XX/NN_Topic.prompt.md   (the learning prompts)
      - .github/prompts/Phase-XX/README.md            (per-phase index)
      - .github/prompts/Resources/<Area>/*.prompt.md  (cross-cutting prompts)
      - README.md, ROADMAP.md, DEPENDENCY_GRAPH.md     (top-level index docs)

    Every prompt file instructs Copilot to produce exactly ONE standalone
    Markdown chapter with all 50 mandatory sections. Re-runnable / idempotent.
#>

$ErrorActionPreference = 'Stop'
$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$promptRoot = Join-Path $root '.github/prompts'

# ---------------------------------------------------------------------------
# Shared persona pool
# ---------------------------------------------------------------------------
$basePersonas = 'a Distinguished Engineer, a Google Staff Engineer, a Microsoft Principal Solution Architect, a Databricks Resident Solutions Architect, an OpenAI AI Platform Engineer, a TOGAF Enterprise Architect, a Chief Data Officer, a Chief AI Officer, and a University Professor'

# ---------------------------------------------------------------------------
# Prompt-file template (single-quoted here-string => no PowerShell interpolation).
# Placeholders are injected with -f:
#   {0} Title   {1} OutputMd   {2} Description   {3} Focus bullets
#   {4} Prereqs {5} Personas   {6} Phase Title   {7} Phase Id
#   {8} Chapter Id  {9} Study time
# ---------------------------------------------------------------------------
$template = @'
---
mode: agent
description: "{2}"
---

# GitHub Copilot Prompt — {0}

> Part of the **Enterprise Data & AI Architecture Handbook**.
> Phase: **{7} — {6}** - Chapter: **{8}** - Estimated study time: **{9}**

## 1. Author Persona
Write as a panel of world-class experts: {5}.
Adopt the voice of an internal enterprise engineering knowledge base
(Microsoft / Google / Netflix / Uber / Databricks internal wiki) — NOT an online course.

## 2. Single-File Output Contract
- Produce **exactly ONE** standalone Markdown file named `{1}`.
- The file MUST be fully self-contained and independently readable.
- The ONLY permitted external dependencies are hyperlink references to the prior
  chapters listed under "Prerequisites & Cross-References".
- Output MUST be Markdown only. Do NOT emit any commentary outside the file content.
- Begin the file with a single top-level heading: `# {0}`.

## 3. Chapter Scope
Cover the following concretely and in depth:
{3}

## 4. Prerequisites & Cross-References
{4}
Explicitly reference the earlier chapters above (using relative Markdown links) wherever
concepts build on them, so the reader can navigate the handbook coherently.

## 5. Mandatory Section Structure
The generated Markdown MUST contain ALL of the following top-level (`##`) sections,
in this exact order, with substantive content under each:

1. Executive Summary
2. Learning Objectives
3. Business Motivation
4. History and Evolution
5. Why This Technology Exists
6. Problems It Solves
7. Problems It Cannot Solve
8. Core Concepts
9. Internal Working
10. Architecture
11. Components
12. Metadata
13. Storage
14. Compute
15. Networking
16. Security
17. Performance
18. Scalability
19. Fault Tolerance
20. Cost Optimization
21. Monitoring
22. Observability
23. Governance
24. Trade-offs
25. Decision Matrix
26. Design Patterns
27. Anti-patterns
28. Common Mistakes
29. Best Practices
30. Enterprise Recommendations
31. Azure Implementation
32. Open Source Implementation
33. AWS Equivalent (comparison only)
34. GCP Equivalent (comparison only)
35. Migration Considerations
36. Mermaid Architecture Diagrams
37. End-to-End Data Flow
38. Real-world Business Use Cases
39. Industry Examples
40. Case Studies
41. Hands-on Labs
42. Exercises
43. Mini Projects
44. Capstone Integration
45. Interview Questions
46. Staff Engineer Questions
47. Architect Questions
48. CTO Review Questions
49. References
50. Further Reading

## 6. Platform Emphasis (STRICT RATIO)
- **~60% Azure** as the PRIMARY implementation platform. Name concrete services,
  SKUs/tiers, configuration, and CLI/Bicep/Terraform where relevant.
- **~30% enterprise open-source stack** (choose those relevant to this topic from:
  Docker, Kubernetes, Kafka, Spark, Delta Lake, Apache Iceberg, Apache Hudi, Flink,
  Airflow, dbt, MLflow, Ray, MinIO, Trino, DuckDB, ClickHouse, Superset, Grafana,
  Prometheus, OpenTelemetry, OpenMetadata, Apache Atlas, Great Expectations, Feast,
  LangChain, LlamaIndex, Qdrant, Milvus, Neo4j, PostgreSQL, Redis, Nginx, Terraform,
  GitHub Actions, Azure DevOps).
- **~10% AWS & GCP as COMPARISON ONLY**: present Azure service -> AWS equivalent ->
  GCP equivalent, with advantages, disadvantages, migration strategy, and selection
  criteria. Do NOT build full AWS/GCP implementations.

## 7. Depth & Rigor Requirements
- Real architectures, real case studies, real failure stories, and lessons learned.
- Explicit trade-offs and clear "when NOT to use this" guidance.
- At least one Architecture Decision Record (ADR) example (Context / Decision /
  Consequences / Alternatives).
- Enterprise governance, cost (FinOps), and security implications woven throughout.
- At least **3 Mermaid diagrams** (e.g., architecture, end-to-end data flow, and one
  sequence/state/ER diagram as appropriate to the topic).
- Concrete, runnable examples (code / config / SQL / CLI / IaC) where applicable.
- Interview questions must span four levels: engineer, staff engineer, architect, CTO.

## 8. Quality Bar
- Target senior -> lead -> staff -> principal -> architect readers with 8+ years of experience.
- Precise, high-signal, production-grade guidance. No filler, no marketing language.
- Every claim should be defensible in a Staff/Principal-level architecture review.

## 9. Output Rules (repeat)
- Return ONLY the complete Markdown content for `{1}`.
- Ensure the 50 mandatory sections are all present and correctly ordered.
'@

# ---------------------------------------------------------------------------
# Helper: write a single prompt file
# ---------------------------------------------------------------------------
function New-PromptFile {
    param(
        [string]$Dir, [string]$N, [string]$Title, [string]$Md, [string]$Desc,
        [string[]]$Focus, [string]$Prereq, [string]$Study, [string]$Personas,
        [string]$PhaseTitle, [string]$PhaseId
    )
    if (-not $Personas) { $Personas = $basePersonas }
    if (-not $Study)    { $Study = '45-60 minutes read + 3-6 hours hands-on' }
    if (-not $Prereq)   { $Prereq = 'None — this is a foundational entry point. It is safe to read this chapter first.' }
    $focusBullets = ($Focus | ForEach-Object { "- $_" }) -join "`n"
    $content = $template -f $Title, $Md, $Desc, $focusBullets, $Prereq, $Personas, $PhaseTitle, $PhaseId, $N, $Study
    $fileName = "{0}_{1}.prompt.md" -f $N, ($Title -replace '[^A-Za-z0-9]+','_').Trim('_')
    $path = Join-Path $Dir $fileName
    Set-Content -Path $path -Value $content -Encoding UTF8
    return $fileName
}

# ---------------------------------------------------------------------------
# SOURCE OF TRUTH: the phases and their chapters
# Each chapter: N, Title, Md (output filename), Desc, Study, Prereq, Focus[]
# ---------------------------------------------------------------------------
$phases = @(
  @{ Id='Phase-00'; Title='Foundations & Prerequisites'; Weeks='Weeks 1-3';
     Goal='Rebuild the computer-science and systems bedrock every architect relies on.'; Chapters=@(
    @{ N='01'; Title='Introduction and How To Use This Handbook'; Md='Introduction.md'; Study='30 minutes';
       Desc='Orientation, learning path, and how to work through the Enterprise Data & AI Architecture Handbook.';
       Prereq='None.'; Focus=@('The target career ladder: Senior -> Lead -> Staff -> Principal -> Data/Solution/Enterprise Architect -> Head of Data/AI -> CDO/CAIO','How the phases, dependency graph, and roadmap fit together','How to use each chapter: theory, labs, case studies, interview drills','Study cadence for a one-year intensive plan','How to self-assess readiness for each role level') },
    @{ N='02'; Title='Computer Science Fundamentals'; Md='Computer_Science_Fundamentals.md'; Study='60 min + 4h';
       Desc='Core CS foundations an architect must reason about: complexity, memory, encoding, and computation models.';
       Prereq='Read [Introduction](01_Introduction.prompt.md) first.'; Focus=@('Time/space complexity and its impact on data-system cost','Memory hierarchy, cache lines, locality of reference','Binary/text encodings, UTF-8, endianness, serialization','Computation models: batch, streaming, MapReduce, dataflow','Numerical precision, floating point, and data-quality implications') },
    @{ N='03'; Title='Operating Systems for Data Engineers'; Md='Operating_Systems.md'; Study='60 min + 4h';
       Desc='How OS internals (scheduling, memory, I/O, filesystems) shape data-platform performance.';
       Prereq='Depends on Phase-00/[Computer Science Fundamentals](02_Computer_Science_Fundamentals.prompt.md).'; Focus=@('Processes, threads, context switching, and CPU scheduling','Virtual memory, paging, page cache, huge pages','Filesystems, block vs object I/O, buffered vs direct I/O','Linux tooling for data workloads (cgroups, ulimits, NUMA)','How OS behavior surfaces as Spark/Kafka performance issues') },
    @{ N='04'; Title='Networking Fundamentals'; Md='Networking_Fundamentals.md'; Study='60 min + 4h';
       Desc='TCP/IP, DNS, TLS, load balancing, and their effect on distributed data systems.';
       Prereq='Depends on Phase-00/[Operating Systems](03_Operating_Systems.prompt.md).'; Focus=@('OSI/TCP-IP model, packets, MTU, latency vs bandwidth','DNS, HTTP/1.1 vs HTTP/2 vs HTTP/3, gRPC transport','TLS handshake, certificates, mTLS','Load balancing (L4/L7), proxies, service discovery','Network partitions and their role in distributed failures') },
    @{ N='05'; Title='Storage Systems Fundamentals'; Md='Storage_Systems_Fundamentals.md'; Study='60 min + 4h';
       Desc='Disks, SSDs, RAID, block/file/object storage, and durability guarantees.';
       Prereq='Depends on Phase-00/[Operating Systems](03_Operating_Systems.prompt.md).'; Focus=@('HDD vs SSD vs NVMe internals and IOPS/throughput','Block vs file vs object storage models','Durability, replication, erasure coding','Write-ahead logs, LSM-trees, B-trees','Consistency and caching in storage tiers') },
    @{ N='06'; Title='Concurrency and Parallelism'; Md='Concurrency_and_Parallelism.md'; Study='60 min + 4h';
       Desc='Threads, locks, actors, and data-parallel execution models underlying every engine.';
       Prereq='Depends on Phase-00/[Operating Systems](03_Operating_Systems.prompt.md).'; Focus=@('Concurrency vs parallelism, Amdahl and Universal Scalability Law','Locks, deadlocks, atomics, lock-free structures','Actor model, CSP, async I/O, event loops','Data parallelism, partitioning, shuffle','Backpressure and flow control') },
    @{ N='07'; Title='Data Structures and Algorithms for Data Engineering'; Md='Data_Structures_and_Algorithms.md'; Study='60 min + 5h';
       Desc='Probabilistic and disk-oriented data structures that power modern data systems.';
       Prereq='Depends on Phase-00/[Computer Science Fundamentals](02_Computer_Science_Fundamentals.prompt.md).'; Focus=@('Hash tables, sorting, external merge sort','Bloom filters, HyperLogLog, Count-Min sketch','B+ trees, LSM-trees, skip lists','Roaring bitmaps, tries, inverted indexes','Consistent hashing and rendezvous hashing') },
    @{ N='08'; Title='Distributed Systems Primer'; Md='Distributed_Systems_Primer.md'; Study='60 min + 5h';
       Desc='The vocabulary and mental models for reasoning about distributed data platforms.';
       Prereq='Depends on Phase-00/[Networking Fundamentals](04_Networking_Fundamentals.prompt.md) and [Concurrency and Parallelism](06_Concurrency_and_Parallelism.prompt.md).'; Focus=@('Why distribution: scale, availability, geo-locality','Failure models: crash, omission, Byzantine','Latency, throughput, tail latency, SLIs/SLOs','Idempotency, retries, at-least/at-most/exactly-once','Introduction to consistency and consensus') }
  )},

  @{ Id='Phase-01'; Title='Enterprise Architecture Foundations'; Weeks='Weeks 4-6';
     Goal='Think and communicate like an enterprise architect: frameworks, governance, and decisions.'; Chapters=@(
    @{ N='01'; Title='Enterprise Architecture Foundations'; Md='Enterprise_Architecture_Foundations.md'; Study='60 min + 3h';
       Desc='TOGAF, Zachman, and the discipline of enterprise architecture for data and AI.';
       Prereq='Depends on Phase-00/[Distributed Systems Primer](../Phase-00/08_Distributed_Systems_Primer.prompt.md).'; Focus=@('TOGAF ADM, Zachman, and architecture domains','Business, data, application, and technology architecture','Reference architectures and capability maps','Architecture principles and standards','Where a data/AI architect sits in the org') },
    @{ N='02'; Title='Architecture Governance'; Md='Architecture_Governance.md'; Study='45 min + 3h';
       Desc='Establishing and running architecture review boards, standards, and guardrails.';
       Prereq='Depends on Phase-01/[Enterprise Architecture Foundations](01_Enterprise_Architecture_Foundations.prompt.md).'; Focus=@('Architecture Review Boards and RFC processes','Tech radar, golden paths, paved roads','Standards, exceptions, and technical debt registers','Guardrails vs gates; policy as code','Measuring architecture health') },
    @{ N='03'; Title='Architecture Decision Records'; Md='Architecture_Decision_Records.md'; Study='45 min + 3h';
       Desc='Writing durable, reviewable ADRs that scale across large engineering organizations.';
       Prereq='Depends on Phase-01/[Architecture Governance](02_Architecture_Governance.prompt.md).'; Focus=@('ADR anatomy: context, decision, consequences, alternatives','Lightweight vs heavyweight decision records','Decision logs and traceability','Reversible (Type 2) vs irreversible (Type 1) decisions','Templates and tooling (MADR, Log4brains)') },
    @{ N='04'; Title='Solution Architecture Practice'; Md='Solution_Architecture_Practice.md'; Study='60 min + 4h';
       Desc='From requirements to a defensible solution design under real-world constraints.';
       Prereq='Depends on Phase-01/[Enterprise Architecture Foundations](01_Enterprise_Architecture_Foundations.prompt.md).'; Focus=@('Requirements, constraints, and quality attributes','Trade-off analysis (ATAM-style)','C4 model and views/viewpoints','Non-functional requirements as first-class citizens','Producing HLD and LLD artifacts') },
    @{ N='05'; Title='Domain Driven Design'; Md='Domain_Driven_Design.md'; Study='60 min + 4h';
       Desc='Bounded contexts, ubiquitous language, and strategic design for data platforms.';
       Prereq='Depends on Phase-01/[Solution Architecture Practice](04_Solution_Architecture_Practice.prompt.md).'; Focus=@('Strategic vs tactical DDD','Bounded contexts and context mapping','Aggregates, entities, value objects','Ubiquitous language and event storming','DDD as the backbone of Data Mesh domains') },
    @{ N='06'; Title='Business Capability Modeling'; Md='Business_Capability_Modeling.md'; Study='45 min + 3h';
       Desc='Mapping business capabilities to data products, platforms, and investment.';
       Prereq='Depends on Phase-01/[Enterprise Architecture Foundations](01_Enterprise_Architecture_Foundations.prompt.md).'; Focus=@('Capability maps and heat maps','Value streams and business motivation models','Linking capabilities to data domains','Investment and portfolio prioritization','Capability-based roadmapping') },
    @{ N='07'; Title='Technical Strategy and Roadmaps'; Md='Technical_Strategy_and_Roadmaps.md'; Study='60 min + 3h';
       Desc='Crafting multi-year technical strategy and executable roadmaps for data and AI.';
       Prereq='Depends on Phase-01/[Business Capability Modeling](06_Business_Capability_Modeling.prompt.md).'; Focus=@('Vision, strategy, and North Star metrics','Build vs buy vs partner decisions','Sequencing, dependencies, and bets','Communicating strategy to executives','Balancing innovation and reliability') }
  )},

  @{ Id='Phase-02'; Title='Distributed Systems Deep Dive'; Weeks='Weeks 7-10';
     Goal='Master the theory and practice that underpins every scalable data platform.'; Chapters=@(
    @{ N='01'; Title='Consensus and Coordination'; Md='Consensus_and_Coordination.md'; Study='75 min + 5h';
       Desc='Paxos, Raft, ZAB, and coordination services that keep distributed systems correct.';
       Prereq='Depends on Phase-00/[Distributed Systems Primer](../Phase-00/08_Distributed_Systems_Primer.prompt.md).'; Focus=@('The consensus problem and FLP impossibility','Paxos, Multi-Paxos, Raft, ZAB','Leader election and log replication','ZooKeeper, etcd, and Consul','Quorums and configuration changes') },
    @{ N='02'; Title='Replication and Consistency'; Md='Replication_and_Consistency.md'; Study='75 min + 5h';
       Desc='Replication strategies and the full spectrum of consistency models.';
       Prereq='Depends on Phase-02/[Consensus and Coordination](01_Consensus_and_Coordination.prompt.md).'; Focus=@('Leader-follower, multi-leader, leaderless replication','Sync vs async replication and durability','Consistency models: linearizable, sequential, causal, eventual','Read/write quorums and hinted handoff','Conflict resolution and CRDTs') },
    @{ N='03'; Title='Partitioning and Sharding'; Md='Partitioning_and_Sharding.md'; Study='60 min + 4h';
       Desc='Horizontal scaling through partitioning, rebalancing, and hot-spot avoidance.';
       Prereq='Depends on Phase-02/[Replication and Consistency](02_Replication_and_Consistency.prompt.md).'; Focus=@('Range vs hash vs directory partitioning','Consistent hashing and virtual nodes','Rebalancing and resharding strategies','Hot partitions and skew mitigation','Secondary indexes across partitions') },
    @{ N='04'; Title='CAP and PACELC'; Md='CAP_and_PACELC.md'; Study='45 min + 2h';
       Desc='Reasoning about availability, consistency, and latency trade-offs correctly.';
       Prereq='Depends on Phase-02/[Replication and Consistency](02_Replication_and_Consistency.prompt.md).'; Focus=@('CAP theorem — what it does and does not say','PACELC and the latency dimension','Tunable consistency in practice','Mapping real databases onto CAP/PACELC','Common CAP misconceptions') },
    @{ N='05'; Title='Distributed Transactions'; Md='Distributed_Transactions.md'; Study='75 min + 5h';
       Desc='2PC, sagas, and modern approaches to correctness across services.';
       Prereq='Depends on Phase-02/[CAP and PACELC](04_CAP_and_PACELC.prompt.md).'; Focus=@('ACID vs BASE','Two-phase and three-phase commit','Sagas: orchestration vs choreography','Outbox pattern and idempotency keys','Spanner/TrueTime-style external consistency') },
    @{ N='06'; Title='Time, Clocks and Ordering'; Md='Time_Clocks_and_Ordering.md'; Study='60 min + 3h';
       Desc='Logical clocks, vector clocks, and event ordering in distributed data.';
       Prereq='Depends on Phase-02/[Distributed Transactions](05_Distributed_Transactions.prompt.md).'; Focus=@('Physical clocks, NTP, clock skew','Lamport and vector clocks','Happens-before and causality','Hybrid logical clocks','Event-time vs processing-time in streaming') },
    @{ N='07'; Title='Fault Tolerance and Resilience'; Md='Fault_Tolerance_and_Resilience.md'; Study='60 min + 4h';
       Desc='Designing systems that degrade gracefully and recover automatically.';
       Prereq='Depends on Phase-02/[Consensus and Coordination](01_Consensus_and_Coordination.prompt.md).'; Focus=@('Failure detection and timeouts','Retries, circuit breakers, bulkheads','Replication and failover strategies','Chaos engineering','Graceful degradation and load shedding') },
    @{ N='08'; Title='Distributed Systems Case Studies'; Md='Distributed_Systems_Case_Studies.md'; Study='60 min + 3h';
       Desc='How Dynamo, Spanner, Kafka, and BigTable solved real distributed problems.';
       Prereq='Depends on all prior Phase-02 chapters.'; Focus=@('Amazon Dynamo and DynamoDB','Google Spanner and BigTable','Apache Kafka replication and ISR','Netflix and Uber resilience patterns','Lessons and failure post-mortems') }
  )},

  @{ Id='Phase-03'; Title='Cloud & Azure Architecture'; Weeks='Weeks 11-14';
     Goal='Design secure, scalable cloud foundations with Azure as the primary platform.'; Chapters=@(
    @{ N='01'; Title='Cloud Architecture Fundamentals'; Md='Cloud_Architecture_Fundamentals.md'; Study='60 min + 3h';
       Desc='Cloud service models, shared responsibility, and cloud-native design principles.';
       Prereq='Depends on Phase-02/[Distributed Systems Case Studies](../Phase-02/08_Distributed_Systems_Case_Studies.prompt.md).'; Focus=@('IaaS/PaaS/SaaS and shared responsibility','Regions, availability zones, and failure domains','Elasticity, autoscaling, and statelessness','Cloud-native 12-factor principles','Multi-tenancy models') },
    @{ N='02'; Title='Azure Core Architecture'; Md='Azure_Core_Architecture.md'; Study='75 min + 5h';
       Desc='Azure resource hierarchy, governance, and core building blocks for data platforms.';
       Prereq='Depends on Phase-03/[Cloud Architecture Fundamentals](01_Cloud_Architecture_Fundamentals.prompt.md).'; Focus=@('Management groups, subscriptions, resource groups','Azure RBAC, policies, and Blueprints','Core services map for data and AI','Regions, paired regions, availability zones','Cost management and tagging strategy') },
    @{ N='03'; Title='Azure Landing Zones'; Md='Azure_Landing_Zones.md'; Study='75 min + 5h';
       Desc='Enterprise-scale landing zones for governed, repeatable Azure adoption.';
       Prereq='Depends on Phase-03/[Azure Core Architecture](02_Azure_Core_Architecture.prompt.md).'; Focus=@('Cloud Adoption Framework and enterprise-scale','Platform vs application landing zones','Hub-and-spoke and Virtual WAN topologies','Identity, management, and connectivity subscriptions','Bicep/Terraform landing-zone accelerators') },
    @{ N='04'; Title='Azure Networking'; Md='Azure_Networking.md'; Study='75 min + 5h';
       Desc='VNets, private endpoints, and secure connectivity for data services.';
       Prereq='Depends on Phase-03/[Azure Landing Zones](03_Azure_Landing_Zones.prompt.md) and Phase-00/[Networking Fundamentals](../Phase-00/04_Networking_Fundamentals.prompt.md).'; Focus=@('VNets, subnets, NSGs, UDRs','Private Link and private endpoints for PaaS','ExpressRoute, VPN, and hybrid connectivity','Azure Firewall, DNS, and egress control','Securing Databricks/Synapse/Storage networking') },
    @{ N='05'; Title='Azure Compute and Containers'; Md='Azure_Compute_and_Containers.md'; Study='60 min + 4h';
       Desc='VMs, AKS, Container Apps, and Functions for data and AI workloads.';
       Prereq='Depends on Phase-03/[Azure Core Architecture](02_Azure_Core_Architecture.prompt.md).'; Focus=@('VM families and spot capacity','AKS architecture and node pools','Container Apps and Azure Functions','Serverless vs cluster compute trade-offs','GPU compute for AI workloads') },
    @{ N='06'; Title='Azure Storage Services'; Md='Azure_Storage_Services.md'; Study='60 min + 4h';
       Desc='ADLS Gen2, Blob, and storage tiers as the foundation of the lakehouse.';
       Prereq='Depends on Phase-00/[Storage Systems Fundamentals](../Phase-00/05_Storage_Systems_Fundamentals.prompt.md).'; Focus=@('Blob vs ADLS Gen2 hierarchical namespace','Access tiers, lifecycle, and immutability','Redundancy: LRS/ZRS/GRS/GZRS','Performance, throughput, and throttling','Security: SAS, RBAC, encryption, firewall') },
    @{ N='07'; Title='Azure Well-Architected Framework'; Md='Well_Architected_Framework.md'; Study='60 min + 3h';
       Desc='Reliability, security, cost, operations, and performance pillars applied to data.';
       Prereq='Depends on Phase-03/[Azure Core Architecture](02_Azure_Core_Architecture.prompt.md).'; Focus=@('The five WAF pillars for data platforms','Reliability targets and RTO/RPO','Security and identity baseline','Cost optimization and FinOps hooks','Operational excellence and reviews') },
    @{ N='08'; Title='Multi-Cloud and Hybrid Architecture'; Md='Multi_Cloud_and_Hybrid.md'; Study='60 min + 3h';
       Desc='When and how to span clouds and on-premises without accidental complexity.';
       Prereq='Depends on Phase-03/[Azure Landing Zones](03_Azure_Landing_Zones.prompt.md).'; Focus=@('Drivers and anti-drivers for multi-cloud','Azure Arc and hybrid control planes','Data gravity and egress economics','Portability vs deep native integration','Reference multi-cloud data topologies') }
  )},

  @{ Id='Phase-04'; Title='Storage Systems & Table Formats'; Weeks='Weeks 15-17';
     Goal='Understand file formats and open table formats that define the lakehouse.'; Chapters=@(
    @{ N='01'; Title='File Formats: Parquet, ORC, Avro'; Md='File_Formats.md'; Study='60 min + 4h';
       Desc='Row vs columnar formats and how they shape analytical performance.';
       Prereq='Depends on Phase-00/[Storage Systems Fundamentals](../Phase-00/05_Storage_Systems_Fundamentals.prompt.md).'; Focus=@('Row vs columnar layout','Parquet internals: row groups, pages, encodings','ORC and Avro use cases','Schema evolution across formats','Predicate pushdown and column pruning') },
    @{ N='02'; Title='Columnar Storage Internals'; Md='Columnar_Storage_Internals.md'; Study='60 min + 4h';
       Desc='Encoding, compression, and vectorized execution over columnar data.';
       Prereq='Depends on Phase-04/[File Formats](01_File_Formats.prompt.md).'; Focus=@('Dictionary, RLE, delta, bit-packing encodings','Compression codecs (Snappy, Zstd, GZIP)','Vectorized and SIMD execution','Statistics, zone maps, and min/max','Apache Arrow in-memory format') },
    @{ N='03'; Title='Object Storage and Data Lakes'; Md='Object_Storage_and_Data_Lakes.md'; Study='60 min + 3h';
       Desc='Building reliable data lakes on object storage and avoiding the data swamp.';
       Prereq='Depends on Phase-03/[Azure Storage Services](../Phase-03/06_Azure_Storage_Services.prompt.md).'; Focus=@('Object storage consistency and listing costs','Partitioning and small-file problems','Data lake zones and layout conventions','Metadata and manifest strategies','MinIO as an S3-compatible OSS lake') },
    @{ N='04'; Title='Delta Lake'; Md='Delta_Lake.md'; Study='75 min + 5h';
       Desc='ACID transactions, time travel, and performance on the lakehouse with Delta.';
       Prereq='Depends on Phase-04/[Object Storage and Data Lakes](03_Object_Storage_and_Data_Lakes.prompt.md).'; Focus=@('Delta transaction log and protocol','ACID, time travel, and MERGE','OPTIMIZE, Z-ORDER, liquid clustering','Deletion vectors and change data feed','Delta on Azure Databricks and Fabric') },
    @{ N='05'; Title='Apache Iceberg'; Md='Apache_Iceberg.md'; Study='75 min + 5h';
       Desc='Iceberg table format, hidden partitioning, and open catalog interoperability.';
       Prereq='Depends on Phase-04/[Delta Lake](04_Delta_Lake.prompt.md).'; Focus=@('Iceberg metadata: manifests, snapshots','Hidden partitioning and partition evolution','Schema evolution and time travel','REST catalog and engine interoperability','Iceberg on Azure and OSS engines') },
    @{ N='06'; Title='Apache Hudi'; Md='Apache_Hudi.md'; Study='60 min + 3h';
       Desc='Copy-on-write vs merge-on-read and incremental processing with Hudi.';
       Prereq='Depends on Phase-04/[Delta Lake](04_Delta_Lake.prompt.md).'; Focus=@('COW vs MOR table types','Record-level upserts and indexes','Incremental queries and timeline','Compaction and clustering','When Hudi beats Delta/Iceberg') },
    @{ N='07'; Title='Table Format Comparison and Selection'; Md='Table_Format_Comparison.md'; Study='45 min + 2h';
       Desc='A decision framework for choosing Delta vs Iceberg vs Hudi in the enterprise.';
       Prereq='Depends on Phase-04/[Delta Lake](04_Delta_Lake.prompt.md), [Apache Iceberg](05_Apache_Iceberg.prompt.md), and [Apache Hudi](06_Apache_Hudi.prompt.md).'; Focus=@('Feature-by-feature comparison matrix','Ecosystem and engine support','Interoperability (XTable/UniForm)','Vendor lock-in considerations','Selection criteria by workload') },
    @{ N='08'; Title='Compression and Encoding Strategies'; Md='Compression_and_Encoding.md'; Study='45 min + 2h';
       Desc='Tuning storage footprint and scan performance through encoding choices.';
       Prereq='Depends on Phase-04/[Columnar Storage Internals](02_Columnar_Storage_Internals.prompt.md).'; Focus=@('Codec trade-offs: ratio vs CPU','Sorting and clustering for compressibility','Column-level encoding tuning','Impact on network and cache','Benchmarking methodology') }
  )},

  @{ Id='Phase-05'; Title='Modern Data Engineering & Lakehouse'; Weeks='Weeks 18-22';
     Goal='Build the lakehouse and batch platforms at the heart of modern data engineering.'; Chapters=@(
    @{ N='01'; Title='Modern Data Stack Overview'; Md='Modern_Data_Stack_Overview.md'; Study='45 min + 2h';
       Desc='The components and topology of the modern data stack, end to end.';
       Prereq='Depends on Phase-04/[Table Format Comparison](../Phase-04/07_Table_Format_Comparison.prompt.md).'; Focus=@('Ingestion, storage, transform, serve, observe','ELT vs ETL','Warehouse vs lake vs lakehouse','Open vs managed component choices','Reference topology diagram') },
    @{ N='02'; Title='Lakehouse Architecture'; Md='Lakehouse_Architecture.md'; Study='75 min + 5h';
       Desc='Unifying warehouse and lake with open formats, ACID, and governance.';
       Prereq='Depends on Phase-05/[Modern Data Stack Overview](01_Modern_Data_Stack_Overview.prompt.md) and Phase-04/[Delta Lake](../Phase-04/04_Delta_Lake.prompt.md).'; Focus=@('Lakehouse principles and separation of storage/compute','Unified batch and streaming','Unity Catalog and open governance','Serving BI and ML from one platform','Azure Databricks + Fabric lakehouse') },
    @{ N='03'; Title='Medallion Architecture'; Md='Medallion_Architecture.md'; Study='60 min + 4h';
       Desc='Bronze/silver/gold layering for reliable, incremental data refinement.';
       Prereq='Depends on Phase-05/[Lakehouse Architecture](02_Lakehouse_Architecture.prompt.md).'; Focus=@('Bronze/silver/gold responsibilities','Idempotent, incremental loads','Data quality gates between layers','Schema enforcement and evolution','Serving marts and features') },
    @{ N='04'; Title='Apache Spark Internals'; Md='Apache_Spark_Internals.md'; Study='90 min + 6h';
       Desc='Catalyst, Tungsten, shuffle, and tuning for large-scale Spark workloads.';
       Prereq='Depends on Phase-00/[Concurrency and Parallelism](../Phase-00/06_Concurrency_and_Parallelism.prompt.md).'; Focus=@('Driver/executor model and DAG scheduling','Catalyst optimizer and AQE','Tungsten, codegen, and memory management','Shuffle, skew, and spill','Photon and performance tuning') },
    @{ N='05'; Title='Databricks Platform'; Md='Databricks_Platform.md'; Study='75 min + 6h';
       Desc='Azure Databricks architecture: clusters, jobs, Unity Catalog, and DLT.';
       Prereq='Depends on Phase-05/[Apache Spark Internals](04_Apache_Spark_Internals.prompt.md).'; Focus=@('Workspace, control plane, and data plane','Cluster types, pools, and Photon','Unity Catalog governance model','Delta Live Tables and Workflows','Security and networking on Azure') },
    @{ N='06'; Title='Azure Data Factory and Synapse'; Md='Azure_Data_Factory_and_Synapse.md'; Study='60 min + 4h';
       Desc='Orchestration and analytics with ADF pipelines and Synapse Analytics.';
       Prereq='Depends on Phase-05/[Medallion Architecture](03_Medallion_Architecture.prompt.md).'; Focus=@('ADF pipelines, datasets, integration runtimes','Mapping data flows vs Spark','Synapse dedicated vs serverless SQL','Linked services and secure connectivity','When to use ADF vs Databricks vs Fabric') },
    @{ N='07'; Title='Microsoft Fabric'; Md='Microsoft_Fabric.md'; Study='75 min + 5h';
       Desc='OneLake, Direct Lake, and the unified SaaS analytics platform.';
       Prereq='Depends on Phase-05/[Lakehouse Architecture](02_Lakehouse_Architecture.prompt.md).'; Focus=@('OneLake and shortcuts','Fabric workloads: Data Engineering, Warehouse, Real-Time','Direct Lake mode for Power BI','Capacity model and governance','Fabric vs Databricks vs Synapse positioning') },
    @{ N='08'; Title='dbt and Analytics Engineering'; Md='dbt_and_Transformation.md'; Study='60 min + 4h';
       Desc='Software-engineering discipline for SQL transformations with dbt.';
       Prereq='Depends on Phase-05/[Medallion Architecture](03_Medallion_Architecture.prompt.md).'; Focus=@('Models, refs, sources, and DAGs','Tests, snapshots, and documentation','Incremental models and materializations','dbt with Databricks/Synapse/Fabric','Analytics engineering workflow') },
    @{ N='09'; Title='Batch Pipeline Design'; Md='Batch_Pipeline_Design.md'; Study='60 min + 4h';
       Desc='Designing reliable, idempotent, backfillable batch data pipelines.';
       Prereq='Depends on Phase-05/[Azure Data Factory and Synapse](06_Azure_Data_Factory_and_Synapse.prompt.md).'; Focus=@('Idempotency and exactly-once semantics','Backfills and reprocessing','Partitioning and incremental watermarks','SLAs, retries, and alerting','Cost-aware scheduling') }
  )},

  @{ Id='Phase-06'; Title='Data Modeling & Warehousing'; Weeks='Weeks 23-25';
     Goal='Model data for analytics at scale with dimensional, vault, and semantic techniques.'; Chapters=@(
    @{ N='01'; Title='Dimensional Modeling'; Md='Dimensional_Modeling.md'; Study='60 min + 4h';
       Desc='Kimball star schemas, facts, and dimensions for analytics.';
       Prereq='Depends on Phase-05/[Batch Pipeline Design](../Phase-05/09_Batch_Pipeline_Design.prompt.md).'; Focus=@('Facts, dimensions, grain','Star vs snowflake schemas','Conformed dimensions and bus matrix','Additive/semi-additive/non-additive facts','Degenerate and junk dimensions') },
    @{ N='02'; Title='Data Vault 2.0'; Md='Data_Vault.md'; Study='60 min + 4h';
       Desc='Hubs, links, and satellites for auditable, scalable enterprise modeling.';
       Prereq='Depends on Phase-06/[Dimensional Modeling](01_Dimensional_Modeling.prompt.md).'; Focus=@('Hubs, links, satellites','Business keys and hash keys','Raw vault vs business vault','Loading patterns and parallelism','When Data Vault fits vs Kimball') },
    @{ N='03'; Title='Normalization and OLTP Modeling'; Md='Normalization_and_OLTP.md'; Study='45 min + 3h';
       Desc='Relational design, normal forms, and transactional workload modeling.';
       Prereq='Depends on Phase-06/[Dimensional Modeling](01_Dimensional_Modeling.prompt.md).'; Focus=@('1NF through BCNF','Keys, constraints, indexing','OLTP vs OLAP access patterns','Denormalization trade-offs','Azure SQL / PostgreSQL modeling') },
    @{ N='04'; Title='OLAP and Cube Modeling'; Md='OLAP_and_Cubes.md'; Study='45 min + 3h';
       Desc='Aggregations, cubes, and tabular models for interactive analytics.';
       Prereq='Depends on Phase-06/[Dimensional Modeling](01_Dimensional_Modeling.prompt.md).'; Focus=@('MOLAP/ROLAP/HOLAP','Tabular models and VertiPaq','Aggregations and pre-computation','Power BI datasets and DAX basics','Direct Lake vs import vs DirectQuery') },
    @{ N='05'; Title='Slowly Changing Dimensions'; Md='Slowly_Changing_Dimensions.md'; Study='45 min + 3h';
       Desc='Tracking history correctly with SCD types 0 through 6.';
       Prereq='Depends on Phase-06/[Dimensional Modeling](01_Dimensional_Modeling.prompt.md).'; Focus=@('SCD types 0-6','Effective dating and surrogate keys','MERGE-based SCD implementation','Late-arriving dimensions','SCD with Delta/Iceberg') },
    @{ N='06'; Title='Semantic Layer and Metrics'; Md='Semantic_Layer_and_Metrics.md'; Study='60 min + 3h';
       Desc='Centralized metrics definitions and the modern semantic layer.';
       Prereq='Depends on Phase-06/[OLAP and Cubes](04_OLAP_and_Cubes.prompt.md).'; Focus=@('Headless BI and metric stores','Consistent metric definitions','dbt Semantic Layer / MetricFlow','Power BI semantic models','Governance of metrics') },
    @{ N='07'; Title='Data Warehouse Architecture'; Md='Data_Warehouse_Architecture.md'; Study='60 min + 3h';
       Desc='End-to-end warehouse architecture, MPP internals, and workload management.';
       Prereq='Depends on Phase-06/[Dimensional Modeling](01_Dimensional_Modeling.prompt.md) and Phase-06/[Data Vault](02_Data_Vault.prompt.md).'; Focus=@('MPP distribution and shuffle','Synapse/Snowflake/BigQuery internals','Workload isolation and concurrency','Materialized views and result caching','Warehouse vs lakehouse convergence') }
  )},

  @{ Id='Phase-07'; Title='Streaming & Real-Time Analytics'; Weeks='Weeks 26-29';
     Goal='Design low-latency streaming and real-time analytics systems.'; Chapters=@(
    @{ N='01'; Title='Streaming Fundamentals'; Md='Streaming_Fundamentals.md'; Study='60 min + 3h';
       Desc='Event-time, windows, watermarks, and delivery semantics.';
       Prereq='Depends on Phase-02/[Time, Clocks and Ordering](../Phase-02/06_Time_Clocks_and_Ordering.prompt.md).'; Focus=@('Streams vs batch','Event-time vs processing-time','Windowing: tumbling, sliding, session','Watermarks and lateness','At-least/at-most/exactly-once') },
    @{ N='02'; Title='Apache Kafka'; Md='Apache_Kafka.md'; Study='90 min + 6h';
       Desc='Kafka internals: partitions, replication, consumer groups, and exactly-once.';
       Prereq='Depends on Phase-07/[Streaming Fundamentals](01_Streaming_Fundamentals.prompt.md) and Phase-02/[Replication and Consistency](../Phase-02/02_Replication_and_Consistency.prompt.md).'; Focus=@('Topics, partitions, offsets','Replication, ISR, and leader election','Producers, consumer groups, rebalancing','Exactly-once and transactions','Kafka Connect and Schema Registry') },
    @{ N='03'; Title='Azure Event Hubs and Stream Analytics'; Md='Azure_Event_Hubs_and_Stream_Analytics.md'; Study='60 min + 4h';
       Desc='Managed streaming ingestion and processing on Azure.';
       Prereq='Depends on Phase-07/[Apache Kafka](02_Apache_Kafka.prompt.md).'; Focus=@('Event Hubs partitions and throughput units','Kafka protocol compatibility','Stream Analytics jobs and queries','Capture to ADLS and integration','Event Hubs vs Kafka on Azure') },
    @{ N='04'; Title='Apache Flink'; Md='Apache_Flink.md'; Study='75 min + 5h';
       Desc='Stateful stream processing, checkpointing, and exactly-once with Flink.';
       Prereq='Depends on Phase-07/[Streaming Fundamentals](01_Streaming_Fundamentals.prompt.md).'; Focus=@('Dataflow model and operators','Managed state and state backends','Checkpointing and savepoints','Exactly-once and two-phase commit sinks','Flink vs Spark Structured Streaming') },
    @{ N='05'; Title='Spark Structured Streaming'; Md='Spark_Structured_Streaming.md'; Study='60 min + 4h';
       Desc='Micro-batch and continuous streaming on the lakehouse.';
       Prereq='Depends on Phase-05/[Apache Spark Internals](../Phase-05/04_Apache_Spark_Internals.prompt.md) and Phase-07/[Streaming Fundamentals](01_Streaming_Fundamentals.prompt.md).'; Focus=@('Micro-batch execution model','Stateful ops and watermarks','Checkpointing to Delta','Streaming joins and dedup','Trigger modes and latency tuning') },
    @{ N='06'; Title='Change Data Capture'; Md='Change_Data_Capture.md'; Study='60 min + 4h';
       Desc='Streaming database changes reliably with CDC patterns.';
       Prereq='Depends on Phase-07/[Apache Kafka](02_Apache_Kafka.prompt.md).'; Focus=@('Log-based vs query-based CDC','Debezium and connectors','Ordering, dedup, and tombstones','CDC into Delta/Iceberg','Azure SQL/Cosmos change feed') },
    @{ N='07'; Title='Real-Time Analytics: ClickHouse and Druid'; Md='Real_Time_Analytics.md'; Study='60 min + 4h';
       Desc='Sub-second analytical queries over high-velocity data.';
       Prereq='Depends on Phase-07/[Streaming Fundamentals](01_Streaming_Fundamentals.prompt.md).'; Focus=@('OLAP for streaming: ClickHouse, Druid, Pinot','Ingestion and indexing','Materialized views and rollups','Azure Data Explorer (Kusto)','Real-time dashboards and serving') },
    @{ N='08'; Title='Streaming Patterns and Delivery Semantics'; Md='Streaming_Patterns.md'; Study='45 min + 3h';
       Desc='Kappa vs Lambda, dedup, and end-to-end exactly-once design.';
       Prereq='Depends on all prior Phase-07 chapters.'; Focus=@('Lambda vs Kappa architecture','Idempotent producers and consumers','Dead-letter queues and replay','Schema evolution in streams','End-to-end exactly-once patterns') }
  )},

  @{ Id='Phase-08'; Title='Data Governance & Quality'; Weeks='Weeks 30-32';
     Goal='Make data trustworthy, discoverable, and compliant across the enterprise.'; Chapters=@(
    @{ N='01'; Title='Data Governance Foundations'; Md='Data_Governance_Foundations.md'; Study='60 min + 3h';
       Desc='Operating models, ownership, and policies for enterprise data governance.';
       Prereq='Depends on Phase-01/[Architecture Governance](../Phase-01/02_Architecture_Governance.prompt.md).'; Focus=@('Governance operating models','Ownership, stewardship, accountability','Policies, standards, and controls','DAMA-DMBOK domains','Governance metrics and maturity') },
    @{ N='02'; Title='Data Catalog and Lineage'; Md='Data_Catalog_and_Lineage.md'; Study='60 min + 3h';
       Desc='Discovery, lineage, and impact analysis across the data estate.';
       Prereq='Depends on Phase-08/[Data Governance Foundations](01_Data_Governance_Foundations.prompt.md).'; Focus=@('Technical vs business metadata','Column-level lineage','Automated harvesting','Search, tagging, glossaries','Purview / OpenMetadata / DataHub') },
    @{ N='03'; Title='Data Quality with Great Expectations'; Md='Data_Quality.md'; Study='60 min + 4h';
       Desc='Automated data quality testing and monitoring in pipelines.';
       Prereq='Depends on Phase-05/[Batch Pipeline Design](../Phase-05/09_Batch_Pipeline_Design.prompt.md).'; Focus=@('Dimensions of data quality','Expectations, suites, checkpoints','Great Expectations and Soda','Quality gates in CI/CD','Anomaly detection and alerting') },
    @{ N='04'; Title='Metadata Management: OpenMetadata and Atlas'; Md='Metadata_Management.md'; Study='60 min + 3h';
       Desc='Active metadata platforms and the metadata control plane.';
       Prereq='Depends on Phase-08/[Data Catalog and Lineage](02_Data_Catalog_and_Lineage.prompt.md).'; Focus=@('Metadata models and standards','OpenMetadata and Apache Atlas','Active metadata and automation','Metadata APIs and events','Federating metadata across tools') },
    @{ N='05'; Title='Master Data Management'; Md='Master_Data_Management.md'; Study='60 min + 3h';
       Desc='Golden records, entity resolution, and reference data management.';
       Prereq='Depends on Phase-08/[Data Governance Foundations](01_Data_Governance_Foundations.prompt.md).'; Focus=@('MDM styles: registry, consolidation, coexistence','Entity resolution and matching','Golden record survivorship','Reference data management','MDM and data mesh tension') },
    @{ N='06'; Title='Microsoft Purview'; Md='Microsoft_Purview.md'; Study='60 min + 4h';
       Desc='Unified governance, cataloging, and data security with Purview.';
       Prereq='Depends on Phase-08/[Data Catalog and Lineage](02_Data_Catalog_and_Lineage.prompt.md).'; Focus=@('Data Map, catalog, and scanning','Classification and sensitivity labels','Lineage across Azure services','DLP and access policies','Purview vs OSS catalogs') },
    @{ N='07'; Title='Data Contracts'; Md='Data_Contracts.md'; Study='45 min + 3h';
       Desc='Schema and SLA contracts that decouple producers and consumers.';
       Prereq='Depends on Phase-08/[Data Quality](03_Data_Quality.prompt.md).'; Focus=@('Contract anatomy: schema, semantics, SLA','Producer/consumer responsibilities','Schema Registry enforcement','Versioning and breaking changes','Contracts in data mesh') }
  )},

  @{ Id='Phase-09'; Title='DataOps, Platform Engineering & DevOps'; Weeks='Weeks 33-37';
     Goal='Operationalize data platforms with automation, IaC, and platform engineering.'; Chapters=@(
    @{ N='01'; Title='DataOps Foundations'; Md='DataOps_Foundations.md'; Study='60 min + 3h';
       Desc='Applying DevOps and lean principles to data pipelines and platforms.';
       Prereq='Depends on Phase-05/[Batch Pipeline Design](../Phase-05/09_Batch_Pipeline_Design.prompt.md).'; Focus=@('DataOps principles and lifecycle','CI/CD for data','Environments and promotion','Testing data pipelines','Observability and incident response') },
    @{ N='02'; Title='Platform Engineering'; Md='Platform_Engineering.md'; Study='60 min + 3h';
       Desc='Internal developer platforms, golden paths, and self-service for data teams.';
       Prereq='Depends on Phase-09/[DataOps Foundations](01_DataOps_Foundations.prompt.md).'; Focus=@('Platform-as-product mindset','Golden paths and paved roads','Internal developer platforms (Backstage)','Self-service provisioning','Platform team topologies') },
    @{ N='03'; Title='DevOps and CI/CD'; Md='DevOps_and_CICD.md'; Study='60 min + 4h';
       Desc='Pipelines, testing, and release strategies for data and AI systems.';
       Prereq='Depends on Phase-09/[DataOps Foundations](01_DataOps_Foundations.prompt.md).'; Focus=@('CI/CD with GitHub Actions and Azure DevOps','Build, test, package, deploy stages','Blue-green and canary releases','Secrets and artifact management','Trunk-based development') },
    @{ N='04'; Title='Infrastructure as Code with Terraform'; Md='Infrastructure_as_Code.md'; Study='75 min + 5h';
       Desc='Declarative infrastructure with Terraform and Bicep on Azure.';
       Prereq='Depends on Phase-03/[Azure Landing Zones](../Phase-03/03_Azure_Landing_Zones.prompt.md).'; Focus=@('Terraform state, modules, workspaces','Bicep and ARM comparison','Provisioning Azure data platforms','Policy as code and drift','GitOps for infrastructure') },
    @{ N='05'; Title='Containers with Docker'; Md='Containers_Docker.md'; Study='60 min + 4h';
       Desc='Container fundamentals and images for reproducible data workloads.';
       Prereq='Depends on Phase-00/[Operating Systems](../Phase-00/03_Operating_Systems.prompt.md).'; Focus=@('Namespaces, cgroups, union filesystems','Dockerfiles and multi-stage builds','Image security and registries (ACR)','Containerizing Spark/Python jobs','OCI standards') },
    @{ N='06'; Title='Kubernetes'; Md='Kubernetes.md'; Study='90 min + 6h';
       Desc='Kubernetes architecture and running data/AI workloads on AKS.';
       Prereq='Depends on Phase-09/[Containers Docker](05_Containers_Docker.prompt.md).'; Focus=@('Control plane and node components','Pods, deployments, services, ingress','StatefulSets, storage, and operators','Autoscaling (HPA/VPA/cluster/KEDA)','Spark/Kafka/ML operators on AKS') },
    @{ N='07'; Title='Orchestration with Airflow'; Md='Orchestration_Airflow.md'; Study='60 min + 4h';
       Desc='Authoring, scheduling, and operating pipelines with Airflow.';
       Prereq='Depends on Phase-05/[Batch Pipeline Design](../Phase-05/09_Batch_Pipeline_Design.prompt.md).'; Focus=@('DAGs, operators, sensors, hooks','Scheduling, backfills, catchup','Executors and scaling','Airflow vs ADF vs Dagster vs Prefect','Managed Airflow on Azure') },
    @{ N='08'; Title='GitOps and Environment Management'; Md='GitOps_and_Environments.md'; Study='45 min + 3h';
       Desc='Declarative, git-driven delivery and multi-environment strategy.';
       Prereq='Depends on Phase-09/[Infrastructure as Code](04_Infrastructure_as_Code.prompt.md) and [Kubernetes](06_Kubernetes.prompt.md).'; Focus=@('GitOps principles and Argo CD/Flux','Environment promotion and config','Secrets management (Key Vault, SOPS)','Progressive delivery','Auditability and rollback') }
  )},

  @{ Id='Phase-10'; Title='Security, Identity & Compliance'; Weeks='Weeks 38-40';
     Goal='Secure data and AI platforms with zero-trust identity and compliance by design.'; Chapters=@(
    @{ N='01'; Title='Security Foundations'; Md='Security_Foundations.md'; Study='60 min + 3h';
       Desc='Threat modeling, defense in depth, and the security mindset for data platforms.';
       Prereq='Depends on Phase-00/[Networking Fundamentals](../Phase-00/04_Networking_Fundamentals.prompt.md).'; Focus=@('CIA triad and threat modeling (STRIDE)','Defense in depth and least privilege','OWASP Top 10 for data systems','Attack surface of data platforms','Security in the SDLC') },
    @{ N='02'; Title='Identity and Access Management with Entra'; Md='Identity_and_Access_Management.md'; Study='75 min + 5h';
       Desc='Microsoft Entra ID, RBAC, and workload identity for data platforms.';
       Prereq='Depends on Phase-10/[Security Foundations](01_Security_Foundations.prompt.md).'; Focus=@('Entra ID, OAuth2, OIDC, SAML','RBAC, ABAC, PIM, conditional access','Managed identities and workload identity','Service principals and federation','Access to Storage/Databricks/Synapse') },
    @{ N='03'; Title='Data Security and Encryption'; Md='Data_Security_and_Encryption.md'; Study='60 min + 4h';
       Desc='Encryption, tokenization, and data-centric protection.';
       Prereq='Depends on Phase-10/[Identity and Access Management](02_Identity_and_Access_Management.prompt.md).'; Focus=@('Encryption at rest and in transit','CMK, BYOK, and key rotation','Tokenization and format-preserving encryption','Row/column-level security and masking','Confidential computing') },
    @{ N='04'; Title='Network Security and Zero Trust'; Md='Network_Security_Zero_Trust.md'; Study='60 min + 4h';
       Desc='Zero-trust networking for data platforms and private connectivity.';
       Prereq='Depends on Phase-03/[Azure Networking](../Phase-03/04_Azure_Networking.prompt.md).'; Focus=@('Zero-trust principles','Micro-segmentation and private endpoints','Egress control and data exfiltration','Firewalls, WAF, and DDoS','Securing lakehouse networking') },
    @{ N='05'; Title='Secrets and Key Management'; Md='Secrets_and_Key_Management.md'; Study='45 min + 3h';
       Desc='Managing secrets, keys, and certificates at scale with Key Vault.';
       Prereq='Depends on Phase-10/[Data Security and Encryption](03_Data_Security_and_Encryption.prompt.md).'; Focus=@('Azure Key Vault and Managed HSM','Secret rotation and references','Certificates and mTLS','HashiCorp Vault comparison','Secret sprawl and detection') },
    @{ N='06'; Title='Compliance and Regulatory Frameworks'; Md='Compliance_and_Regulatory.md'; Study='45 min + 2h';
       Desc='GDPR, HIPAA, SOC 2, and building compliant data platforms.';
       Prereq='Depends on Phase-08/[Data Governance Foundations](../Phase-08/01_Data_Governance_Foundations.prompt.md).'; Focus=@('GDPR, CCPA, HIPAA, PCI-DSS','SOC 2, ISO 27001','Audit trails and evidence','Data residency and sovereignty','Compliance as code') },
    @{ N='07'; Title='Data Privacy and PII Protection'; Md='Data_Privacy_and_PII.md'; Study='60 min + 3h';
       Desc='Privacy engineering, PII discovery, and anonymization techniques.';
       Prereq='Depends on Phase-10/[Compliance and Regulatory](06_Compliance_and_Regulatory.prompt.md).'; Focus=@('PII/PHI discovery and classification','Anonymization vs pseudonymization','Differential privacy','Right to be forgotten in lakehouses','Privacy-enhancing technologies') }
  )},

  @{ Id='Phase-11'; Title='AI Platform Engineering & MLOps'; Weeks='Weeks 41-44';
     Goal='Industrialize machine learning with feature stores, MLOps, and serving.'; Chapters=@(
    @{ N='01'; Title='Machine Learning Foundations'; Md='Machine_Learning_Foundations.md'; Study='60 min + 4h';
       Desc='The ML lifecycle and concepts an AI platform architect must master.';
       Prereq='Depends on Phase-00/[Data Structures and Algorithms](../Phase-00/07_Data_Structures_and_Algorithms.prompt.md).'; Focus=@('Supervised/unsupervised/RL basics','Training, validation, evaluation metrics','Bias-variance and generalization','Feature engineering fundamentals','The ML lifecycle end to end') },
    @{ N='02'; Title='Feature Stores with Feast'; Md='Feature_Stores.md'; Study='60 min + 4h';
       Desc='Consistent online/offline features and preventing training-serving skew.';
       Prereq='Depends on Phase-11/[Machine Learning Foundations](01_Machine_Learning_Foundations.prompt.md).'; Focus=@('Online vs offline feature stores','Training-serving skew','Point-in-time correctness','Feast and Databricks Feature Store','Feature governance and reuse') },
    @{ N='03'; Title='MLOps and MLflow'; Md='MLOps_and_MLflow.md'; Study='75 min + 5h';
       Desc='Experiment tracking, model registry, and reproducible ML delivery.';
       Prereq='Depends on Phase-09/[DevOps and CICD](../Phase-09/03_DevOps_and_CICD.prompt.md) and Phase-11/[Machine Learning Foundations](01_Machine_Learning_Foundations.prompt.md).'; Focus=@('Experiment tracking and reproducibility','Model registry and stages','CI/CD/CT for models','MLflow on Azure Databricks','Model lineage and governance') },
    @{ N='04'; Title='Model Serving and Ray'; Md='Model_Serving_and_Ray.md'; Study='60 min + 4h';
       Desc='Scalable batch/real-time inference and distributed compute with Ray.';
       Prereq='Depends on Phase-11/[MLOps and MLflow](03_MLOps_and_MLflow.prompt.md).'; Focus=@('Batch vs online vs streaming inference','Serving patterns and autoscaling','Ray Serve, Ray Data, Ray Train','GPU utilization and batching','Latency and throughput tuning') },
    @{ N='05'; Title='Azure Machine Learning'; Md='Azure_Machine_Learning.md'; Study='60 min + 4h';
       Desc='End-to-end ML on Azure ML: pipelines, endpoints, and governance.';
       Prereq='Depends on Phase-11/[MLOps and MLflow](03_MLOps_and_MLflow.prompt.md).'; Focus=@('Workspaces, compute, and datastores','Azure ML pipelines and components','Managed online/batch endpoints','Model registry and MLflow integration','Responsible AI dashboard') },
    @{ N='06'; Title='ML Pipeline Architecture'; Md='ML_Pipeline_Architecture.md'; Study='60 min + 4h';
       Desc='Designing production ML pipelines from data to deployment and monitoring.';
       Prereq='Depends on Phase-11/[Feature Stores](02_Feature_Stores.prompt.md) and [MLOps and MLflow](03_MLOps_and_MLflow.prompt.md).'; Focus=@('Data -> feature -> train -> deploy -> monitor','Orchestration and triggers','Drift detection and retraining','Champion/challenger and shadow','Cost and resource governance') },
    @{ N='07'; Title='Responsible AI'; Md='Responsible_AI.md'; Study='45 min + 2h';
       Desc='Fairness, explainability, safety, and governance of AI systems.';
       Prereq='Depends on Phase-11/[Azure Machine Learning](05_Azure_Machine_Learning.prompt.md).'; Focus=@('Fairness and bias mitigation','Explainability (SHAP, LIME)','Model cards and datasheets','AI risk and regulation (EU AI Act)','Microsoft Responsible AI Standard') }
  )},

  @{ Id='Phase-12'; Title='LLMOps & Agentic AI'; Weeks='Weeks 45-49';
     Goal='Build, operate, and govern LLM-powered and agentic systems.'; Chapters=@(
    @{ N='01'; Title='Large Language Model Foundations'; Md='LLM_Foundations.md'; Study='75 min + 4h';
       Desc='Transformer internals, tokenization, and inference economics.';
       Prereq='Depends on Phase-11/[Machine Learning Foundations](../Phase-11/01_Machine_Learning_Foundations.prompt.md).'; Focus=@('Transformer architecture and attention','Tokenization and context windows','Pretraining, fine-tuning, RLHF','Inference cost, latency, quantization','Open vs proprietary models') },
    @{ N='02'; Title='Prompt Engineering'; Md='Prompt_Engineering.md'; Study='45 min + 3h';
       Desc='Systematic prompt design, patterns, and structured outputs.';
       Prereq='Depends on Phase-12/[LLM Foundations](01_LLM_Foundations.prompt.md).'; Focus=@('Zero/few-shot and chain-of-thought','System vs user prompts and roles','Structured output and function calling','Prompt templates and versioning','Prompt injection defenses') },
    @{ N='03'; Title='Retrieval Augmented Generation'; Md='Retrieval_Augmented_Generation.md'; Study='75 min + 5h';
       Desc='Grounding LLMs with retrieval, chunking, and hybrid search.';
       Prereq='Depends on Phase-12/[Prompt Engineering](02_Prompt_Engineering.prompt.md).'; Focus=@('RAG architecture and components','Chunking and embedding strategies','Vector, keyword, and hybrid retrieval','Reranking and context assembly','Grounding, citations, and hallucination control') },
    @{ N='04'; Title='LLMOps'; Md='LLMOps.md'; Study='60 min + 4h';
       Desc='Operating LLM applications: evaluation, cost, caching, and observability.';
       Prereq='Depends on Phase-12/[Retrieval Augmented Generation](03_Retrieval_Augmented_Generation.prompt.md) and Phase-11/[MLOps and MLflow](../Phase-11/03_MLOps_and_MLflow.prompt.md).'; Focus=@('LLM lifecycle and versioning','Prompt/response logging and tracing','Cost controls, caching, routing','Evaluation and regression testing','Guardrails and safety in production') },
    @{ N='05'; Title='Agentic AI Architecture'; Md='Agentic_AI_Architecture.md'; Study='75 min + 5h';
       Desc='Planner-executor agents, tool use, memory, and multi-agent systems.';
       Prereq='Depends on Phase-12/[LLMOps](04_LLMOps.prompt.md).'; Focus=@('Agent loops: plan, act, observe, reflect','Tool use and function calling','Short/long-term memory design','Multi-agent orchestration','Reliability, cost, and failure modes') },
    @{ N='06'; Title='Model Context Protocol (MCP)'; Md='Model_Context_Protocol_MCP.md'; Study='60 min + 4h';
       Desc='Standardizing tool and context integration for agents with MCP.';
       Prereq='Depends on Phase-12/[Agentic AI Architecture](05_Agentic_AI_Architecture.prompt.md).'; Focus=@('MCP architecture: hosts, clients, servers','Tools, resources, and prompts','Transport and security model','Building MCP servers for enterprise data','MCP vs proprietary plugin ecosystems') },
    @{ N='07'; Title='Azure OpenAI and AI Foundry'; Md='Azure_OpenAI_and_AI_Foundry.md'; Study='60 min + 4h';
       Desc='Enterprise LLM platform: deployments, grounding, and governance on Azure.';
       Prereq='Depends on Phase-12/[LLMOps](04_LLMOps.prompt.md).'; Focus=@('Azure OpenAI deployments and quotas','AI Foundry, agents, and prompt flow','On Your Data and grounding','Content safety and guardrails','Networking, identity, and cost') },
    @{ N='08'; Title='LangChain and LlamaIndex'; Md='LangChain_and_LlamaIndex.md'; Study='60 min + 4h';
       Desc='Orchestration frameworks for LLM and agent applications.';
       Prereq='Depends on Phase-12/[Retrieval Augmented Generation](03_Retrieval_Augmented_Generation.prompt.md).'; Focus=@('LangChain chains, agents, tools','LlamaIndex data connectors and indexes','LangGraph for stateful agents','Framework vs build-your-own','Production hardening') },
    @{ N='09'; Title='Evaluation and Guardrails'; Md='Evaluation_and_Guardrails.md'; Study='60 min + 3h';
       Desc='Measuring and constraining LLM/agent quality and safety.';
       Prereq='Depends on Phase-12/[LLMOps](04_LLMOps.prompt.md).'; Focus=@('Offline and online evaluation','LLM-as-judge and human eval','Groundedness, relevance, safety metrics','Guardrails and content filtering','Red-teaming and adversarial testing') }
  )},

  @{ Id='Phase-13'; Title='Knowledge Graphs & Vector Systems'; Weeks='Weeks 50-51';
     Goal='Model knowledge and semantics with graphs, embeddings, and vector search.'; Chapters=@(
    @{ N='01'; Title='Vector Databases: Qdrant and Milvus'; Md='Vector_Databases.md'; Study='60 min + 4h';
       Desc='ANN indexing, filtering, and operating vector databases at scale.';
       Prereq='Depends on Phase-12/[Retrieval Augmented Generation](../Phase-12/03_Retrieval_Augmented_Generation.prompt.md).'; Focus=@('ANN algorithms: HNSW, IVF, PQ','Qdrant, Milvus, pgvector','Filtering and hybrid search','Sharding, replication, scaling','Azure AI Search vector store') },
    @{ N='02'; Title='Knowledge Graphs with Neo4j'; Md='Knowledge_Graphs.md'; Study='60 min + 4h';
       Desc='Property graphs, Cypher, and graph modeling for connected data.';
       Prereq='Depends on Phase-06/[Data Modeling](../Phase-06/01_Dimensional_Modeling.prompt.md).'; Focus=@('Property graph vs RDF','Cypher and graph queries','Graph modeling patterns','Graph algorithms (centrality, community)','Neo4j and Azure Cosmos DB Gremlin') },
    @{ N='03'; Title='Embeddings and Semantic Search'; Md='Embeddings_and_Semantic_Search.md'; Study='45 min + 3h';
       Desc='Embedding models, similarity, and building semantic search.';
       Prereq='Depends on Phase-13/[Vector Databases](01_Vector_Databases.prompt.md).'; Focus=@('Embedding models and dimensions','Similarity metrics','Chunking and multi-vector','Evaluation of retrieval quality','Multimodal embeddings') },
    @{ N='04'; Title='GraphRAG'; Md='GraphRAG.md'; Study='60 min + 3h';
       Desc='Combining knowledge graphs with retrieval for grounded reasoning.';
       Prereq='Depends on Phase-13/[Knowledge Graphs](02_Knowledge_Graphs.prompt.md) and [Embeddings and Semantic Search](03_Embeddings_and_Semantic_Search.prompt.md).'; Focus=@('Graph construction from documents','Community detection and summarization','Graph + vector hybrid retrieval','Multi-hop reasoning','Microsoft GraphRAG patterns') },
    @{ N='05'; Title='Ontologies and Taxonomies'; Md='Ontologies_and_Taxonomies.md'; Study='45 min + 2h';
       Desc='Formal semantics, ontologies, and the enterprise semantic layer.';
       Prereq='Depends on Phase-13/[Knowledge Graphs](02_Knowledge_Graphs.prompt.md).'; Focus=@('Taxonomies vs ontologies','RDF, RDFS, OWL, SKOS','Enterprise knowledge organization','Reasoning and inference','Semantic interoperability') }
  )},

  @{ Id='Phase-14'; Title='Event-Driven Architecture & Integration'; Weeks='Weeks 52-54';
     Goal='Design decoupled, event-driven, and integration architectures.'; Chapters=@(
    @{ N='01'; Title='Event-Driven Architecture'; Md='Event_Driven_Architecture.md'; Study='60 min + 4h';
       Desc='Events, brokers, and choreography for loosely coupled systems.';
       Prereq='Depends on Phase-07/[Apache Kafka](../Phase-07/02_Apache_Kafka.prompt.md).'; Focus=@('Events vs commands vs messages','Pub/sub, brokers, and topics','Choreography vs orchestration','Event schemas and evolution','Azure Event Grid and Service Bus') },
    @{ N='02'; Title='Microservices Architecture'; Md='Microservices_Architecture.md'; Study='60 min + 4h';
       Desc='Service boundaries, communication, and data ownership for microservices.';
       Prereq='Depends on Phase-01/[Domain Driven Design](../Phase-01/05_Domain_Driven_Design.prompt.md).'; Focus=@('Service boundaries from DDD','Sync vs async communication','Database-per-service and data ownership','Resilience patterns','When NOT to use microservices') },
    @{ N='03'; Title='CQRS'; Md='CQRS.md'; Study='45 min + 3h';
       Desc='Separating read and write models for scalability and clarity.';
       Prereq='Depends on Phase-14/[Microservices Architecture](02_Microservices_Architecture.prompt.md).'; Focus=@('Command vs query models','Read model projections','Consistency and eventual sync','CQRS with event sourcing','When CQRS adds vs removes complexity') },
    @{ N='04'; Title='Event Sourcing'; Md='Event_Sourcing.md'; Study='60 min + 4h';
       Desc='Persisting state as an immutable event log with replay and audit.';
       Prereq='Depends on Phase-14/[CQRS](03_CQRS.prompt.md).'; Focus=@('Event store and append-only log','Rebuilding state and snapshots','Projections and read models','Schema evolution and upcasting','Auditability and temporal queries') },
    @{ N='05'; Title='API Design: REST, GraphQL, gRPC'; Md='API_Design.md'; Study='60 min + 4h';
       Desc='Designing robust, versioned APIs for data and services.';
       Prereq='Depends on Phase-00/[Networking Fundamentals](../Phase-00/04_Networking_Fundamentals.prompt.md).'; Focus=@('REST maturity and resource design','GraphQL schemas and resolvers','gRPC and protobuf','Versioning, pagination, idempotency','Azure API Management') },
    @{ N='06'; Title='Enterprise Integration Patterns'; Md='Enterprise_Integration_Patterns.md'; Study='45 min + 3h';
       Desc='Classic integration patterns for connecting heterogeneous systems.';
       Prereq='Depends on Phase-14/[Event-Driven Architecture](01_Event_Driven_Architecture.prompt.md).'; Focus=@('Messaging channels and routers','Transformation and enrichment','Aggregator, splitter, and saga','iPaaS and Azure Logic Apps','Anti-corruption layers') },
    @{ N='07'; Title='Message Brokers and Queues'; Md='Message_Brokers_and_Queues.md'; Study='45 min + 3h';
       Desc='Choosing and operating queues, logs, and brokers.';
       Prereq='Depends on Phase-14/[Event-Driven Architecture](01_Event_Driven_Architecture.prompt.md).'; Focus=@('Queue vs log vs pub/sub semantics','Delivery guarantees and ordering','Dead-letter and poison messages','RabbitMQ, Kafka, Service Bus, SQS','Backpressure and throughput') }
  )},

  @{ Id='Phase-15'; Title='Data Mesh & Data Fabric'; Weeks='Weeks 55-56';
     Goal='Scale data ownership and interoperability with mesh and fabric paradigms.'; Chapters=@(
    @{ N='01'; Title='Data Mesh Principles'; Md='Data_Mesh_Principles.md'; Study='60 min + 3h';
       Desc='The four principles of data mesh and their organizational implications.';
       Prereq='Depends on Phase-01/[Domain Driven Design](../Phase-01/05_Domain_Driven_Design.prompt.md) and Phase-08/[Data Governance Foundations](../Phase-08/01_Data_Governance_Foundations.prompt.md).'; Focus=@('Domain ownership','Data as a product','Self-serve data platform','Federated computational governance','Socio-technical implications') },
    @{ N='02'; Title='Data Products'; Md='Data_Products.md'; Study='60 min + 3h';
       Desc='Designing, packaging, and operating data as first-class products.';
       Prereq='Depends on Phase-15/[Data Mesh Principles](01_Data_Mesh_Principles.prompt.md).'; Focus=@('Data product anatomy and ports','Discoverability and addressability','SLAs, SLOs, and contracts','Data product lifecycle','Metrics and adoption') },
    @{ N='03'; Title='Data Fabric'; Md='Data_Fabric.md'; Study='45 min + 2h';
       Desc='Metadata-driven integration and the data fabric approach.';
       Prereq='Depends on Phase-08/[Metadata Management](../Phase-08/04_Metadata_Management.prompt.md).'; Focus=@('Data fabric vs data mesh','Active metadata and knowledge graph','Automated integration and virtualization','Data virtualization engines','Fabric on Azure') },
    @{ N='04'; Title='Federated Governance'; Md='Federated_Governance.md'; Study='45 min + 2h';
       Desc='Global policies with local autonomy through computational governance.';
       Prereq='Depends on Phase-15/[Data Mesh Principles](01_Data_Mesh_Principles.prompt.md).'; Focus=@('Global vs local policies','Policy as code and automation','Interoperability standards','Governance guild and roles','Balancing autonomy and control') },
    @{ N='05'; Title='Self-Serve Data Platform'; Md='Self_Serve_Data_Platform.md'; Study='60 min + 3h';
       Desc='Platform capabilities that enable autonomous domain teams.';
       Prereq='Depends on Phase-09/[Platform Engineering](../Phase-09/02_Platform_Engineering.prompt.md) and Phase-15/[Data Products](02_Data_Products.prompt.md).'; Focus=@('Platform capability planes','Provisioning and templates','Golden paths for data products','Observability and cost transparency','Mesh on Azure/Databricks/Fabric') }
  )},

  @{ Id='Phase-16'; Title='Domain-Specific & Frontier Data Platforms'; Weeks='Weeks 57-60';
     Goal='Apply architecture to IoT, robotics, autonomy, space, and geospatial domains.'; Chapters=@(
    @{ N='01'; Title='IoT Data Platforms'; Md='IoT_Data_Platforms.md'; Study='60 min + 4h';
       Desc='Ingesting and processing device telemetry at massive scale.';
       Prereq='Depends on Phase-07/[Streaming Fundamentals](../Phase-07/01_Streaming_Fundamentals.prompt.md).'; Focus=@('Device connectivity and protocols (MQTT/AMQP)','Azure IoT Hub and Event Hubs','Edge vs cloud processing','Time-series storage and downsampling','Device management and security') },
    @{ N='02'; Title='Industrial IoT (IIoT)'; Md='Industrial_IoT.md'; Study='60 min + 4h';
       Desc='OT/IT convergence, OPC UA, and industrial data platforms.';
       Prereq='Depends on Phase-16/[IoT Data Platforms](01_IoT_Data_Platforms.prompt.md).'; Focus=@('OT/IT convergence and Purdue model','OPC UA and industrial protocols','Azure IoT Operations and Edge','Predictive maintenance pipelines','Safety, reliability, and standards') },
    @{ N='03'; Title='Robotics and ROS2'; Md='Robotics_and_ROS2.md'; Study='60 min + 4h';
       Desc='Robotics data architecture, ROS2, and DDS communication.';
       Prereq='Depends on Phase-14/[Event-Driven Architecture](../Phase-14/01_Event_Driven_Architecture.prompt.md).'; Focus=@('ROS2 nodes, topics, services, actions','DDS and real-time communication','Sensor fusion data pipelines','Simulation and digital twins','Fleet data collection and MLOps') },
    @{ N='04'; Title='Autonomous Vehicles Data'; Md='Autonomous_Vehicles_Data.md'; Study='60 min + 4h';
       Desc='Petabyte-scale sensor data pipelines for autonomy.';
       Prereq='Depends on Phase-16/[Robotics and ROS2](03_Robotics_and_ROS2.prompt.md).'; Focus=@('Sensor suites: LiDAR, camera, radar','Data ingestion and labeling at scale','Scenario mining and replay','Simulation and validation','Storage and cost at PB scale') },
    @{ N='05'; Title='Space Data Platforms'; Md='Space_Data_Platforms.md'; Study='60 min + 3h';
       Desc='Satellite telemetry, downlink, and space-ground data architecture.';
       Prereq='Depends on Phase-16/[IoT Data Platforms](01_IoT_Data_Platforms.prompt.md).'; Focus=@('Satellite telemetry and downlink','Ground station as a service (Azure Orbital)','Onboard vs ground processing','Data prioritization over constrained links','Mission data archives') },
    @{ N='06'; Title='Earth Observation and Geospatial Analytics'; Md='Earth_Observation_and_Geospatial.md'; Study='60 min + 4h';
       Desc='Raster/vector geospatial data and large-scale EO processing.';
       Prereq='Depends on Phase-16/[Space Data Platforms](05_Space_Data_Platforms.prompt.md).'; Focus=@('Raster vs vector, COG, STAC','Geospatial indexing (H3, S2, geohash)','Planetary Computer and EO pipelines','Spatial SQL and processing engines','Geospatial ML') },
    @{ N='07'; Title='Digital Twins'; Md='Digital_Twins.md'; Study='60 min + 3h';
       Desc='Modeling physical systems as live digital twins.';
       Prereq='Depends on Phase-16/[Industrial IoT](02_Industrial_IoT.prompt.md).'; Focus=@('Digital twin definition language (DTDL)','Azure Digital Twins','Real-time state and simulation','Twin graphs and relationships','Use cases across industries') }
  )},

  @{ Id='Phase-17'; Title='Industry Vertical Platforms'; Weeks='Weeks 61-63';
     Goal='Architect regulated, high-stakes data platforms across key industries.'; Chapters=@(
    @{ N='01'; Title='Healthcare Data Platforms'; Md='Healthcare_Data_Platforms.md'; Study='60 min + 3h';
       Desc='FHIR, HIPAA, and interoperable healthcare data architecture.';
       Prereq='Depends on Phase-10/[Compliance and Regulatory](../Phase-10/06_Compliance_and_Regulatory.prompt.md).'; Focus=@('FHIR and HL7 standards','Azure Health Data Services','PHI protection and HIPAA','Clinical and genomics pipelines','Interoperability and consent') },
    @{ N='02'; Title='Financial Data Platforms'; Md='Financial_Data_Platforms.md'; Study='60 min + 3h';
       Desc='Low-latency, auditable, regulated financial data systems.';
       Prereq='Depends on Phase-10/[Compliance and Regulatory](../Phase-10/06_Compliance_and_Regulatory.prompt.md).'; Focus=@('Market data and tick pipelines','Risk, fraud, and AML analytics','Auditability and lineage','Regulatory reporting (BCBS 239)','Low-latency and accuracy trade-offs') },
    @{ N='03'; Title='Aviation Data Platforms'; Md='Aviation_Data_Platforms.md'; Study='60 min + 3h';
       Desc='Flight, sensor, and operational data at airline and OEM scale.';
       Prereq='Depends on Phase-16/[IoT Data Platforms](../Phase-16/01_IoT_Data_Platforms.prompt.md).'; Focus=@('Flight and engine telemetry','Predictive maintenance (prognostics)','Operations and network optimization','Safety-critical data standards','Data sovereignty across regions') },
    @{ N='04'; Title='Smart Cities'; Md='Smart_Cities.md'; Study='60 min + 3h';
       Desc='Urban-scale sensor, mobility, and services data platforms.';
       Prereq='Depends on Phase-16/[IoT Data Platforms](../Phase-16/01_IoT_Data_Platforms.prompt.md) and Phase-16/[Digital Twins](../Phase-16/07_Digital_Twins.prompt.md).'; Focus=@('Mobility and traffic data','Urban digital twins','Citizen privacy and ethics','Open data and interoperability','Sustainability analytics') },
    @{ N='05'; Title='Retail and E-Commerce Data'; Md='Retail_and_Ecommerce_Data.md'; Study='60 min + 3h';
       Desc='Personalization, inventory, and real-time commerce analytics.';
       Prereq='Depends on Phase-07/[Real-Time Analytics](../Phase-07/07_Real_Time_Analytics.prompt.md) and Phase-11/[ML Pipeline Architecture](../Phase-11/06_ML_Pipeline_Architecture.prompt.md).'; Focus=@('Clickstream and event pipelines','Recommendation systems','Real-time inventory and pricing','Customer 360 and CDP','Peak-scale (Black Friday) design') }
  )},

  @{ Id='Phase-18'; Title='FinOps, Observability & Reliability'; Weeks='Weeks 64-66';
     Goal='Run data and AI platforms cost-efficiently and reliably in production.'; Chapters=@(
    @{ N='01'; Title='FinOps and Cost Optimization'; Md='FinOps_and_Cost_Optimization.md'; Study='60 min + 3h';
       Desc='Cost visibility, allocation, and optimization for data and AI.';
       Prereq='Depends on Phase-03/[Well-Architected Framework](../Phase-03/07_Well_Architected_Framework.prompt.md).'; Focus=@('FinOps operating model and phases','Cost allocation, tagging, showback','Compute/storage optimization levers','Spot, reservations, and savings plans','LLM/token cost management') },
    @{ N='02'; Title='Observability with OpenTelemetry'; Md='Observability_OpenTelemetry.md'; Study='60 min + 4h';
       Desc='Traces, metrics, and logs unified through OpenTelemetry.';
       Prereq='Depends on Phase-09/[DataOps Foundations](../Phase-09/01_DataOps_Foundations.prompt.md).'; Focus=@('Three pillars: logs, metrics, traces','OpenTelemetry collector and SDKs','Distributed tracing and context propagation','Data pipeline observability','Azure Monitor and App Insights') },
    @{ N='03'; Title='Monitoring with Prometheus and Grafana'; Md='Monitoring_Prometheus_Grafana.md'; Study='60 min + 3h';
       Desc='Metrics collection, alerting, and dashboards for platforms.';
       Prereq='Depends on Phase-18/[Observability OpenTelemetry](02_Observability_OpenTelemetry.prompt.md).'; Focus=@('Prometheus data model and PromQL','Exporters and service discovery','Grafana dashboards and alerting','SLO-based alerting','Managed Prometheus/Grafana on Azure') },
    @{ N='04'; Title='Reliability and SRE'; Md='Reliability_and_SRE.md'; Study='60 min + 3h';
       Desc='SLOs, error budgets, and incident management for data platforms.';
       Prereq='Depends on Phase-02/[Fault Tolerance and Resilience](../Phase-02/07_Fault_Tolerance_and_Resilience.prompt.md).'; Focus=@('SLIs, SLOs, error budgets','Toil reduction and automation','Incident response and postmortems','Data reliability engineering','On-call and runbooks') },
    @{ N='05'; Title='Performance Engineering'; Md='Performance_Engineering.md'; Study='60 min + 4h';
       Desc='Systematic benchmarking and tuning across the data stack.';
       Prereq='Depends on Phase-05/[Apache Spark Internals](../Phase-05/04_Apache_Spark_Internals.prompt.md).'; Focus=@('Benchmarking methodology','Profiling and bottleneck analysis','Query and storage tuning','Caching and materialization','Capacity planning') }
  )},

  @{ Id='Phase-19'; Title='Leadership & Technical Strategy'; Weeks='Weeks 67-70';
     Goal='Lead architecture, teams, and strategy at staff-through-executive levels.'; Chapters=@(
    @{ N='01'; Title='Technical Leadership'; Md='Technical_Leadership.md'; Study='45 min + 2h';
       Desc='Influence, decision-making, and leading without authority.';
       Prereq='Depends on Phase-01/[Technical Strategy and Roadmaps](../Phase-01/07_Technical_Strategy_and_Roadmaps.prompt.md).'; Focus=@('Staff+ archetypes and scope','Leading through influence','Driving technical decisions','Managing ambiguity','Building technical vision') },
    @{ N='02'; Title='Architecture Reviews'; Md='Architecture_Reviews.md'; Study='45 min + 3h';
       Desc='Running effective, constructive architecture and design reviews.';
       Prereq='Depends on Phase-01/[Architecture Governance](../Phase-01/02_Architecture_Governance.prompt.md).'; Focus=@('Review formats and cadence','Design docs and RFCs','Trade-off and risk analysis','Giving and receiving feedback','Decision documentation') },
    @{ N='03'; Title='Stakeholder Management'; Md='Stakeholder_Management.md'; Study='45 min + 2h';
       Desc='Aligning executives, product, and engineering around data/AI strategy.';
       Prereq='Depends on Phase-19/[Technical Leadership](01_Technical_Leadership.prompt.md).'; Focus=@('Stakeholder mapping and influence','Executive communication','Managing conflict and trade-offs','Building coalitions','Selling technical investments') },
    @{ N='04'; Title='Technical Writing'; Md='Technical_Writing.md'; Study='45 min + 3h';
       Desc='Writing design docs, ADRs, and strategy that scale decisions.';
       Prereq='Depends on Phase-01/[Architecture Decision Records](../Phase-01/03_Architecture_Decision_Records.prompt.md).'; Focus=@('Design docs and one-pagers','Writing for different audiences','Structure, clarity, brevity','Diagrams as communication','Docs-as-code') },
    @{ N='05'; Title='Hiring and Interviewing'; Md='Hiring_and_Interviewing.md'; Study='45 min + 2h';
       Desc='Building and assessing high-performing data and AI teams.';
       Prereq='Depends on Phase-19/[Technical Leadership](01_Technical_Leadership.prompt.md).'; Focus=@('Role and leveling calibration','Structured interviews and rubrics','System design and coding signals','Bias reduction','Building diverse teams') },
    @{ N='06'; Title='Mentoring and Team Building'; Md='Mentoring_and_Team_Building.md'; Study='45 min + 2h';
       Desc='Growing engineers and shaping healthy engineering culture.';
       Prereq='Depends on Phase-19/[Technical Leadership](01_Technical_Leadership.prompt.md).'; Focus=@('Mentoring and sponsorship','Career ladders and growth','Team topologies and Conway law','Psychological safety','Knowledge sharing') },
    @{ N='07'; Title='Roadmap and Portfolio Planning'; Md='Roadmap_and_Portfolio_Planning.md'; Study='45 min + 3h';
       Desc='Planning, prioritizing, and sequencing multi-year technical portfolios.';
       Prereq='Depends on Phase-01/[Technical Strategy and Roadmaps](../Phase-01/07_Technical_Strategy_and_Roadmaps.prompt.md).'; Focus=@('Portfolio prioritization frameworks','Sequencing and dependency management','Capacity and investment planning','Measuring outcomes (OKRs)','Communicating roadmaps') },
    @{ N='08'; Title='CDO and CAIO Playbook'; Md='CDO_and_CAIO_Playbook.md'; Study='60 min + 3h';
       Desc='Operating model, org design, and strategy for data/AI executives.';
       Prereq='Depends on Phase-19/[Roadmap and Portfolio Planning](07_Roadmap_and_Portfolio_Planning.prompt.md) and Phase-01/[Technical Strategy and Roadmaps](../Phase-01/07_Technical_Strategy_and_Roadmaps.prompt.md).'; Focus=@('CDO/CAIO mandate and scope','Data/AI operating model and org design','Value realization and ROI','Risk, ethics, and governance at the top','Building the data/AI strategy') }
  )},

  @{ Id='Phase-20'; Title='Capstone & Career'; Weeks='Weeks 71-73';
     Goal='Integrate everything into capstone platforms and role-readiness.'; Chapters=@(
    @{ N='01'; Title='Capstone: Enterprise Data Platform'; Md='Capstone_Enterprise_Data_Platform.md'; Study='90 min + 12h';
       Desc='Design a full enterprise lakehouse platform integrating prior phases.';
       Prereq='Depends on Phases 03-09 (Azure, lakehouse, streaming, governance, DataOps).'; Focus=@('End-to-end reference architecture','Ingestion, lakehouse, serving, governance','Security, networking, and FinOps','Operability and reliability','Full ADR set and diagrams') },
    @{ N='02'; Title='Capstone: Enterprise AI Platform'; Md='Capstone_Enterprise_AI_Platform.md'; Study='90 min + 12h';
       Desc='Design an enterprise AI/LLM/agentic platform on Azure.';
       Prereq='Depends on Phases 11-13 (MLOps, LLMOps, agents, vector/graph).'; Focus=@('AI platform reference architecture','MLOps + LLMOps + agent orchestration','RAG, vector, and knowledge graph','Responsible AI and guardrails','Cost, security, and governance') },
    @{ N='03'; Title='System Design Interview Prep'; Md='System_Design_Interview_Prep.md'; Study='60 min + 6h';
       Desc='A framework and drills for data/AI system design interviews.';
       Prereq='Depends on Phase-02 through Phase-12.'; Focus=@('A repeatable system-design framework','Estimation and back-of-envelope','Common data-system design questions','Trade-off articulation','Whiteboarding and communication') },
    @{ N='04'; Title='Architecture Interview Prep'; Md='Architecture_Interview_Prep.md'; Study='60 min + 6h';
       Desc='Preparing for solution/enterprise architect interviews.';
       Prereq='Depends on Phase-01 and Phase-19.'; Focus=@('Architecture case interviews','Requirements to design under constraints','Governance and stakeholder scenarios','Cost and risk reasoning','Presenting and defending designs') },
    @{ N='05'; Title='Staff and Principal Promotion'; Md='Staff_Principal_Promotion.md'; Study='45 min + 3h';
       Desc='Building the scope, impact, and evidence for staff+ promotion.';
       Prereq='Depends on Phase-19/[Technical Leadership](../Phase-19/01_Technical_Leadership.prompt.md).'; Focus=@('Leveling expectations by role','Demonstrating scope and impact','Promotion packets and evidence','Sponsorship and visibility','Common promotion pitfalls') },
    @{ N='06'; Title='Portfolio and Case Studies'; Md='Portfolio_and_Case_Studies.md'; Study='45 min + 4h';
       Desc='Packaging your work into a compelling architect portfolio.';
       Prereq='Depends on Phase-20/[Capstone Enterprise Data Platform](01_Capstone_Enterprise_Data_Platform.prompt.md) and [Capstone Enterprise AI Platform](02_Capstone_Enterprise_AI_Platform.prompt.md).'; Focus=@('Portfolio structure and narrative','Writing impactful case studies','Architecture artifacts to showcase','Public presence (talks, writing)','Interview storytelling (STAR)') }
  )}
)

# ---------------------------------------------------------------------------
# Resources: cross-cutting prompt files grouped by area
# ---------------------------------------------------------------------------
$resources = @(
  @{ Area='Architecture'; Files=@(
    @{ N='01'; Title='Reference Architectures Catalog'; Md='Reference_Architectures.md'; Desc='A curated catalog of enterprise data and AI reference architectures.'; Prereq='Depends on Phase-05 and Phase-12.'; Focus=@('Lakehouse, streaming, and AI reference architectures','Azure-first blueprints with OSS alternatives','When to use each pattern','Cost and reliability profiles','Diagrams for each architecture') },
    @{ N='02'; Title='Architecture Patterns Catalog'; Md='Architecture_Patterns_Catalog.md'; Desc='A reusable catalog of data and integration architecture patterns.'; Prereq='Depends on Phase-14.'; Focus=@('Ingestion, storage, processing, serving patterns','Integration and event patterns','Anti-patterns to avoid','Pattern selection matrix','Trade-offs per pattern') }
  )},
  @{ Area='CaseStudies'; Files=@(
    @{ N='01'; Title='Netflix Data Platform Case Study'; Md='Netflix_Data_Platform.md'; Desc='How Netflix built its large-scale data platform and streaming analytics.'; Prereq='Depends on Phase-05 and Phase-07.'; Focus=@('Netflix data platform evolution','Keystone, Iceberg, and streaming','Self-service and scale','Failure stories and lessons','What to reuse vs avoid') },
    @{ N='02'; Title='Uber Data Infrastructure Case Study'; Md='Uber_Data_Infrastructure.md'; Desc='Uber data infrastructure: Hudi, Michelangelo, and real-time systems.'; Prereq='Depends on Phase-04, Phase-07, and Phase-11.'; Focus=@('Uber big-data stack and Hudi origins','Michelangelo ML platform','Real-time and geospatial systems','Scale and cost lessons','Applicable patterns') },
    @{ N='03'; Title='Airbnb Minerva Case Study'; Md='Airbnb_Minerva.md'; Desc='Airbnb metrics platform (Minerva) and the semantic layer story.'; Prereq='Depends on Phase-06.'; Focus=@('Metric consistency problem','Minerva architecture','Semantic layer and governance','Adoption and impact','Lessons for metric platforms') },
    @{ N='04'; Title='Spotify Data Platform Case Study'; Md='Spotify_Data_Platform.md'; Desc='Spotify data platform, Backstage, and golden paths.'; Prereq='Depends on Phase-09.'; Focus=@('Spotify data ecosystem','Backstage and platform engineering','Event delivery at scale','Autonomy and paved roads','Lessons for platform teams') },
    @{ N='05'; Title='LinkedIn and the Birth of Kafka'; Md='LinkedIn_Kafka_Story.md'; Desc='How LinkedIn created Kafka and the log-centric architecture.'; Prereq='Depends on Phase-07.'; Focus=@('The integration problem at LinkedIn','The log as unifying abstraction','Kafka and stream processing evolution','Organizational impact','Lessons and trade-offs') }
  )},
  @{ Area='Labs'; Files=@(
    @{ N='01'; Title='Lab Environment Setup'; Md='Lab_Environment_Setup.md'; Desc='Set up a reproducible local and Azure lab environment for the handbook.'; Prereq='Depends on Phase-09.'; Focus=@('Local toolchain (Docker, Python, CLIs)','Azure sandbox subscription and guardrails','Cost controls and auto-shutdown','IaC bootstrap','Cleanup and teardown') },
    @{ N='02'; Title='End-to-End Lakehouse Lab'; Md='End_to_End_Lakehouse_Lab.md'; Desc='Build a full bronze-silver-gold lakehouse on Azure Databricks.'; Prereq='Depends on Phase-05.'; Focus=@('Ingestion to Delta bronze','Silver cleansing and quality','Gold marts and serving','Orchestration and CI/CD','Validation and teardown') },
    @{ N='03'; Title='Streaming Lab'; Md='Streaming_Lab.md'; Desc='Build a real-time pipeline with Event Hubs/Kafka and stream processing.'; Prereq='Depends on Phase-07.'; Focus=@('Producer and ingestion setup','Stream processing job','Exactly-once sink to Delta','Real-time dashboard','Failure injection') },
    @{ N='04'; Title='RAG Lab'; Md='RAG_Lab.md'; Desc='Build a production-style RAG application on Azure with evaluation.'; Prereq='Depends on Phase-12 and Phase-13.'; Focus=@('Ingestion, chunking, embedding','Vector store and retrieval','Azure OpenAI grounding','Evaluation and guardrails','Cost and observability') }
  )},
  @{ Area='Interview'; Files=@(
    @{ N='01'; Title='Interview Question Bank'; Md='Interview_Question_Bank.md'; Desc='A structured bank of interview questions across all handbook topics and levels.'; Prereq='Spans all phases.'; Focus=@('Questions by topic and by level','Engineer, staff, architect, CTO tiers','Model answers and rubrics','Behavioral and leadership questions','Self-assessment tracker') },
    @{ N='02'; Title='System Design Scenarios'; Md='System_Design_Scenarios.md'; Desc='A set of realistic data/AI system design scenarios with guidance.'; Prereq='Depends on Phase-20.'; Focus=@('End-to-end scenario prompts','Requirements and constraints','Reference solutions and trade-offs','Evaluation rubric','Follow-up deep dives') }
  )},
  @{ Area='References'; Files=@(
    @{ N='01'; Title='Glossary'; Md='Glossary.md'; Desc='A comprehensive glossary of data and AI architecture terminology.'; Prereq='Spans all phases.'; Focus=@('Alphabetical term definitions','Acronym expansions','Cross-links to relevant chapters','Azure/OSS/AWS/GCP equivalents','Concise, precise definitions') },
    @{ N='02'; Title='Reading List and Further Study'; Md='Reading_List.md'; Desc='A curated reading and reference list to go beyond the handbook.'; Prereq='Spans all phases.'; Focus=@('Foundational books and papers','Vendor and OSS documentation','Blogs and engineering wikis','Conferences and communities','Certifications and learning paths') }
  )}
)

# ---------------------------------------------------------------------------
# Generation
# ---------------------------------------------------------------------------
$generated = @()

foreach ($phase in $phases) {
    $dir = Join-Path $promptRoot $phase.Id
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $indexRows = @()
    foreach ($c in $phase.Chapters) {
        $fn = New-PromptFile -Dir $dir -N $c.N -Title $c.Title -Md $c.Md -Desc $c.Desc `
            -Focus $c.Focus -Prereq $c.Prereq -Study $c.Study `
            -PhaseTitle $phase.Title -PhaseId $phase.Id
        $generated += [pscustomobject]@{ Phase=$phase.Id; File="$($phase.Id)/$fn"; Title=$c.Title; Output=$c.Md }
        $indexRows += "| $($c.N) | [$($c.Title)]($fn) | ``$($c.Md)`` | $($c.Study) |"
    }
    # Per-phase README index
    $phaseReadme = @"
# $($phase.Id) — $($phase.Title)

> $($phase.Goal)
>
> Suggested timeline: **$($phase.Weeks)**

Each prompt below instructs GitHub Copilot to generate exactly one standalone Markdown
chapter with all 50 mandatory sections (Azure-primary, ~60/30/10 Azure/OSS/AWS+GCP).

| # | Prompt | Generates | Study time |
|---|--------|-----------|------------|
$($indexRows -join "`n")

## How to run
Open a prompt file in VS Code and run it with GitHub Copilot (agent mode), or reference it
from Copilot Chat. It will produce the corresponding ``.md`` chapter listed above.

[Back to handbook README](../../../README.md) - [Roadmap](../../../ROADMAP.md) - [Dependency graph](../../../DEPENDENCY_GRAPH.md)
"@
    Set-Content -Path (Join-Path $dir 'README.md') -Value $phaseReadme -Encoding UTF8
}

# Resources
foreach ($res in $resources) {
    $dir = Join-Path $promptRoot (Join-Path 'Resources' $res.Area)
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $indexRows = @()
    foreach ($c in $res.Files) {
        $fn = New-PromptFile -Dir $dir -N $c.N -Title $c.Title -Md $c.Md -Desc $c.Desc `
            -Focus $c.Focus -Prereq $c.Prereq -Study '45-60 min + optional lab' `
            -PhaseTitle "Resources / $($res.Area)" -PhaseId 'Resources'
        $generated += [pscustomobject]@{ Phase="Resources/$($res.Area)"; File="Resources/$($res.Area)/$fn"; Title=$c.Title; Output=$c.Md }
        $indexRows += "| [$($c.Title)]($fn) | ``$($c.Md)`` |"
    }
    $resReadme = @"
# Resources — $($res.Area)

Cross-cutting prompts that complement the phased curriculum.

| Prompt | Generates |
|--------|-----------|
$($indexRows -join "`n")

[Back to handbook README](../../../README.md)
"@
    Set-Content -Path (Join-Path $dir 'README.md') -Value $resReadme -Encoding UTF8
}

# ---------------------------------------------------------------------------
# Top-level index docs
# ---------------------------------------------------------------------------
$totalPrompts = $generated.Count

# README.md
$phaseTableRows = foreach ($phase in $phases) {
    "| **$($phase.Id)** | $($phase.Title) | $($phase.Chapters.Count) | $($phase.Weeks) |"
}
$resCount = ($resources | ForEach-Object { $_.Files.Count } | Measure-Object -Sum).Sum
$readme = @"
# Enterprise Data & AI Architecture Handbook — Prompt Library

A complete library of **GitHub Copilot prompt files**. Each prompt generates **one
standalone Markdown chapter**. Together they form an enterprise-grade handbook that takes an
experienced Azure Data Engineer to **Senior -> Lead -> Staff -> Principal -> Data/Solution/Enterprise
Architect -> Head of Data/AI -> CDO/CAIO**.

> This repository intentionally contains **prompts, not content**. Run the prompts with
> GitHub Copilot to generate the handbook chapters.

## What makes this different
- Reads like an **internal engineering knowledge base** (Microsoft / Google / Netflix /
  Uber / Databricks), not an online course.
- **Azure-primary** (~60%), **enterprise open-source** (~30%), **AWS & GCP comparison only** (~10%).
- Every chapter enforces the same **50-section structure** for depth and consistency.
- Real architectures, real case studies, failure stories, trade-offs, ADRs, and "when NOT to use".

## Repository layout
``````
Learning-Curriculum/
├── README.md
├── ROADMAP.md
├── DEPENDENCY_GRAPH.md
├── generate_curriculum.ps1
└── .github/prompts/
    ├── Phase-00 ... Phase-20/   (phased curriculum)
    └── Resources/
        ├── Architecture/
        ├── CaseStudies/
        ├── Labs/
        ├── Interview/
        └── References/
``````

## Curriculum at a glance
- **$($phases.Count) phases**, **$totalPrompts prompt files** total ($($totalPrompts - $resCount) phased + $resCount resources).
- Targets **~1 year** of intensive study (see [ROADMAP.md](ROADMAP.md)).

| Phase | Focus | Chapters | Timeline |
|-------|-------|----------|----------|
$($phaseTableRows -join "`n")

## How to use
1. Pick a phase in ``.github/prompts/`` and open a ``*.prompt.md`` file in VS Code.
2. Run it with **GitHub Copilot (agent mode)** or reference it from Copilot Chat.
3. Copilot generates the corresponding standalone ``.md`` chapter.
4. Follow the order in [ROADMAP.md](ROADMAP.md); respect prerequisites in [DEPENDENCY_GRAPH.md](DEPENDENCY_GRAPH.md).

## Regenerating the prompt library
All prompts and index docs are generated from a single source of truth:
``````powershell
pwsh ./generate_curriculum.ps1   # or: powershell -File ./generate_curriculum.ps1
``````

## Every generated chapter contains these 50 sections
Executive Summary - Learning Objectives - Business Motivation - History and Evolution - Why This
Technology Exists - Problems It Solves - Problems It Cannot Solve - Core Concepts - Internal Working
- Architecture - Components - Metadata - Storage - Compute - Networking - Security - Performance -
Scalability - Fault Tolerance - Cost Optimization - Monitoring - Observability - Governance -
Trade-offs - Decision Matrix - Design Patterns - Anti-patterns - Common Mistakes - Best Practices -
Enterprise Recommendations - Azure Implementation - Open Source Implementation - AWS Equivalent -
GCP Equivalent - Migration Considerations - Mermaid Architecture Diagrams - End-to-End Data Flow -
Real-world Business Use Cases - Industry Examples - Case Studies - Hands-on Labs - Exercises - Mini
Projects - Capstone Integration - Interview Questions - Staff Engineer Questions - Architect
Questions - CTO Review Questions - References - Further Reading.
"@
Set-Content -Path (Join-Path $root 'README.md') -Value $readme -Encoding UTF8

# ROADMAP.md
$roadmapSections = foreach ($phase in $phases) {
    $chapterLines = foreach ($c in $phase.Chapters) {
        "  - [ ] $($phase.Id)/$($c.N) — $($c.Title)  →  generates ``$($c.Md)``"
    }
@"

### $($phase.Id) — $($phase.Title)  _( $($phase.Weeks) )_
_$($phase.Goal)_
$($chapterLines -join "`n")
"@
}
$roadmap = @"
# Learning Roadmap (≈ 1 Year, Intensive)

Work top to bottom. Each item is a prompt that generates one chapter. Check items off as you
complete both the reading and the hands-on labs. Respect prerequisites in
[DEPENDENCY_GRAPH.md](DEPENDENCY_GRAPH.md).

**Weekly cadence target:** 8-12 focused hours. **Total prompts:** $totalPrompts.

## Suggested pacing
| Block | Phases | Theme |
|-------|--------|-------|
| Foundations | Phase-00 to Phase-02 | CS, systems, distributed theory |
| Cloud & Storage | Phase-03 to Phase-04 | Azure and table formats |
| Core Data Engineering | Phase-05 to Phase-08 | Lakehouse, modeling, streaming, governance |
| Platform & Security | Phase-09 to Phase-10 | DataOps, IaC, security |
| AI Platform | Phase-11 to Phase-13 | MLOps, LLMOps, agents, vector/graph |
| Architecture & Domains | Phase-14 to Phase-17 | EDA, mesh, verticals |
| Run & Lead | Phase-18 to Phase-19 | FinOps, reliability, leadership |
| Capstone | Phase-20 | Integration and role-readiness |

## Detailed checklist
$($roadmapSections -join "`n")

## Resources (use throughout)
$(($resources | ForEach-Object { "- **$($_.Area)** — " + (($_.Files | ForEach-Object { $_.Title }) -join '; ') }) -join "`n")
"@
Set-Content -Path (Join-Path $root 'ROADMAP.md') -Value $roadmap -Encoding UTF8

# DEPENDENCY_GRAPH.md
$mermaidPhaseEdges = @'
graph TD
    P00[Phase-00 Foundations] --> P01[Phase-01 Enterprise Architecture]
    P00 --> P02[Phase-02 Distributed Systems]
    P02 --> P03[Phase-03 Cloud & Azure]
    P03 --> P04[Phase-04 Storage & Table Formats]
    P04 --> P05[Phase-05 Data Engineering & Lakehouse]
    P05 --> P06[Phase-06 Data Modeling]
    P05 --> P07[Phase-07 Streaming]
    P05 --> P08[Phase-08 Governance & Quality]
    P05 --> P09[Phase-09 DataOps & Platform]
    P03 --> P10[Phase-10 Security & Identity]
    P08 --> P10
    P09 --> P11[Phase-11 AI Platform & MLOps]
    P11 --> P12[Phase-12 LLMOps & Agentic AI]
    P12 --> P13[Phase-13 Knowledge Graphs & Vectors]
    P07 --> P14[Phase-14 EDA & Integration]
    P01 --> P14
    P08 --> P15[Phase-15 Data Mesh & Fabric]
    P01 --> P15
    P07 --> P16[Phase-16 Domain Platforms]
    P10 --> P17[Phase-17 Industry Verticals]
    P16 --> P17
    P09 --> P18[Phase-18 FinOps & Reliability]
    P01 --> P19[Phase-19 Leadership & Strategy]
    P18 --> P19
    P05 --> P20[Phase-20 Capstone & Career]
    P12 --> P20
    P19 --> P20
'@
$chapterPrereqRows = foreach ($phase in $phases) {
    foreach ($c in $phase.Chapters) {
        $pr = ($c.Prereq -replace '\r?\n',' ').Trim()
        "| $($phase.Id)/$($c.N)_$($c.Title -replace '[^A-Za-z0-9]+','_') | $pr |"
    }
}
$depGraph = @"
# Dependency Graph & Prerequisites

This graph shows the recommended learning order. Arrows mean "should be understood before".
Within a phase, chapters are ordered; cross-phase prerequisites are called out per chapter
inside each prompt file and summarized in the table below.

## Phase-level dependency graph
``````mermaid
$mermaidPhaseEdges
``````

## Reading principles
- **Foundations first:** Phase-00 unlocks everything. Do not skip it.
- **Azure spine:** Phase-03 -> Phase-04 -> Phase-05 is the backbone for all data work.
- **AI track:** Phase-11 -> Phase-12 -> Phase-13 build on ML foundations and streaming/governance.
- **Leadership track:** Phase-01 and Phase-19 can be read in parallel with technical phases.
- **Capstones last:** Phase-20 integrates prior phases; attempt after the relevant tracks.

## Chapter-level prerequisites
| Chapter (prompt) | Prerequisites |
|------------------|---------------|
$($chapterPrereqRows -join "`n")

[Back to README](README.md) - [Roadmap](ROADMAP.md)
"@
Set-Content -Path (Join-Path $root 'DEPENDENCY_GRAPH.md') -Value $depGraph -Encoding UTF8

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host "Generated $totalPrompts prompt files across $($phases.Count) phases + Resources." -ForegroundColor Green
Write-Host "Top-level docs: README.md, ROADMAP.md, DEPENDENCY_GRAPH.md" -ForegroundColor Green
$generated | Group-Object Phase | ForEach-Object {
    Write-Host ("  {0,-24} {1} files" -f $_.Name, $_.Count)
}
