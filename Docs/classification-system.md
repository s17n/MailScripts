# Classification system

The classification system is build on top of DEVONthink's Tags feature. It uses:

- Tag Groups to implement Dimensions and
- Tags within the tag groups to implement Categories.

You can think of a Dimension like a viewing angle or perspective to all of your documents and you can think of a Category like a criterion - specific for a single persepective - to mark (tag) a document.

For example, for personal documents you could have a classification system with:

- a dimension Sender with the names of the sender of a document as categories 
- a dimension Subject with categories like Invoice, Contract or Payslip
- a dimension Year, Month and Day to represent the document date

You can have as much dimensions and categories as you want.

Besides the usual usage scenarios where tags are helpful, classification system tags can do a more:

- Dimensions can be linked to Custom Metadata fields to show the category and other dimension's categories in a well-defined, condensed format, along with the option to add document specific individual information.
- Dimensions and categories can be used to name and file documents consistently.

Even though classification data spans over to other parts of the solution it's important to know that classification system tags are leading. When a tag is changed Custom Metadata fields, document name and location in the file system will follow - automatically (trigged by Smart Rule) or manually (e.g. trigged by a keyboard shortcut).

## Configuration

The classification system can be configured through AppleScripts properties in the [database-independent functional configuration](configuration.md#Database-independent-functional-configuration). Configuration options are:

- **pDimensionsHome**: Root group for Dimensions tag groups. Default is /Tags. For examle:

	```applescript
	property pDimensionsHome : "/Tags"
	```

- **pDimensionsConstraints**: Optional. Currently used to check cardinality. For examle:

	```applescript
	property pDimensionsConstraints : {{"01 Day", "1"}, {"02 Month", "1"}, {"03 Year", "1"}}	```

- **pDateDimensions**: When document date is mapped to dimensions, this is where you specify which dimension is year, month and day. This must be specified as list of strings with the names of the corresponding dimensions / tag group names. The seqence matters: first item must be the year, second item the month, third item the day. For examle:

	```applescript
	property pDateDimensions : {"03 Year", "02 Month", "01 Day"} 	```

- **pCompareDimensions**: Name of the dimensions as list of strings which are taken over in auto-classification. For examle:

	```applescript
	property pCompareDimensions : {"04 Sender", "05 Subject", "06 Context"}	```

- **pCompareDimensionsScoreThreshold**: Threshold for taking over tags in auto-classification. If compare record has lower score, tags are not taken over. For examle:

	```applescript
	property pCompareDimensionsScoreThreshold : 0.25	```

- **pClassificationDate**: Date source used for auto-classification and optional archive path date placeholders. Leave empty ("") to disable date-based auto-classification. Supported values are:
	- `DOCUMENT_CREATION_DATE`:
	- `DATE_MODIFIED`:
	- `DATE_CREATED`:
	- `RECORD_CREATION_DATE`. 

	```applescript
	property pClassificationDate : "DOCUMENT_CREATION_DATE"
	```

- **pTagAliases**: Optional list of `{tag, alias}` mappings used in generated metadata text output (for example in custom metadata templates) to replace long tag labels with short forms. For examle:

	```applescript
	property pTagAliases : {{"analog", "A"}, {"digital", "D"}}	```

- **pMonths**: List of `{monthNumber, monthName}` pairs used to map between numeric months (`"01"`-`"12"`) and month tags. This mapping is used when writing date tags and when replacing dimension placeholders. For examle:

	```applescript
	property pMonths : {{"01", "Januar"}, {"02", "Februar"}, {"03", "März"}, {"04", "April"}, {"05", "Mai"}, {"06", "Juni"}, {"07", "Juli"}, {"08", "August"}, {"09", "September"}, {"10", "Oktober"}, {"11", "November"}, {"12", "Dezember"}}	```
