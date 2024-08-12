# MailScripts

The MailScripts project is a collection of scripts used to connect various MacOS applications with DEVONthink to automate daily document and email workflows.

## Overview
![](Docs/architecture.drawio.svg)

## Workflows


```mermaid
flowchart LR
    I[Import Message]-->P[Inbox Processing]
    P-->A[Archive Message]
    click I "Docs/import-email-workflow.md" _blank
    click B "https://www.github.com" "Open this in a new tab" _blank
    click A href "https://www.github.com" _blank

```

[Import Email Workflow](Docs/import-email-workflow.md)
