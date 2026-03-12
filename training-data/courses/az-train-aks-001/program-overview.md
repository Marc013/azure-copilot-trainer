# AKS Training Program — Overview and Timeline

## 1. Audience Profile

| Attribute     | Value                                                                  |
| ------------- | ---------------------------------------------------------------------- |
| Role          | Azure Engineer                                                         |
| Baseline      | Familiar with Azure IaaS/PaaS; limited container/Kubernetes experience |
| Goals         | Deploy, operate, and maintain AKS in production at enterprise scale    |
| Delivery mode | Self-paced; online labs with real Azure subscriptions                  |
| Duration      | 12 weeks                                                               |
| Weekly effort | ~8 hours (3 h reading + 5 h hands-on)                                  |

---

## 2. Program Timeline

| Week | Module           | Theme                                              |
| ---- | ---------------- | -------------------------------------------------- |
| 1    | Module 00 + 01   | Prerequisites · AKS Fundamentals & Architecture    |
| 2    | Module 02        | Private Cluster · Hub-Spoke Networking · AGIC      |
| 3    | Module 03        | ACR Integration · Image Lifecycle                  |
| 4    | Module 04        | Identity · Microsoft Entra ID · Workload Identity  |
| 5    | Module 05        | CI/CD with Azure DevOps Pipelines                  |
| 6    | Module 06        | Observability · Container Insights · Log Analytics |
| 7    | Module 07        | Scaling · HPA · KEDA · Cluster Autoscaler          |
| 8    | Module 08        | Upgrades · Node OS · Maintenance Windows           |
| 9    | Module 09        | Backup · Velero · Business Continuity              |
| 10   | Module 10        | Governance · Azure Policy · Cost Management        |
| 11   | Scenario 01 + 02 | Production Incident Response · Security Hardening  |
| 12   | Final Assessment | End-to-end AKS Store Demo evaluation               |

---

## 3. Module Table with Objective IDs

| Module | Title                        | Prerequisites | Objective IDs                          |
| ------ | ---------------------------- | ------------- | -------------------------------------- |
| M00    | Prerequisites                | None          | PRE-01, PRE-02, PRE-03                 |
| M01    | AKS Fundamentals             | M00           | AKS-01, AKS-02, AKS-03, AKS-04         |
| M02    | Private Cluster & Networking | M01           | NET-01, NET-02, NET-03, NET-04, NET-05 |
| M03    | ACR Integration              | M01           | ACR-01, ACR-02, ACR-03                 |
| M04    | Identity & Security          | M02, M03      | IDN-01, IDN-02, IDN-03, IDN-04         |
| M05    | CI/CD with Azure DevOps      | M03, M04      | CICD-01, CICD-02, CICD-03, CICD-04     |
| M06    | Observability                | M02           | OBS-01, OBS-02, OBS-03, OBS-04         |
| M07    | Scaling                      | M01, M06      | SCA-01, SCA-02, SCA-03                 |
| M08    | Upgrades & Maintenance       | M02, M04      | UPG-01, UPG-02, UPG-03                 |
| M09    | Backup & DR                  | M04           | BDR-01, BDR-02, BDR-03                 |
| M10    | Governance & Cost            | M04           | GOV-01, GOV-02, GOV-03, GOV-04         |

---

## 4. Objective Map

### Prerequisites (PRE)
| ID     | Objective                                                                                |
| ------ | ---------------------------------------------------------------------------------------- |
| PRE-01 | Set up Azure subscription, resource groups, and RBAC for labs                            |
| PRE-02 | Install required tooling: Azure CLI, kubectl, Bicep CLI, kubelogin, PowerShell Az module |
| PRE-03 | Verify access to Azure DevOps organization and project                                   |

### AKS Fundamentals (AKS)
| ID     | Objective                                                                |
| ------ | ------------------------------------------------------------------------ |
| AKS-01 | Explain AKS control-plane vs. node-pool architecture                     |
| AKS-02 | Compare networking options: Kubenet, Azure CNI, Azure CNI Overlay        |
| AKS-03 | Describe node pool types (system vs. user), VM SKUs, and OS disk options |
| AKS-04 | Explain the AKS baseline architecture with hub-spoke networking          |

### Networking (NET)
| ID     | Objective                                                   |
| ------ | ----------------------------------------------------------- |
| NET-01 | Design hub-spoke virtual network topology for AKS           |
| NET-02 | Deploy a private AKS cluster with private API server access |
| NET-03 | Configure Application Gateway WAF v2 and AGIC add-on        |
| NET-04 | Implement Azure CNI Overlay and Network Policies            |
| NET-05 | Restrict egress with Azure Firewall and UDRs                |

### ACR (ACR)
| ID     | Objective                                                             |
| ------ | --------------------------------------------------------------------- |
| ACR-01 | Deploy Azure Container Registry with premium SKU and private endpoint |
| ACR-02 | Attach ACR to AKS using AcrPull managed identity role assignment      |
| ACR-03 | Build, tag, and push Azure-Samples/aks-store-demo images to ACR       |

