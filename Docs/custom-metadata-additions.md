# Custom Metadata Additions

Custom Metadata Additions are solution-specific additions to DEVONthink's Custom Metadata feature. They show and enrich classification data. A Custom Metadata field can be linked to a dimension to show its dimension value, values from other dimensions, and other special fields. String-based Custom Metadata fields can be configured through simple template patterns.

When classification data changes, Custom Metadata fields are updated as well, while existing individual text is preserved.

## Configuration

Custom Metadata behavior can be configured through AppleScript properties in the [database-independent functional configuration](configuration.md#Database-independent-functional-configuration). Configuration options are:

- **pCustomMetadataFields**: Ordered list of Custom Metadata field names to update with a dimension value or extracted fields from the document (amount or date). When a document amount is used, this must be the first entry. For example:

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
	- `[Dimension Name]`: Replaced by the dimension value (when only one dimension value is allowed for the dimension).
	- `[[Dimension Name]]`: Replaced by all dimension values (when multiple dimension values are allowed).
	- `{Text}`: Individual / user text.
	- `{Amount}`: Document amount.

	For example:
	```applescript
	property pCustomMetadataTemplates : {"", "", "[04 Sender]{Text}", "[05 Subject]{Text}{Amount}[06 Context][[09 Marker]]"}
	```

- **pCustomMetadataFieldSeparator**: Separator between the dimension value and the individual/user text. Default value is ": ". For example:

	```applescript
	property pCustomMetadataFieldSeparator : ": "
	```

- **pCommentsFields**: List of Custom Metadata field names that are copied into the record comments after metadata update. For example:

	```applescript
	property pCommentsFields : {"Sender", "Subject"}
	```

- **pAmountLookupDimensionValues**: Space-separated list of dimension values that enable automatic amount lookup for `AMOUNT` fields when the amount field is empty. Because the value is split into words, configured dimension values should not contain spaces. For example:

	```applescript
	property pAmountLookupDimensionValues : "Receipt Invoice"
	```

	Existing configurations using `pAmountLookupCategories` are still accepted as a backward-compatible alias.

**Note**: The properties pCustomMetadataFields, pCustomMetadataDimensions, pCustomMetadataTypes, pCustomMetadataTemplates are index-aligned.
