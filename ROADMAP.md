# Learning Roadmap (≈ 1 Year, Intensive)

Work top to bottom. Each item is a prompt that generates one chapter. Check items off as you
complete both the reading and the hands-on labs. Respect prerequisites in
[DEPENDENCY_GRAPH.md](DEPENDENCY_GRAPH.md).

**Weekly cadence target:** 8-12 focused hours. **Total prompts:** 165.

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

### Phase-00 — Foundations & Prerequisites  _( Weeks 1-3 )_
_Rebuild the computer-science and systems bedrock every architect relies on._
  - [ ] Phase-00/01 — Introduction and How To Use This Handbook  →  generates `Introduction.md`
  - [ ] Phase-00/02 — Computer Science Fundamentals  →  generates `Computer_Science_Fundamentals.md`
  - [ ] Phase-00/03 — Operating Systems for Data Engineers  →  generates `Operating_Systems.md`
  - [ ] Phase-00/04 — Networking Fundamentals  →  generates `Networking_Fundamentals.md`
  - [ ] Phase-00/05 — Storage Systems Fundamentals  →  generates `Storage_Systems_Fundamentals.md`
  - [ ] Phase-00/06 — Concurrency and Parallelism  →  generates `Concurrency_and_Parallelism.md`
  - [ ] Phase-00/07 — Data Structures and Algorithms for Data Engineering  →  generates `Data_Structures_and_Algorithms.md`
  - [ ] Phase-00/08 — Distributed Systems Primer  →  generates `Distributed_Systems_Primer.md`

### Phase-01 — Enterprise Architecture Foundations  _( Weeks 4-6 )_
_Think and communicate like an enterprise architect: frameworks, governance, and decisions._
  - [ ] Phase-01/01 — Enterprise Architecture Foundations  →  generates `Enterprise_Architecture_Foundations.md`
  - [ ] Phase-01/02 — Architecture Governance  →  generates `Architecture_Governance.md`
  - [ ] Phase-01/03 — Architecture Decision Records  →  generates `Architecture_Decision_Records.md`
  - [ ] Phase-01/04 — Solution Architecture Practice  →  generates `Solution_Architecture_Practice.md`
  - [ ] Phase-01/05 — Domain Driven Design  →  generates `Domain_Driven_Design.md`
  - [ ] Phase-01/06 — Business Capability Modeling  →  generates `Business_Capability_Modeling.md`
  - [ ] Phase-01/07 — Technical Strategy and Roadmaps  →  generates `Technical_Strategy_and_Roadmaps.md`

### Phase-02 — Distributed Systems Deep Dive  _( Weeks 7-10 )_
_Master the theory and practice that underpins every scalable data platform._
  - [ ] Phase-02/01 — Consensus and Coordination  →  generates `Consensus_and_Coordination.md`
  - [ ] Phase-02/02 — Replication and Consistency  →  generates `Replication_and_Consistency.md`
  - [ ] Phase-02/03 — Partitioning and Sharding  →  generates `Partitioning_and_Sharding.md`
  - [ ] Phase-02/04 — CAP and PACELC  →  generates `CAP_and_PACELC.md`
  - [ ] Phase-02/05 — Distributed Transactions  →  generates `Distributed_Transactions.md`
  - [ ] Phase-02/06 — Time, Clocks and Ordering  →  generates `Time_Clocks_and_Ordering.md`
  - [ ] Phase-02/07 — Fault Tolerance and Resilience  →  generates `Fault_Tolerance_and_Resilience.md`
  - [ ] Phase-02/08 — Distributed Systems Case Studies  →  generates `Distributed_Systems_Case_Studies.md`

### Phase-03 — Cloud & Azure Architecture  _( Weeks 11-14 )_
_Design secure, scalable cloud foundations with Azure as the primary platform._
  - [ ] Phase-03/01 — Cloud Architecture Fundamentals  →  generates `Cloud_Architecture_Fundamentals.md`
  - [ ] Phase-03/02 — Azure Core Architecture  →  generates `Azure_Core_Architecture.md`
  - [ ] Phase-03/03 — Azure Landing Zones  →  generates `Azure_Landing_Zones.md`
  - [ ] Phase-03/04 — Azure Networking  →  generates `Azure_Networking.md`
  - [ ] Phase-03/05 — Azure Compute and Containers  →  generates `Azure_Compute_and_Containers.md`
  - [ ] Phase-03/06 — Azure Storage Services  →  generates `Azure_Storage_Services.md`
  - [ ] Phase-03/07 — Azure Well-Architected Framework  →  generates `Well_Architected_Framework.md`
  - [ ] Phase-03/08 — Multi-Cloud and Hybrid Architecture  →  generates `Multi_Cloud_and_Hybrid.md`

