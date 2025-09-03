# The Azure Resource Graph Kit (ARG-Kit)

[![PSGallery Preview Version](https://img.shields.io/powershellgallery/v/arg-kit.svg?style=flat&logo=powershell&label=Preview%20Version&include_prereleases)](https://www.powershellgallery.com/packages/arg-kit) 
[![PSGallery Release Version](https://img.shields.io/powershellgallery/v/arg-kit.svg?style=flat&logo=powershell&label=Release%20Version)](https://www.powershellgallery.com/packages/arg-kit) 
[![PSGallery Downloads](https://img.shields.io/powershellgallery/dt/arg-kit.svg?style=flat&logo=powershell&label=PSGallery%20Downloads)](https://www.powershellgallery.com/packages/arg-kit)

PowerShell module to simplify working with **Azure Resource Graph (ARG)**. The kit includes a curated set of queries and an **interactive dashboard** for quickly assessing the health, security, compliance, and cost posture of your Azure environment.

---

## ✨ Features

- Run curated **health checks** against your environment with one command
- Interactive **HTML dashboard** with drill-down into issues (in development)
- Export results to **JSON** or **Console output**
- Includes ARG queries for:
  - Orphaned resources (disks, NICs, NSGs, public IPs, app service plans, load balancers)
  - Security checks (public access Key Vaults and storage accounts, HTTPS enforcement, Defender for Cloud)
  - Patching status (Windows, Linux, pending updates)
  - Compliance (per resource type, per policy assignment, all non-compliant resources)
  - Deprecations (Basic SKU IP addresses, legacy TLS on SQL/Storage)
  - Monitoring (alerts, service health)
  - Cost optimization (hybrid benefit usage, savings overview)

---

## 🚀 Getting Started

### Prerequisites
- Reader or higher role in the target subscriptions

### Installation

```powershell
Install-Module -Name ARG-Kit -Scope CurrentUser
