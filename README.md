# MailScripts

**TL;DR**

- Automates document and email workflows with DEVONthink and AppleScript.
	- Imports, classifies, renames, and archives records.
- Implements a multi-dimemsional, fully customizable, Tag-based classification system.
- Push and pull emails from Mail.app, takes over text with PopClip, connects with Contacts.app.
- Simple, easy to configure, to use and to adapt - behavior is controlled on database level.
- Start with `~/.mailscripts/config.scpt` and the user guide.

MailScripts is a collection of AppleScript scripts for recurring workflows in Mail.app and DEVONthink.

## Project Goal

The project reduces manual work in email and document processing. Standard tasks such as import, assignment, metadata updates, and archiving are handled through rules and scripts.

## Feature Scope

- Automatically import emails from Mail.app into DEVONthink with option for push and pull.
- Works best with .pdf for documents (for scanned or digital sources) and .eml for email.  
- Multi-dimensional [classification system](Docs/classification-system.md) to structure data as you need.
- Simple templating mechanism for [Custom Metadata](Docs/custom-metadata-enhancements.md) fields to enrich classification data with custom information and/or to show classification data in a condensed format.
- Simple templating mechanism for [file names and filing folders](Docs/name-and-file-documents.md), based on classification data.
- [Auto-classification](Docs/auto-classification.md) for date and other dimensions, with different options for source date.
- Auto-extraction of documente amounts for defined categories.
- Custom Metadata can be enriched directly though PopClip.
- Workflow can be run step-by-step (recommended for the beginning), partially automated (recommended for quality assurance) or fully automated.
- Classification data can be changed at any time - dependend fields reflects the changes.
- Optional contact/sender processing and smart-group creation.
- Database and content type specific [configurations](Docs/configuration.md) with reasonable defaults.

## Requirements

- macOS
- DEVONthink 4
- Mail.app (only needed when email import is requiered)

Support for:

- Contacts.app
- PopClip

## Quick Start

1. Clone the repository.
2. Copy `Configuration/config.scpt` to `~/.mailscripts/config.scpt` and set at least:
	- `pMailScriptsPath` to the MailScripts folder
4. Create a copy of `Configuration/Database-Template.scpt` and rename it according to your DEVONthink database to `Database-<DATABASE NAME>.scpt` 
	- check that `pConfigurationFile` is pointing to the proper configuration file (default configuration file is `Default-Configuration-Documents.scpt`)
6. Integrate required scripts as Mail Rules, DEVONthink menu scripts, or Smart Rules.

## Documentation

- Documents Quick Start: [Docs/A Quick Start Guide for Documents.md](Docs/A%20Quick%20Start%20Guide%20for%20Documents.md)
- Architecture Diagrams: [Docs/architecture-diagrams.md](Docs/architecture-diagrams.md)

## Notes

- Many `.scpt` files are compiled AppleScript files.
- Operational logic is located in the libraries under `Libs/`.
- Behavior changes are typically made through configuration scripts.
- `pClassificationDate` currently supports `DOCUMENT_CREATION_DATE`, `DATE_MODIFIED`, `DATE_CREATED`, and `RECORD_CREATION_DATE`.
