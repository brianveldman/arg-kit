# The Azure Resource Graph Kit
[![PSGallery Preview Version](https://img.shields.io/powershellgallery/v/arg-kit.svg?style=flat&logo=powershell&label=Preview%20Version&include_prereleases)](https://www.powershellgallery.com/packages/arg-kit) [![PSGallery Release Version](https://img.shields.io/powershellgallery/v/arg-kit.svg?style=flat&logo=powershell&label=Release%20Version)](https://www.powershellgallery.com/packages/arg-kit) [![PSGallery Downloads](https://img.shields.io/powershellgallery/dt/arg-kit.svg?style=flat&logo=powershell&label=PSGallery%20Downloads)](https://www.powershellgallery.com/packages/arg-kit)

PowerShell module for handling Azure Resource Graph queries in Microsoft Azure.  
Includes a curated collection of queries for:

- **Orphaned resources**  
  Disks, network interface cards, network security groups, and public IP addresses

- **Security**  
  Public access on Key Vaults and storage accounts

- **Patching**  
  Current update status for Windows and Linux, plus all pending updates

- **Compliance**  
  Compliance by resource type, compliance by policy assignment, and all non-compliant resources

- **Deprecations**  
  Basic public IP addresses and older TLS versions on storage accounts

## Getting Started

### Installation

```powershell
Install-Module -Name ARG-Kit
```
