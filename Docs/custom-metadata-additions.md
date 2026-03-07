# Custom Metadata Additions

Custom Metadata Additions are solution-specific additions to DEVONthink's Custom Metadata Feature. They are used to show and enrich classification data. Through Additions, Custom Metadata can be linked to a Dimension to show the Category value, the values of other dimensions and other special fields. The output format of such (string-based) Custom Metadata field can be configured through simple template patterns.

When classification data is changed, the changes are taken over to Cutom Metadata fields as well - while preserving existing individual informations.

## Configuration

Custom Metadata behavior can be configured through AppleScript properties in the [database-independent functional configuration](configuration.md#Database-independent-functional-configuration). Configuration options are:

- **pCustomMetadataFields**: Ordered list of Custom Metadata field names to update with a category value or extracted fields form the document (amount or date). When a document amount is used, this must be the first entry. For example:

	```applescript
	property pCustomMetadataFields : {"Betrag", "Date", "Sender", "Subject"}
	```

- **pCustomMetadataDimensions**: Ordered list of dimension names per metadata field (same index as `pCustomMetadataFields`). For `DATE` fields, provide a 3-item list in `{year, month, day}` dimension order (usually `pDateDimensions`). For example:

	```applescript
	property pCustomMetadataDimensions : {"", pDateDimensions, "04 Sender", "05 Subject"}
	```

- **pCustomMetadataTypes**: Ordered list of field types (same index as `pCustomMetadataFields`). Supported values are `AMOUNT`, `DATE`, and `TEXT`. For example:

	```applescript
	property pCustomMetadataTypes : {"AMOUNT", "DATE", "TEXT", "TEXT"}
	```

- **pCustomMetadataTemplates**: Ordered list of templates (same index as `pCustomMetadataFields`) used for `TEXT` fields. Supported placeholders are:
	- `[Dimension Name]`: Replaced by the category name (when only one catagory value is allowed for dimension)
	- `[[Dimension Name]]`: Replace by all category names (when multiple category values are allowed).
	- `{Text}`: Individual / user text.
	- `{Amount}`: Document amount.

	For example:
	```applescript
	property pCustomMetadataTemplates : {"", "", "[04 Sender]{Text}", "[05 Subject]{Text}{Amount}[06 Context][[09 Marker]]"}
	```

- **pCustomMetadataFieldSeparator**: Separator between the category and th individual/user text. Default value is ": ". For example:

	```applescript
	property pCustomMetadataFieldSeparator : ": "
	```

- **pCommentsFields**: List of Custom Metadata field names that are copied into the record comments after metadata update. For example:

	```applescript
	property pCommentsFields : {"Sender", "Subject"}
	```

- **pAmountLookupCategories**: Space-separated list of categories that enable automatic amount lookup for `AMOUNT` fields when the amount field is empty. For example:

	```applescript
	property pAmountLookupCategories : "Receipt Invoice"
	```

**Note**: The properties pCustomMetadataFields, pCustomMetadataDimensions, pCustomMetadataTypes, pCustomMetadataTemplates are index-aligned.
