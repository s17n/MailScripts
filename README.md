# MailScripts

**TL;DR**
- Automates email and document workflows with AppleScript.
- Connects Mail.app with DEVONthink (optional: Contacts/PopClip).
- Imports, classifies, renames, and archives records.
- Behavior is controlled via `Configuration/*.scpt`.
- Start with `~/.mailscripts/config.scpt` and the user guide.

MailScripts is a collection of AppleScript scripts for recurring workflows in Mail.app and DEVONthink.

## Project Goal

The project reduces manual work in email and document processing. Standard tasks such as import, assignment, metadata updates, and archiving are handled through rules and scripts.

## Feature Scope

- Import emails from Mail.app into DEVONthink
- Classify documents using tags/dimensions
- Set file names and custom metadata
- Move and archive records into defined target folders
- Optional contact/sender processing and smart-group creation

## Requirements

- macOS
- DEVONthink 4
- Mail.app
- Configuration file at `~/.mailscripts/config.scpt`

Optional:

- Contacts.app
- PopClip

## Quick Start

1. Clone the repository.
2. Copy `Configuration/config.scpt` to `~/.mailscripts/config.scpt`.
3. In `~/.mailscripts/config.scpt`, set at least `pMailScriptsPath` and `pPrimaryEmailDatabase`.
4. Adjust database configurations in `Configuration/` (`Database-Configuration-*.scpt`, `Default-Configuration-*.scpt`).
5. Integrate required scripts as Mail Rules, DEVONthink menu scripts, or Smart Rules.

## Documentation

- Documents Quick Start: [Docs/A Quick Start Guide for Documents.md](Docs/A%20Quick%20Start%20Guide%20for%20Documents.md)
- Architecture Diagrams: [Docs/architecture-diagrams.md](Docs/architecture-diagrams.md)

## Notes

- Many `.scpt` files are compiled AppleScript files.
- Operational logic is located in the libraries under `Libs/`.
- Behavior changes are typically made through configuration scripts.