### Identity (IDN)
| ID     | Objective                                                                              |
| ------ | -------------------------------------------------------------------------------------- |
| IDN-01 | Enable AKS-managed Microsoft Entra ID integration and Azure RBAC for Kubernetes        |
| IDN-02 | Configure Workload Identity with Kubernetes service accounts and federated credentials |
| IDN-03 | Apply Kubernetes RBAC (ClusterRole, RoleBinding) for least-privilege access            |
| IDN-04 | Integrate Azure Key Vault with AKS using Secrets Store CSI driver                      |

### CI/CD (CICD)
| ID      | Objective                                                                       |
| ------- | ------------------------------------------------------------------------------- |
| CICD-01 | Create Azure DevOps pipeline with Docker build stage pushing to ACR             |
| CICD-02 | Add KubernetesManifest deploy stage using ARM service connection to private AKS |
| CICD-03 | Implement environment gates and approval policies before production release     |
| CICD-04 | Configure image tag strategy and rollback trigger in pipeline                   |

### Observability (OBS)
| ID     | Objective                                                                |
| ------ | ------------------------------------------------------------------------ |
| OBS-01 | Enable Container Insights and send metrics to Log Analytics workspace    |
| OBS-02 | Create KQL queries for pod crash loops, OOM kills, and node CPU pressure |
| OBS-03 | Configure Azure Monitor alerts and action groups for SLO breach          |
| OBS-04 | Deploy Prometheus-compatible scraping with Azure Managed Prometheus      |

### Scaling (SCA)
| ID     | Objective                                                                 |
| ------ | ------------------------------------------------------------------------- |
| SCA-01 | Configure Horizontal Pod Autoscaler (HPA) based on CPU and custom metrics |
| SCA-02 | Enable and tune Cluster Autoscaler on a user node pool                    |
| SCA-03 | Deploy KEDA with Azure Service Bus scaler for event-driven scaling        |

### Upgrades (UPG)
| ID     | Objective                                                             |
| ------ | --------------------------------------------------------------------- |
| UPG-01 | Set cluster auto-upgrade channel and node OS auto-upgrade channel     |
| UPG-02 | Perform manual control-plane and node-pool upgrade with zero downtime |
| UPG-03 | Configure planned maintenance windows for upgrade operations          |

### Backup & DR (BDR)
| ID     | Objective                                                       |
| ------ | --------------------------------------------------------------- |
| BDR-01 | Install and configure Azure Backup for AKS                      |
| BDR-02 | Create backup policies for cluster state and persistent volumes |
| BDR-03 | Execute a restore operation and validate workload recovery      |

### Governance & Cost (GOV)
| ID     | Objective                                                                   |
| ------ | --------------------------------------------------------------------------- |
| GOV-01 | Apply built-in Azure Policy definitions to enforce AKS security baseline    |
| GOV-02 | Implement namespace resource quotas and limit ranges                        |
| GOV-03 | Analyse AKS cost with Cost Management and understand node pool cost drivers |
| GOV-04 | Apply AKS cost-optimisation recommendations: spot pools, right-sizing       |

---

## 5. Assessment Blueprint

| Domain                                  | Module IDs | Questions | Weight |
| --------------------------------------- | ---------- | --------- | ------ |
| Architecture & Networking               | M01, M02   | 6         | 20 %   |
| ACR & Identity                          | M03, M04   | 5         | 17 %   |
| CI/CD                                   | M05        | 4         | 13 %   |
| Observability & Scaling                 | M06, M07   | 5         | 17 %   |
| Upgrades & Maintenance                  | M08        | 4         | 13 %   |
| Backup, Governance & Cost               | M09, M10   | 4         | 13 %   |
| Practical Scenario (Bicep + PowerShell) | All        | 2 tasks   | 7 %    |

**Pass threshold:** ≥ 75 % overall; no domain below 60 %  
**Practical tasks:** Bicep deployment validation + PowerShell operational runbook  

---

## 6. Adaptation Rules

| Condition                            | Action                                             |
| ------------------------------------ | -------------------------------------------------- |
| Module checkpoint score < 70 %       | Repeat the remediation exercise before progressing |
| Practical lab fails CI/CD pipeline   | Review CICD-01 → CICD-04 and retry                 |
| Final assessment domain score < 60 % | Complete the linked remediation module             |

---

## Proof Links

| Claim                                          | Source                                                                                                                                                                                           | Confidence |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------- |
| AKS baseline architecture reference            | [learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks) | High       |
| Private AKS cluster recommended for production | [learn.microsoft.com/azure/aks/private-cluster](https://learn.microsoft.com/azure/aks/private-cluster)                                                                                           | High       |
| Azure DevOps CI/CD to AKS                      | [learn.microsoft.com/azure/devops/pipelines/tasks/reference/kubernetes-manifest-v1](https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/kubernetes-manifest-v1)                   | High       |
| AGIC overview and deployment options           | [learn.microsoft.com/azure/application-gateway/ingress-controller-overview](https://learn.microsoft.com/azure/application-gateway/ingress-controller-overview)                                   | High       |