### Phase-04 — Storage Systems & Table Formats  _( Weeks 15-17 )_
_Understand file formats and open table formats that define the lakehouse._
  - [ ] Phase-04/01 — File Formats: Parquet, ORC, Avro  →  generates `File_Formats.md`
  - [ ] Phase-04/02 — Columnar Storage Internals  →  generates `Columnar_Storage_Internals.md`
  - [ ] Phase-04/03 — Object Storage and Data Lakes  →  generates `Object_Storage_and_Data_Lakes.md`
  - [ ] Phase-04/04 — Delta Lake  →  generates `Delta_Lake.md`
  - [ ] Phase-04/05 — Apache Iceberg  →  generates `Apache_Iceberg.md`
  - [ ] Phase-04/06 — Apache Hudi  →  generates `Apache_Hudi.md`
  - [ ] Phase-04/07 — Table Format Comparison and Selection  →  generates `Table_Format_Comparison.md`
  - [ ] Phase-04/08 — Compression and Encoding Strategies  →  generates `Compression_and_Encoding.md`

### Phase-05 — Modern Data Engineering & Lakehouse  _( Weeks 18-22 )_
_Build the lakehouse and batch platforms at the heart of modern data engineering._
  - [ ] Phase-05/01 — Modern Data Stack Overview  →  generates `Modern_Data_Stack_Overview.md`
  - [ ] Phase-05/02 — Lakehouse Architecture  →  generates `Lakehouse_Architecture.md`
  - [ ] Phase-05/03 — Medallion Architecture  →  generates `Medallion_Architecture.md`
  - [ ] Phase-05/04 — Apache Spark Internals  →  generates `Apache_Spark_Internals.md`
  - [ ] Phase-05/05 — Databricks Platform  →  generates `Databricks_Platform.md`
  - [ ] Phase-05/06 — Azure Data Factory and Synapse  →  generates `Azure_Data_Factory_and_Synapse.md`
  - [ ] Phase-05/07 — Microsoft Fabric  →  generates `Microsoft_Fabric.md`
  - [ ] Phase-05/08 — dbt and Analytics Engineering  →  generates `dbt_and_Transformation.md`
  - [ ] Phase-05/09 — Batch Pipeline Design  →  generates `Batch_Pipeline_Design.md`

### Phase-06 — Data Modeling & Warehousing  _( Weeks 23-25 )_
_Model data for analytics at scale with dimensional, vault, and semantic techniques._
  - [ ] Phase-06/01 — Dimensional Modeling  →  generates `Dimensional_Modeling.md`
  - [ ] Phase-06/02 — Data Vault 2.0  →  generates `Data_Vault.md`
  - [ ] Phase-06/03 — Normalization and OLTP Modeling  →  generates `Normalization_and_OLTP.md`
  - [ ] Phase-06/04 — OLAP and Cube Modeling  →  generates `OLAP_and_Cubes.md`
  - [ ] Phase-06/05 — Slowly Changing Dimensions  →  generates `Slowly_Changing_Dimensions.md`
  - [ ] Phase-06/06 — Semantic Layer and Metrics  →  generates `Semantic_Layer_and_Metrics.md`
  - [ ] Phase-06/07 — Data Warehouse Architecture  →  generates `Data_Warehouse_Architecture.md`
  - [ ] Phase-06/08 — SQL Server and Azure SQL  →  generates `SQL_Server_and_Azure_SQL.md`

