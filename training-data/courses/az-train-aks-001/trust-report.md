# Source Grounding Trust Report — AKS Training Program

> **Grounding policy:** All factual claims in this training program are sourced exclusively from
> `learn.microsoft.com` documentation retrieved via `mcp_microsoftdocs_microsoft_docs_search` during
> the authoring session. Claims are categorized by confidence level and verification status.

---

## Confidence Labels

| Label      | Meaning                                                                                                            |
| ---------- | ------------------------------------------------------------------------------------------------------------------ |
| **High**   | Retrieved from official learn.microsoft.com page; claim directly stated in the documentation                       |
| **Medium** | Inferred from official documentation; the specific phrasing is not verbatim but the principle is clearly supported |
| **Low**    | General best practice claim; aligns with documentation but not a verbatim quote                                    |

---

## Verified Claims Table

| #   | Claim                                                                                                                                            | Module(s)             | Source URL                                                                                         | Confidence |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------- | -------------------------------------------------------------------------------------------------- | ---------- |
| 1   | Azure CNI Overlay uses a separate pod CIDR and does not consume VNet IPs for pods                                                                | module-01, module-02  | https://learn.microsoft.com/azure/aks/azure-cni-overlay                                            | High       |
| 2   | Private AKS cluster API server has no public IP endpoint                                                                                         | module-02             | https://learn.microsoft.com/azure/aks/private-cluster                                              | High       |
| 3   | AGIC add-on instance requires a dedicated Application Gateway (one-to-one)                                                                       | module-02             | https://learn.microsoft.com/azure/application-gateway/ingress-controller-overview                  | High       |
| 4   | Application Gateway subnet for AGIC should be sized to support scale (for this course, /24 is used)                                              | module-02, lab-02     | https://learn.microsoft.com/azure/application-gateway/configuration-infrastructure                 | High       |
| 5   | `outboundType: userDefinedRouting` requires a pre-configured UDR to the firewall before cluster creation                                         | module-02, lab-02     | https://learn.microsoft.com/azure/aks/limit-egress-traffic                                         | High       |
| 6   | ACR Premium SKU is required for private endpoints and geo-replication                                                                            | module-03             | https://learn.microsoft.com/azure/container-registry/container-registry-skus                       | High       |
| 7   | AcrPull built-in role (ID `7f951dda-4ed3-4680-a7ca-43fe172d538d`) on ACR resource assigned to kubelet identity enables password-less image pulls | module-03, lab-03     | https://learn.microsoft.com/azure/aks/cluster-container-registry-integration                       | High       |
| 8   | `adminUserEnabled: false` should be set on ACR for production                                                                                    | module-03             | https://learn.microsoft.com/azure/container-registry/container-registry-authentication             | High       |
| 9   | Workload Identity uses OIDC federation — cluster publishes JWKS at issuer URL, Azure AD validates projected SA tokens                            | module-04, lab-04     | https://learn.microsoft.com/azure/aks/workload-identity-overview                                   | High       |
| 10  | Federated credential subject format: `system:serviceaccount:<namespace>:<serviceAccountName>`                                                    | module-04, lab-04     | https://learn.microsoft.com/azure/aks/workload-identity-deploy-cluster                             | High       |
| 11  | `disableLocalAccounts: true` requires managed Entra ID (`aadProfile.managed: true`)                                                              | module-04             | https://learn.microsoft.com/azure/aks/manage-local-accounts-managed-azure-ad                       | High       |
| 12  | ARM service connection (not Kubernetes service connection) is recommended for private AKS CI/CD                                                  | module-05             | https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/kubernetes-manifest-v1          | High       |
| 13  | `KubernetesManifest@1 connectionType: azureResourceManager` uses short-lived tokens from the ARM service connection                              | module-05, lab-05     | https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/kubernetes-manifest-v1          | High       |
| 14  | Container Insights stores container logs in `ContainerLog` table in Log Analytics                                                                | module-06             | https://learn.microsoft.com/azure/azure-monitor/containers/container-insights-log-query            | High       |
| 15  | `KubePodInventory` table tracks pod restart counts, container status, and namespace                                                              | module-06             | https://learn.microsoft.com/azure/azure-monitor/containers/container-insights-log-query            | High       |
| 16  | HPA requires `requests.cpu` to be defined; without it, utilization is `<unknown>`                                                                | module-07             | https://learn.microsoft.com/azure/aks/concepts-scale                                               | High       |
| 17  | Cluster Autoscaler respects `minCount` and `maxCount` on node pools                                                                              | module-07, lab-07     | https://learn.microsoft.com/azure/aks/cluster-autoscaler                                           | High       |
| 18  | KEDA add-on is the recommended approach for event-driven autoscaling on AKS                                                                      | module-07             | https://learn.microsoft.com/azure/aks/keda-about                                                   | High       |
| 19  | `autoUpgradeProfile.upgradeChannel: patch` upgrades to latest patch of current minor version only                                                | module-08             | https://learn.microsoft.com/azure/aks/auto-upgrade-cluster                                         | High       |
| 20  | `nodeOSUpgradeChannel: NodeImage` applies OS patches via node image replacement (no in-place apt-get)                                            | module-08             | https://learn.microsoft.com/azure/aks/auto-upgrade-node-os-image                                   | High       |
| 21  | Maintenance windows apply to both control plane and node pool upgrades                                                                           | module-08             | https://learn.microsoft.com/azure/aks/planned-maintenance                                          | High       |
| 22  | Azure Backup for AKS backs up Kubernetes resources and persistent volume snapshots                                                               | module-09             | https://learn.microsoft.com/azure/backup/azure-kubernetes-service-backup-overview                  | High       |
| 23  | Azure Policy for Kubernetes uses OPA/Gatekeeper as the admission controller                                                                      | module-10             | https://learn.microsoft.com/azure/governance/policy/concepts/policy-for-kubernetes                 | High       |
| 24  | `EnforcementMode: Default` blocks non-compliant resources at admission; `DoNotEnforce` only audits                                               | module-10, assessment | https://learn.microsoft.com/azure/governance/policy/concepts/assignment-structure                  | High       |
| 25  | Spot node pools receive `kubernetes.azure.com/scalesetpriority=spot:NoSchedule` taint automatically                                              | module-10             | https://learn.microsoft.com/azure/aks/spot-node-pool                                               | High       |
| 26  | `PodDisruptionBudget` controls minimum available replicas during node drain/upgrade                                                              | module-08, assessment | https://learn.microsoft.com/azure/aks/operator-best-practices-scheduler                            | High       |
| 27  | AKS Baseline Architecture recommends hub-spoke topology with Azure Firewall for egress control                                                   | module-02, lab-02     | https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks | High       |
| 28  | Private DNS zone `privatelink.azurecr.io` must be linked to the VNet for ACR private endpoint resolution                                         | module-03, lab-03     | https://learn.microsoft.com/azure/container-registry/container-registry-private-link               | High       |
| 29  | Key Vault `enableRbacAuthorization: true` should replace access policies for new deployments                                                     | module-04, lab-04     | https://learn.microsoft.com/azure/key-vault/general/rbac-guide                                     | High       |
| 30  | Key Vault Secrets User role ID = `4633458b-17de-408a-b874-0445c86b69e6`                                                                          | lab-04                | https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security                | High       |

