# Import Email Workflow

Emails can be imported into DEVONthink via push or pull mechanism from Apple Mail.app. The push import is trigged by a rule in Apple Mail.app - the pull import can requested from DEVONthink. Usually push import works fine, but sometimes, e.g. when reading emails first on mobile, the mail rules doesn't fire anymore, so they can be imported via pull. 

The following chart shows how the push import works:

<script>
let config = {theme: 'forest',
'themeVariables': {
      'primaryColor': "#ffcccc",
      'secondaryColor': "#fff0cc",
      'tertiaryColor': "#fff0f0" }
};
let config2 = {'sequence': {'noteAlign': 'left', 'boxBorderWith':'100'}} 
mermaid.initialize(config2)
</script>

```mermaid 
sequenceDiagram
	participant M as Mail.app
	box sand MailScripts
	    participant MR as Mail Rule
    		participant ML as MailLib 
	end
	participant C as Contacts.app
    participant D as DEVONthink.app
	
	M->>+MR: perform mail action
	MR->>MR: init MailScript properties
	Note right of MR: dtImportDatabase <br/> dtImportFolder <br/> dtSortBySender <br/> mailboxAccount <br/> mailboxArchiveFolder
	MR->>+ML: add message to DEVONthink
	ML->>+M: extract address from
	M-->>-ML: address
	ML->>ML: getContactGroupName
	ML->>C: first persons with same emails address
	C-->>ML: persons with groups
	ML->>D: create record with [message properties]
	ML->>D: perform smart rule [trigger import event]
	ML->>D: create location [import folder]
	ML->>D: move record to [import folder]
	ML->>M: set mailbox of [message] to [archive folder] of [mailbox account]
	ML-->>-MR: return
	MR-->>-M: return
	
```