### Phase-07 — Streaming & Real-Time Analytics  _( Weeks 26-29 )_
_Design low-latency streaming and real-time analytics systems._
  - [ ] Phase-07/01 — Streaming Fundamentals  →  generates `Streaming_Fundamentals.md`
  - [ ] Phase-07/02 — Apache Kafka  →  generates `Apache_Kafka.md`
  - [ ] Phase-07/03 — Azure Event Hubs and Stream Analytics  →  generates `Azure_Event_Hubs_and_Stream_Analytics.md`
  - [ ] Phase-07/04 — Apache Flink  →  generates `Apache_Flink.md`
  - [ ] Phase-07/05 — Spark Structured Streaming  →  generates `Spark_Structured_Streaming.md`
  - [ ] Phase-07/06 — Change Data Capture  →  generates `Change_Data_Capture.md`
  - [ ] Phase-07/07 — Real-Time Analytics: ClickHouse and Druid  →  generates `Real_Time_Analytics.md`
  - [ ] Phase-07/08 — Streaming Patterns and Delivery Semantics  →  generates `Streaming_Patterns.md`

### Phase-08 — Data Governance & Quality  _( Weeks 30-32 )_
_Make data trustworthy, discoverable, and compliant across the enterprise._
  - [ ] Phase-08/01 — Data Governance Foundations  →  generates `Data_Governance_Foundations.md`
  - [ ] Phase-08/02 — Data Catalog and Lineage  →  generates `Data_Catalog_and_Lineage.md`
  - [ ] Phase-08/03 — Data Quality with Great Expectations  →  generates `Data_Quality.md`
  - [ ] Phase-08/04 — Metadata Management: OpenMetadata and Atlas  →  generates `Metadata_Management.md`
  - [ ] Phase-08/05 — Master Data Management  →  generates `Master_Data_Management.md`
  - [ ] Phase-08/06 — Microsoft Purview  →  generates `Microsoft_Purview.md`
  - [ ] Phase-08/07 — Data Contracts  →  generates `Data_Contracts.md`

### Phase-09 — DataOps, Platform Engineering & DevOps  _( Weeks 33-37 )_
_Operationalize data platforms with automation, IaC, and platform engineering._
  - [ ] Phase-09/01 — DataOps Foundations  →  generates `DataOps_Foundations.md`
  - [ ] Phase-09/02 — Platform Engineering  →  generates `Platform_Engineering.md`
  - [ ] Phase-09/03 — DevOps and CI/CD  →  generates `DevOps_and_CICD.md`
  - [ ] Phase-09/04 — Infrastructure as Code with Terraform  →  generates `Infrastructure_as_Code.md`
  - [ ] Phase-09/05 — Containers with Docker  →  generates `Containers_Docker.md`
  - [ ] Phase-09/06 — Kubernetes  →  generates `Kubernetes.md`
  - [ ] Phase-09/07 — Orchestration with Airflow  →  generates `Orchestration_Airflow.md`
  - [ ] Phase-09/08 — GitOps and Environment Management  →  generates `GitOps_and_Environments.md`

### Phase-10 — Security, Identity & Compliance  _( Weeks 38-40 )_
_Secure data and AI platforms with zero-trust identity and compliance by design._
  - [ ] Phase-10/01 — Security Foundations  →  generates `Security_Foundations.md`
  - [ ] Phase-10/02 — Identity and Access Management with Entra  →  generates `Identity_and_Access_Management.md`
  - [ ] Phase-10/03 — Data Security and Encryption  →  generates `Data_Security_and_Encryption.md`
  - [ ] Phase-10/04 — Network Security and Zero Trust  →  generates `Network_Security_Zero_Trust.md`
  - [ ] Phase-10/05 — Secrets and Key Management  →  generates `Secrets_and_Key_Management.md`
  - [ ] Phase-10/06 — Compliance and Regulatory Frameworks  →  generates `Compliance_and_Regulatory.md`
  - [ ] Phase-10/07 — Data Privacy and PII Protection  →  generates `Data_Privacy_and_PII.md`

### Phase-11 — AI Platform Engineering & MLOps  _( Weeks 41-44 )_
_Industrialize machine learning with feature stores, MLOps, and serving._
  - [ ] Phase-11/01 — Machine Learning Foundations  →  generates `Machine_Learning_Foundations.md`
  - [ ] Phase-11/02 — Feature Stores with Feast  →  generates `Feature_Stores.md`
  - [ ] Phase-11/03 — MLOps and MLflow  →  generates `MLOps_and_MLflow.md`
  - [ ] Phase-11/04 — Model Serving and Ray  →  generates `Model_Serving_and_Ray.md`
  - [ ] Phase-11/05 — Azure Machine Learning  →  generates `Azure_Machine_Learning.md`
  - [ ] Phase-11/06 — ML Pipeline Architecture  →  generates `ML_Pipeline_Architecture.md`
  - [ ] Phase-11/07 — Responsible AI  →  generates `Responsible_AI.md`

