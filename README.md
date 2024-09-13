# MailScripts

The MailScripts project is a collection of Apple Scripts to integrate various MacOS applications with DEVONthink to support and automate my daily document and email management workflows.

## Overview

DEVONthink is my leading system for email and document management. For email each mail message is treated as document (or record) in DEVONthink. Apple's Mail.app is mostly used under the hood for receiving and for composing and sending emails (technically speaking I only work with Mail.app's message windows - I don't work with the viewer window). This sounds complicated and, of course, working with two apps is more complex than working with one, but, since DEVONthink offers so much featuture which makes me so much more efficient, Mail.app is not an option anymore.

![](Docs/architecture.drawio.svg)

## Methods & Workflows

Despite the fact that DEVONthink is my leading system, it is still only a tool. Just as important, if not more important, are the methodology and the workflows - how the tools is used. Regarding the methodology I use or practice Inbox-Zero along with the [PARA Method]. The workflow is this:

1. [Import Message](Docs/import-email-workflow.md) to:
	- import the email into DEVONthink (this creates a copy of the email) and
	- move the email to the proper inbox folder (based on the contact group where the sender is member of) and
	- move the original email from the Inbox to the archive folder in Mail.app
2. Verify correct Inbox to:
	- ensure the email is in the correct inpox folder and, if not,
	- move the email to the right inbox folder -> this will automatically update the contact group - the sender will be added to the contact group, so further emails from same sender will be moved directly to that inbox folder
3. Inbox Processing: 
	- tag the email with one specific tag for project, area or resource
		- this will be done based on best see-also/classiy records through a script with keyboard shortcut
	- process and optionally cross-reference the email in project work products 
	- Note: in general a email remains in the Inbox until:
		- it is done (answered, replied, whatever) or 
		- a task is created when it takes longer to finish it 
4. Archive Message:
	- move the email to the archive folder, which is: [archive root] / year / month
		- this will be done through a script with a keyboard shortcut

Usually the inbox processing ends here - when a mail is archived it is never touched again in terms of getting things done, except that a task exists for it. But, since I reference mail messages a lot I have unified my professional note taking system and my email system. This is were the PARA method comes into play. The workflow is this:

to be continued

[PARA Method]: https://fortelabs.com/blog/para/