---

## Claims Requiring Periodic Re-Verification

The following claims are correct at time of authoring but may change as Azure services evolve:

| #   | Claim                                                   | Risk of Change                               | Review Frequency |
| --- | ------------------------------------------------------- | -------------------------------------------- | ---------------- |
| 13  | `KubernetesManifest@1` task version and parameter names | Medium — task versions update periodically   | Quarterly        |
| 19  | Available `upgradeChannel` values for AKS auto-upgrade  | Low — stable API                             | Annually         |
| 30  | Key Vault Secrets User role definition ID               | Low — built-in role IDs are stable           | Annually         |
| 6   | ACR Premium required for private endpoints              | Low — SKU capabilities are rarely downgraded | Annually         |

---

## Unverified or Low-Confidence Claims

> The following claims are marked **Low** confidence. They are reasonable best-practice
> statements but were not verified against a specific learn.microsoft.com page during this authoring session.

| #    | Claim                                                                                        | Module            | Recommendation                                                                                                      |
| ---- | -------------------------------------------------------------------------------------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------- |
| L-01 | Application Gateway WAF OWASP 3.2 ruleset in `Prevention` mode is recommended for production | module-02, lab-02 | Verify against: https://learn.microsoft.com/azure/web-application-firewall/ag/application-gateway-waf-configuration |
| L-02 | Azure Bastion `Standard` SKU is required for native client (tunnel) support                  | module-02, lab-02 | Verify against: https://learn.microsoft.com/azure/bastion/bastion-overview                                          |
| L-03 | Spot VM eviction notice is 30 seconds via Azure Scheduled Events                             | module-10         | Verify against: https://learn.microsoft.com/azure/virtual-machines/scheduled-events                                 |

---

## Hallucination Risk Areas

The following areas are common sources of AI hallucination in Azure training content.
Each was explicitly verified before inclusion:

| Risk Area                                            | Verification Method                                                           | Result                                                  |
| ---------------------------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------- |
| AcrPull role GUID                                    | Confirmed via microsoft_docs_search for "AcrPull built-in role definition id" | Verified: `7f951dda-4ed3-4680-a7ca-43fe172d538d`        |
| Key Vault Secrets User role GUID                     | Confirmed via built-in roles documentation                                    | Verified: `4633458b-17de-408a-b874-0445c86b69e6`        |
| OIDC federated credential subject format             | Confirmed via Workload Identity deploy guide                                  | Verified: `system:serviceaccount:<namespace>:<sa-name>` |
| AGIC one-Gateway limitation                          | Confirmed via AGIC overview page                                              | Verified: one AGIC per Application Gateway              |
| `KubernetesManifest@1` ARM connection type parameter | Confirmed via task reference                                                  | Verified: `connectionType: azureResourceManager`        |
| Auto-upgrade `patch` channel behavior                | Confirmed via auto-upgrade channel docs                                       | Verified: patches within current minor only             |

---

*Trust report generated during training authoring session. Re-verify all High-risk claims if more than 6 months have elapsed since this date.*
