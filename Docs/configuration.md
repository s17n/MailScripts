# Configuration

The configuration is database specific and consists of two parts:

- a **database-specific** configuration which is used to connect a database to a database-independent functional configuration and
- a **database-independent** functional configuration which contains the actual configuration and can be used by multiple databases

## Database-specific configuration

The database-specific configuration sets the relation between your DEVONthink database and the database-independent functional configuration.  In order to do that you need to:

- Create a .scpt file in the Configuration folder for each database you want to use and set the name to the name of your DEVONthink database. To be precise, the name needs to be set in this format: `Database-[Name-of-your-Database].scpt`.
- In the database-specific .scpt file set the property **pConfigurationFile**  to the name of the functional configuration file you want to use. For example:

	```applescript
	property pConfigurationFile : "Default-Configuration-Documents.scpt"
	```

## Database-independent functional configuration

The functional configuration is database-independent and has to be configured through AppleScript properties in a .scpt file. The .scpt file can have an arbitrary name and is used to be referenced from database-specific configuration(s).  

The functional configuration consists of the following properties:

- **pContentType**: Content type switch for behavior and functional confíguration differences. Supported values are:
	- `DOCUMENTS`: Used for regular .pdf documents (scanned paper or digital documents) 
	- `EMAILS`: Used for email. Requires additional [email configuration](configuration-email.md) properties for mailbox access and email import. 
	- `ASSETS`: tbd

	For example:
	```applescript
	property pContentType : "DOCUMENTS"
	```

- **pLogLevel**: Log verbosity. Supported values are:
	- `0`: TRACE
	- `1`: DEBUG
	- `2`: INFO
	- `3`: ERROR

	For example:
	```applescript
	property pLogLevel : 2
	```
- **pUseWorker**: Global toggle for DEVONthink worker execution. Supported values are:
	- `true`: worker-enabled menu scripts and smart rules relaunch via `osascript ... --worker`
	- `false`: scripts run directly without worker relaunch

	For example:
	```applescript
	property pUseWorker : true
	```
- **Classification system** properties are documented [here](./classification-system.md#Configuration) and include: pDimensionsHome, pDimensionsConstraints, pDateDimensions, pCompareDimensions, pCompareDimensionsScoreThreshold, pClassificationDate, pTagAliases, pMonths
- **Custom Metadata** related properties are documented [here](custom-metadata-additions.md#Configuration) and include: pCustomMetadataFields, pCustomMetadataDimensions, pCustomMetadataTypes, pCustomMetadataTemplates, pCustomMetadataFieldSeparator, pCommentsFields, pAmountLookupCategories
- **File names and filing** related properties are documented [here](./name-and-file-documents.md#Configuration) and include: pNameTemplate, pFilesHome
