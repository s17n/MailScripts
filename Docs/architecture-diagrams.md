# Architecture Diagrams

This document contains four practical views of the MailScripts architecture:

1. System context
2. Container view
3. Email import sequence
4. Document processing sequence

## 1) System Context

```mermaid
C4Context
    title MailScripts - C4 System Context

    Person(user, "User", "Runs document and email workflows.")

    System(mailScripts, "MailScripts", "AppleScript automation system. Main entry points are DEVONthink Scripts and Smart Rules.")
    System_Ext(devonthink, "DEVONthink", "Primary workspace for records, tags, metadata, and rules.")
    System_Ext(mailApp, "Mail.app", "Email source and archive target.")
    System_Ext(contacts, "Contacts.app", "Optional contact/group resolution.")
    System_Ext(popclip, "PopClip", "Optional metadata enrichment shortcut.")
    System_Ext(config, "~/.mailscripts/config.scpt", "Runtime configuration for paths and defaults.")

    Rel_L(user, mailScripts, "Triggers workflows")
    Rel_D(mailScripts, devonthink, "Reads/updates records, tags, metadata")
    Rel_D(mailScripts, mailApp, "Imports emails, archives originals")
    Rel_D(mailScripts, contacts, "Reads/updates contact groups (optional)")
    Rel_D(popclip, mailScripts, "Triggers helper actions (optional)")
    Rel_L(mailScripts, config, "Loads runtime configuration")
```

## 2) Container View

```mermaid
C4Container
    title MailScripts - C4 Container View

    Person(user, "User", "Runs workflows in DEVONthink and Mail.app.")
    System_Ext(devonthink, "DEVONthink", "Main workspace for records, tags, metadata, rules.")
    System_Ext(mailApp, "Mail.app", "Email source and archive target.")
    System_Ext(contacts, "Contacts.app", "Optional contact/group management.")
    System_Ext(popclip, "PopClip", "Optional text-action trigger.")

    System_Boundary(ms, "MailScripts") {
        Container(dtscripts, "DEVONthink Scripts Menu", "AppleScript", "Menu scripts triggered by user actions in DEVONthink.")
        Container(smartRules, "Smart Rules", "AppleScript", "Event-driven scripts triggered by DEVONthink rules.")
        Container(mailRules, "Mail Rules", "AppleScript", "Event-driven scripts triggered by Mail.app rules.")
        Container(libs, "Libraries (Libs/*.scpt)", "AppleScript", "Core workflow logic: DocLibrary, MailLibrary, BaseLibrary, Logger, PopClipLibrary.")
        Container(config, "Configuration", "AppleScript config files", "Runtime and database-specific settings.")
    }

    Rel_U(user, dtscripts, "Runs manually")
    Rel_U(devonthink, smartRules, "Triggers")
    Rel_U(mailApp, mailRules, "Triggers")
    Rel_D(dtscripts, libs, "Calls")
    Rel_D(smartRules, libs, "Calls")
    Rel_D(mailRules, libs, "Calls")
    Rel_D(libs, config, "Loads settings from")
    Rel(libs, devonthink, "Reads/updates records and metadata")
    Rel(libs, mailApp, "Reads messages, moves originals to archive")
    Rel(libs, contacts, "Reads/updates contact groups (optional)")
    Rel(popclip, dtscripts, "Triggers helper actions (optional)")
```

## 3) Sequence: Email Import

```mermaid
sequenceDiagram
    participant U as User
    participant MA as Mail.app
    participant MR as Mail Rule
    participant DL as DocLibrary
    participant ML as MailLibrary
    participant DT as DEVONthink
    participant CO as Contacts.app

    MA->>MR: New mail triggers rule
    MR->>DL: importMailMessages(database)
    DL->>ML: initialize + getInboxMessages()
    ML->>MA: Read messages from configured mailbox
    ML->>DT: Create .eml record in target database/folder
    ML->>DT: Set custom attributes and metadata
    ML->>CO: Resolve/update contact group (optional)
    ML->>MA: Mark as read and move original to archive mailbox
    ML-->>DL: Return import result
    DL-->>U: Processing completed (logs available)
```

## 4) Sequence: Document Processing

```mermaid
sequenceDiagram
    participant U as User
    participant DT as DEVONthink
    participant MS as Menu Script / Smart Rule
    participant DL as DocLibrary
    participant CF as Configuration

    U->>DT: Select/import document(s)
    DT->>MS: Trigger script (menu or smart rule)
    MS->>DL: processDocuments(records)
    DL->>CF: Load database/default configuration
    DL->>DT: Classify records (tags/dimensions)
    DL->>DT: Set name + custom metadata
    DL->>DT: Optional verification
    DL->>DT: Move to archive/files target
    DL-->>MS: Return status
    MS-->>U: Processing completed (logs available)
```
