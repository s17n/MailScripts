# Email Configuration

This page documents properties from `Default-Configuration-Emails.scpt` and how they are used by the current implementation.

## Configuration

The email configuration can be configured through AppleScripts properties in the [database-independent functional configuration](configuration.md#Database-independent-functional-configuration). Configuration options are:

- **pContentType**: Content type identifier for this configuration. Use `EMAILS`. For example:

	```applescript
	property pContentType : "EMAILS"
	```

- **pMailboxAccount**: Apple Mail account name used to access inbox and archive mailboxes. For example:

	```applescript
	property pMailboxAccount : "Google"
	```

- **pMailboxImportFolder**: Apple Mail mailbox folder name from which messages are imported. For example:

	```applescript
	property pMailboxImportFolder : "INBOX"
	```

- **pMailboxArchiveFolder**: Apple Mail mailbox folder name where imported messages are moved. For example:

	```applescript
	property pMailboxArchiveFolder : "Archiv"
	```

- **pDtImportFolder_1**: Target DEVONthink folder path used by `MailLibrary` for imported messages. For example:

	```applescript
	property pDtImportFolder_1 : ""
	```

- **pDtArchiveRoot**: Archive root path used by `Rule - Archive Records` via global `config.scpt`. For example:

	```applescript
	property pDtArchiveRoot : ""
	```

- **pDelayBeforeImport**: Delay in seconds before import starts. For example:

	```applescript
	property pDelayBeforeImport : 5
	```

- **pLogLevel**: Log verbosity. Supported values are `0` (TRACE), `1` (DEBUG), `2` (INFO), and `3` (ERROR). For example:

	```applescript
	property pLogLevel : 2
	```

- **pLogFilePath**: Optional file log path for this functional configuration. Leave empty (`""`) to use the bootstrap/fallback path from `~/.mailscripts/config.scpt`. For example:

	```applescript
	property pLogFilePath : "~/Library/Logs/MailScripts/emails.log"
	```

## Implementation Notes

- `pDtArchiveRoot` is read by `Rule - Archive Records` from global `config.scpt`. If it is only set in `Default-Configuration-Emails.scpt`, it will not be picked up by that rule.