### Phase-12 — LLMOps & Agentic AI  _( Weeks 45-49 )_
_Build, operate, and govern LLM-powered and agentic systems._
  - [ ] Phase-12/01 — Large Language Model Foundations  →  generates `LLM_Foundations.md`
  - [ ] Phase-12/02 — Prompt Engineering  →  generates `Prompt_Engineering.md`
  - [ ] Phase-12/03 — Retrieval Augmented Generation  →  generates `Retrieval_Augmented_Generation.md`
  - [ ] Phase-12/04 — LLMOps  →  generates `LLMOps.md`
  - [ ] Phase-12/05 — Agentic AI Architecture  →  generates `Agentic_AI_Architecture.md`
  - [ ] Phase-12/06 — Model Context Protocol (MCP)  →  generates `Model_Context_Protocol_MCP.md`
  - [ ] Phase-12/07 — Azure OpenAI and AI Foundry  →  generates `Azure_OpenAI_and_AI_Foundry.md`
  - [ ] Phase-12/08 — LangChain and LlamaIndex  →  generates `LangChain_and_LlamaIndex.md`
  - [ ] Phase-12/09 — Evaluation and Guardrails  →  generates `Evaluation_and_Guardrails.md`

### Phase-13 — Knowledge Graphs & Vector Systems  _( Weeks 50-51 )_
_Model knowledge and semantics with graphs, embeddings, and vector search._
  - [ ] Phase-13/01 — Vector Databases: Qdrant and Milvus  →  generates `Vector_Databases.md`
  - [ ] Phase-13/02 — Knowledge Graphs with Neo4j  →  generates `Knowledge_Graphs.md`
  - [ ] Phase-13/03 — Embeddings and Semantic Search  →  generates `Embeddings_and_Semantic_Search.md`
  - [ ] Phase-13/04 — GraphRAG  →  generates `GraphRAG.md`
  - [ ] Phase-13/05 — Ontologies and Taxonomies  →  generates `Ontologies_and_Taxonomies.md`

### Phase-14 — Event-Driven Architecture & Integration  _( Weeks 52-54 )_
_Design decoupled, event-driven, and integration architectures._
  - [ ] Phase-14/01 — Event-Driven Architecture  →  generates `Event_Driven_Architecture.md`
  - [ ] Phase-14/02 — Microservices Architecture  →  generates `Microservices_Architecture.md`
  - [ ] Phase-14/03 — CQRS  →  generates `CQRS.md`
  - [ ] Phase-14/04 — Event Sourcing  →  generates `Event_Sourcing.md`
  - [ ] Phase-14/05 — API Design: REST, GraphQL, gRPC  →  generates `API_Design.md`
  - [ ] Phase-14/06 — Enterprise Integration Patterns  →  generates `Enterprise_Integration_Patterns.md`
  - [ ] Phase-14/07 — Message Brokers and Queues  →  generates `Message_Brokers_and_Queues.md`

### Phase-15 — Data Mesh & Data Fabric  _( Weeks 55-56 )_
_Scale data ownership and interoperability with mesh and fabric paradigms._
  - [ ] Phase-15/01 — Data Mesh Principles  →  generates `Data_Mesh_Principles.md`
  - [ ] Phase-15/02 — Data Products  →  generates `Data_Products.md`
  - [ ] Phase-15/03 — Data Fabric  →  generates `Data_Fabric.md`
  - [ ] Phase-15/04 — Federated Governance  →  generates `Federated_Governance.md`
  - [ ] Phase-15/05 — Self-Serve Data Platform  →  generates `Self_Serve_Data_Platform.md`

### Phase-16 — Domain-Specific & Frontier Data Platforms  _( Weeks 57-60 )_
_Apply architecture to IoT, robotics, autonomy, space, and geospatial domains._
  - [ ] Phase-16/01 — IoT Data Platforms  →  generates `IoT_Data_Platforms.md`
  - [ ] Phase-16/02 — Industrial IoT (IIoT)  →  generates `Industrial_IoT.md`
  - [ ] Phase-16/03 — Robotics and ROS2  →  generates `Robotics_and_ROS2.md`
  - [ ] Phase-16/04 — Autonomous Vehicles Data  →  generates `Autonomous_Vehicles_Data.md`
  - [ ] Phase-16/05 — Space Data Platforms  →  generates `Space_Data_Platforms.md`
  - [ ] Phase-16/06 — Earth Observation and Geospatial Analytics  →  generates `Earth_Observation_and_Geospatial.md`
  - [ ] Phase-16/07 — Digital Twins  →  generates `Digital_Twins.md`

