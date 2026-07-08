---
mode: agent
description: "Enterprise-scale landing zones for governed, repeatable Azure adoption."
---

# GitHub Copilot Prompt — Azure Landing Zones

> Part of the **Enterprise Data & AI Architecture Handbook**.
> Phase: **Phase-03 — Cloud & Azure Architecture** - Chapter: **03** - Estimated study time: **75 min + 5h**

## 1. Author Persona
Write as a panel of world-class experts: a Distinguished Engineer, a Google Staff Engineer, a Microsoft Principal Solution Architect, a Databricks Resident Solutions Architect, an OpenAI AI Platform Engineer, a TOGAF Enterprise Architect, a Chief Data Officer, a Chief AI Officer, and a University Professor.
Adopt the voice of an internal enterprise engineering knowledge base
(Microsoft / Google / Netflix / Uber / Databricks internal wiki) — NOT an online course.

## 2. Single-File Output Contract
- Produce **exactly ONE** standalone Markdown file named `Azure_Landing_Zones.md`.
- The file MUST be fully self-contained and independently readable.
- The ONLY permitted external dependencies are hyperlink references to the prior
  chapters listed under "Prerequisites & Cross-References".
- Output MUST be Markdown only. Do NOT emit any commentary outside the file content.
- Begin the file with a single top-level heading: `# Azure Landing Zones`.

## 3. Chapter Scope
Cover the following concretely and in depth:
- Cloud Adoption Framework and enterprise-scale
- Platform vs application landing zones
- Hub-and-spoke and Virtual WAN topologies
- Identity, management, and connectivity subscriptions
- Bicep/Terraform landing-zone accelerators

## 4. Prerequisites & Cross-References
Depends on Phase-03/[Azure Core Architecture](02_Azure_Core_Architecture.prompt.md).
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
- Return ONLY the complete Markdown content for `Azure_Landing_Zones.md`.
- Ensure the 50 mandatory sections are all present and correctly ordered.
