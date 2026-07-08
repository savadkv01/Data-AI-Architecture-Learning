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
```
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
```

## Curriculum at a glance
- **21 phases**, **164 prompt files** total (149 phased + 15 resources).
- Targets **~1 year** of intensive study (see [ROADMAP.md](ROADMAP.md)).

| Phase | Focus | Chapters | Timeline |
|-------|-------|----------|----------|
| **Phase-00** | Foundations & Prerequisites | 8 | Weeks 1-3 |
| **Phase-01** | Enterprise Architecture Foundations | 7 | Weeks 4-6 |
| **Phase-02** | Distributed Systems Deep Dive | 8 | Weeks 7-10 |
| **Phase-03** | Cloud & Azure Architecture | 8 | Weeks 11-14 |
| **Phase-04** | Storage Systems & Table Formats | 8 | Weeks 15-17 |
| **Phase-05** | Modern Data Engineering & Lakehouse | 9 | Weeks 18-22 |
| **Phase-06** | Data Modeling & Warehousing | 7 | Weeks 23-25 |
| **Phase-07** | Streaming & Real-Time Analytics | 8 | Weeks 26-29 |
| **Phase-08** | Data Governance & Quality | 7 | Weeks 30-32 |
| **Phase-09** | DataOps, Platform Engineering & DevOps | 8 | Weeks 33-37 |
| **Phase-10** | Security, Identity & Compliance | 7 | Weeks 38-40 |
| **Phase-11** | AI Platform Engineering & MLOps | 7 | Weeks 41-44 |
| **Phase-12** | LLMOps & Agentic AI | 9 | Weeks 45-49 |
| **Phase-13** | Knowledge Graphs & Vector Systems | 5 | Weeks 50-51 |
| **Phase-14** | Event-Driven Architecture & Integration | 7 | Weeks 52-54 |
| **Phase-15** | Data Mesh & Data Fabric | 5 | Weeks 55-56 |
| **Phase-16** | Domain-Specific & Frontier Data Platforms | 7 | Weeks 57-60 |
| **Phase-17** | Industry Vertical Platforms | 5 | Weeks 61-63 |
| **Phase-18** | FinOps, Observability & Reliability | 5 | Weeks 64-66 |
| **Phase-19** | Leadership & Technical Strategy | 8 | Weeks 67-70 |
| **Phase-20** | Capstone & Career | 6 | Weeks 71-73 |

## How to use
1. Pick a phase in `.github/prompts/` and open a `*.prompt.md` file in VS Code.
2. Run it with **GitHub Copilot (agent mode)** or reference it from Copilot Chat.
3. Copilot generates the corresponding standalone `.md` chapter.
4. Follow the order in [ROADMAP.md](ROADMAP.md); respect prerequisites in [DEPENDENCY_GRAPH.md](DEPENDENCY_GRAPH.md).

## Regenerating the prompt library
All prompts and index docs are generated from a single source of truth:
```powershell
pwsh ./generate_curriculum.ps1   # or: powershell -File ./generate_curriculum.ps1
```

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
