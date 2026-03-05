# Custom Metadata Enhancements

Custom Metadata enhancements combine classification tags with structured DEVONthink fields. They are used to:

- derive metadata values from dimensions and categories
- keep metadata consistent with tags after updates
- optionally append user-defined free text to generated values
- copy selected metadata values into record comments

## Configuration

Custom Metadata behavior can be configured through AppleScript properties in the [database-independent functional configuration](configuration.md#Database-independent-functional-configuration). Configuration options are:

- **pCustomMetadataFields**: Ordered list of DEVONthink Custom Metadata field names to update. This list is index-aligned with `pCustomMetadataDimensions`, `pCustomMetadataTypes`, and `pCustomMetadataTemplates`. The first entry is treated as the amount field reference. For example:

	```applescript
	property pCustomMetadataFields : {"Betrag", "Date", "Sender", "Subject"}
	```

- **pCustomMetadataDimensions**: Ordered mapping of dimensions per metadata field (same index as `pCustomMetadataFields`). For `DATE` fields, provide a 3-item list in `{year, month, day}` dimension order (usually `pDateDimensions`). For example:

	```applescript
	property pCustomMetadataDimensions : {"", pDateDimensions, "04 Sender", "05 Subject"}
	```

- **pCustomMetadataTypes**: Ordered list of field types (same index as `pCustomMetadataFields`). Supported values are `AMOUNT`, `DATE`, and `TEXT`. For example:

	```applescript
	property pCustomMetadataTypes : {"AMOUNT", "DATE", "TEXT", "TEXT"}
	```

- **pCustomMetadataTemplates**: Ordered list of templates (same index as `pCustomMetadataFields`), mainly used for `TEXT` fields. Supported placeholders are `[Dimension]`, `[[Dimension]]`, `{Text}`, and `{Amount}`. For example:

	```applescript
	property pCustomMetadataTemplates : {"", "", "[04 Sender]{Text}", "[05 Subject]{Text}{Amount}[06 Context][[09 Marker]]"}
	```

- **pCustomMetadataFieldSeparator**: Separator between generated text and user-provided custom text for `TEXT` fields (for example `": "`). For example:

	```applescript
	property pCustomMetadataFieldSeparator : ": "
	```

- **pCommentsFields**: List of Custom Metadata field names that are copied into the record comments after metadata update. For example:

	```applescript
	property pCommentsFields : {"Sender", "Subject"}
	```

- **pAmountLookupCategories**: Space-separated list of categories that enable automatic amount lookup for `AMOUNT` fields when the amount field is empty. For example:

	```applescript
	property pAmountLookupCategories : "Beleg Rechnung Quittung Kostenbescheid"
	```

