# Import Email Workflow

Emails can be imported into DEVONthink via push or pull mechanism from Apple Mail.app. The push import is trigged by a rule in Apple Mail.app - the pull import can requested from DEVONthink. Usually push import works fine, but sometimes, e.g. when reading emails first on mobile, the mail rules doesn't fire anymore, so they can be imported via pull. 

The following chart shows how the push import works:

```mermaid 

sequenceDiagram
    Mail.app->>Mail Rule: perform mail action
	Mail Rule->>Mail Rule: init MailScript properties
	Note right of Mail Rule: dtImportDatabase <br/> dtImportFolder <br/> dtSortBySender <br/> mailboxAccount <br/> mailboxArchiveFolder
	Mail Rule->>MailLib: add message to DEVONthink
	MailLib->>Mail.app: extract address from
	Mail.app-->>MailLib: address
	MailLib->>MailLib: getContactGroupName
	MailLib->>Contacts: first persons with same emails address
	Contacts-->>MailLib: persons with groups
	MailLib->>DEVONthink: create record with [message properties]
	MailLib->>DEVONthink: perform smart rule [trigger import event]
	MailLib->>DEVONthink: create location [import folder]
	MailLib->>DEVONthink: move record to [import folder]
	MailLib->>Mail.app: set mailbox of [message] to [archive folder]
	
	MailLib-->>Mail Rule: return
	Mail Rule-->>Mail.app: return
	
```