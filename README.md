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
- Simple templating mechanism for [Custom Metadata](Docs/custom-metadata-additions.md) fields to enrich classification data with custom information and/or to show classification data in a condensed format.
- Simple templating mechanism for [file names and filing folders](Docs/name-and-file-documents.md), based on classification data.
- [Auto-classification](Docs/classification-system.md#auto-classification) for date and other dimensions, with different options for source date.
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

1. Clone the repository (Prereq: [osagitfilter](https://github.com/doekman/osagitfilter))
2. Copy [Configuration/config.scpt](Configuration/config.scpt) to `~/.mailscripts/config.scpt` and
	- set `pMailScriptsPath` to your local MailScripts folder
4. Create a [configuration](Docs/configuration.md) for the DEVONthink database you want to use.
6. Setup your workflow
	- Copy or alias [DEVONthink Menu](DEVONthink%20Menu) scripts and [DEVONthink Smart Rules](DEVONthink%20Smart%20Rules) to DEVONthink's scripts folders
	- Copy [Mail Rules](Mail%20Rules) to Mail.app's scripts folder
	- Install [PopClip](PopClip) extentsion

## Documentation

- Quick Start Guide for Documents: [Docs/A Quick Start Guide for Documents.md](Docs/A%20Quick%20Start%20Guide%20for%20Documents.md)

## Notes

- Many `.scpt` files are compiled AppleScript files.
- Operational logic is located in the libraries under `Libs/`.
- Behavior changes are typically made through configuration scripts.
- `pClassificationDate` currently supports `DOCUMENT_CREATION_DATE`, `DATE_MODIFIED`, `DATE_CREATED`, and `RECORD_CREATION_DATE`.