### Phase-17 — Industry Vertical Platforms  _( Weeks 61-63 )_
_Architect regulated, high-stakes data platforms across key industries._
  - [ ] Phase-17/01 — Healthcare Data Platforms  →  generates `Healthcare_Data_Platforms.md`
  - [ ] Phase-17/02 — Financial Data Platforms  →  generates `Financial_Data_Platforms.md`
  - [ ] Phase-17/03 — Aviation Data Platforms  →  generates `Aviation_Data_Platforms.md`
  - [ ] Phase-17/04 — Smart Cities  →  generates `Smart_Cities.md`
  - [ ] Phase-17/05 — Retail and E-Commerce Data  →  generates `Retail_and_Ecommerce_Data.md`

### Phase-18 — FinOps, Observability & Reliability  _( Weeks 64-66 )_
_Run data and AI platforms cost-efficiently and reliably in production._
  - [ ] Phase-18/01 — FinOps and Cost Optimization  →  generates `FinOps_and_Cost_Optimization.md`
  - [ ] Phase-18/02 — Observability with OpenTelemetry  →  generates `Observability_OpenTelemetry.md`
  - [ ] Phase-18/03 — Monitoring with Prometheus and Grafana  →  generates `Monitoring_Prometheus_Grafana.md`
  - [ ] Phase-18/04 — Reliability and SRE  →  generates `Reliability_and_SRE.md`
  - [ ] Phase-18/05 — Performance Engineering  →  generates `Performance_Engineering.md`

### Phase-19 — Leadership & Technical Strategy  _( Weeks 67-70 )_
_Lead architecture, teams, and strategy at staff-through-executive levels._
  - [ ] Phase-19/01 — Technical Leadership  →  generates `Technical_Leadership.md`
  - [ ] Phase-19/02 — Architecture Reviews  →  generates `Architecture_Reviews.md`
  - [ ] Phase-19/03 — Stakeholder Management  →  generates `Stakeholder_Management.md`
  - [ ] Phase-19/04 — Technical Writing  →  generates `Technical_Writing.md`
  - [ ] Phase-19/05 — Hiring and Interviewing  →  generates `Hiring_and_Interviewing.md`
  - [ ] Phase-19/06 — Mentoring and Team Building  →  generates `Mentoring_and_Team_Building.md`
  - [ ] Phase-19/07 — Roadmap and Portfolio Planning  →  generates `Roadmap_and_Portfolio_Planning.md`
  - [ ] Phase-19/08 — CDO and CAIO Playbook  →  generates `CDO_and_CAIO_Playbook.md`

### Phase-20 — Capstone & Career  _( Weeks 71-73 )_
_Integrate everything into capstone platforms and role-readiness._
  - [ ] Phase-20/01 — Capstone: Enterprise Data Platform  →  generates `Capstone_Enterprise_Data_Platform.md`
  - [ ] Phase-20/02 — Capstone: Enterprise AI Platform  →  generates `Capstone_Enterprise_AI_Platform.md`
  - [ ] Phase-20/03 — System Design Interview Prep  →  generates `System_Design_Interview_Prep.md`
  - [ ] Phase-20/04 — Architecture Interview Prep  →  generates `Architecture_Interview_Prep.md`
  - [ ] Phase-20/05 — Staff and Principal Promotion  →  generates `Staff_Principal_Promotion.md`
  - [ ] Phase-20/06 — Portfolio and Case Studies  →  generates `Portfolio_and_Case_Studies.md`

## Resources (use throughout)
- **Architecture** — Reference Architectures Catalog; Architecture Patterns Catalog
- **CaseStudies** — Netflix Data Platform Case Study; Uber Data Infrastructure Case Study; Airbnb Minerva Case Study; Spotify Data Platform Case Study; LinkedIn and the Birth of Kafka
- **Labs** — Lab Environment Setup; End-to-End Lakehouse Lab; Streaming Lab; RAG Lab
- **Interview** — Interview Question Bank; System Design Scenarios
- **References** — Glossary; Reading List and Further Study
