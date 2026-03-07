# File names and filing folders

File names and filing folder structure are considered to follow the classification system. Therefore they can be defined through simple templating patterns with dimension placeholders.

The file name is set when record's metadata are updated through `Update Records Metadata`.

The filing folder structure is used when a record is archived through `Archive Records`. 

## Configuration

Naming and filing can be configured through AppleScript properties in the [database-independent functional configuration](configuration.md#Database-independent-functional-configuration). Configuration options are:

- **pNameTemplate**: Template used to rename records during metadata updates. Supports dimension placeholders like `[03 Year]`, `[04 Sender]`, and `[05 Subject]`. Leave empty (`""`) to disable automatic renaming. For example:

	```applescript
	property pNameTemplate : "[03 Year]-[02 Month]-[01 Day]_[04 Sender]_[05 Subject]"
	```

- **pFilesHome**: Destination template used when archiving records. Supports dimension placeholders (`[Dimension]`), `{Decades}`, and optional date placeholders `{Year}`, `{Month}`, `{Day}` (the date placeholders are primarily relevant when date dimensions are not configured and a classification date is available). For example:

	```applescript
	property pFilesHome : "/05 Files/{Decades}[03 Year]/[02 Month]"
	```

