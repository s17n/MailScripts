# Classification system

The classification system is built on top of DEVONthink's Tags feature. It uses:

- Top-level Tag Groups to implement dimensions and
- Tags within these top-level tag groups to implement dimension values.

You can think of a dimension as a viewing angle or perspective on all of your documents. A dimension value is the concrete tag value within that perspective that marks a document.

For example, for personal documents you could have a classification system with:

- a dimension Sender with the names of document senders as dimension values
- a dimension Subject with dimension values like Invoice, Contract, or Payslip
- a dimension Year, Month and Day to represent the document date

You can have as many dimensions and dimension values as you want.

Besides the usual usage scenarios where tags are helpful, classification system tags can do something more:

- Dimensions can be linked to Custom Metadata fields to show the dimension value and other dimensions' values in a well-defined, condensed format, along with the option to add document-specific individual information.
- Dimensions and dimension values can be used to name and file documents consistently.

Classification tags are the leading source of truth across the solution. When a tag changes, Custom Metadata fields, document names, and filing folders follow automatically (triggered by Smart Rules) or manually (for example by keyboard shortcut).

## Auto-classification

Auto-classification assigns classification tags to a record through scripting. It can be triggered by a Smart Rule, a menu bar script, or a stand-alone AppleScript.

Based on the configuration, date dimension values and other dimension values are determined and assigned automatically:

- Date values are derived from the record itself, based on `pClassificationDate`.
- Non-date values are copied from the most similar record found by DEVONthink's compare feature.
- `pCompareDimensionsScoreThreshold` prevents copying values when the compare score is below the configured threshold.


## Configuration

The classification system can be configured through AppleScript properties in the [database-independent functional configuration](configuration.md#Database-independent-functional-configuration). Configuration options are:

- **pDimensionsHome**: Root tag group that contains the top-level tag groups used as dimensions. Default is `/Tags`. For example:

	```applescript
	property pDimensionsHome : "/Tags"
	```

- **pDimensionsConstraints**: Optional cardinality constraints for verification. Each entry is `{dimensionName, expectedDimensionValueCount}`.
  A value greater than `0` means the record must contain exactly that number of dimension values for the dimension (for example `"1"` means exactly one value).
  Violations are logged by **Verify Records** and affected records are marked with label `7`. For example:

	```applescript
	property pDimensionsConstraints : {{"01 Day", "1"}, {"02 Month", "1"}, {"03 Year", "1"}}
	```

- **pDateDimensions**: Dimensions used to represent the document date. This must be a list of dimension names in fixed order: year, month, day. For example:

	```applescript
	property pDateDimensions : {"03 Year", "02 Month", "01 Day"}
	```

- **pCompareDimensions**: List of dimensions whose values can be copied from similar records during auto-classification. For example:

	```applescript
	property pCompareDimensions : {"04 Sender", "05 Subject", "06 Context"}
	```

- **pCompareDimensionsScoreThreshold**: Minimum compare score required before dimension values are copied during auto-classification. For example:

	```applescript
	property pCompareDimensionsScoreThreshold : 0.25
	```

- **pClassificationDate**: Date source used for auto-classification and optional archive path date placeholders. Leave empty ("") to disable date-based auto-classification. Supported values are:
	- `DOCUMENT_CREATION_DATE`
	- `DATE_MODIFIED`
	- `DATE_CREATED`
	- `RECORD_CREATION_DATE`

	```applescript
	property pClassificationDate : "DOCUMENT_CREATION_DATE"
	```

- **pTagAliases**: Optional list of `{tag, alias}` mappings used in generated metadata text output (for example in custom metadata templates) to replace long tag labels with short forms. For example:

	```applescript
	property pTagAliases : {{"analog", "A"}, {"digital", "D"}}
	```

- **pMonths**: List of `{monthNumber, monthName}` pairs used to map between numeric months (`"01"`-`"12"`) and month dimension values. This mapping is used when writing date tags and when replacing dimension placeholders. For example:

	```applescript
	property pMonths : {{"01", "Januar"}, {"02", "Februar"}, {"03", "März"}, {"04", "April"}, {"05", "Mai"}, {"06", "Juni"}, {"07", "Juli"}, {"08", "August"}, {"09", "September"}, {"10", "Oktober"}, {"11", "November"}, {"12", "Dezember"}}
	```
