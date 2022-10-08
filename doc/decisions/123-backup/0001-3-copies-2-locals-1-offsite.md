---
parent: 123 Backup Decisions
nav_order: 1
---

# 3 copies 2 locals 1 offsite

## Context and Problem Statement

- At least 3 copies of data, which consists of 2 locals and 1 offsite.

- Both locals will use a separate Synology NAS, while the offsite will use OneDrive. Note that both locals and offsite are not used exclusively for backup.

- Each storage has different capacity, the smallest is OneDrive with 1 TB per account.

- Offsite storage must have encryption-at-rest and MFA.

## Feasible Alternatives

- Be wary of newer companies that have cheaper storage costs, but slower upload/download times, eg iDrive, Internxt.

## Decision Outcome

- Use OneDrive for offsite storage, and two Synology NAS for local.

### Minimise Backup Sprawl

- Use Synology client on each PC to backup files-at-rest to Synology NAS.

- Use Synology server to sync to other local Synology NAS.

- Use Synology cloud to sync to offsite.

## More Information

- [Markdown Any Decision Records](https://adr.github.io/madr/)

- [Upside Down Backups](https://ivymike.dev/upside-down-backups.html)