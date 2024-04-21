# Document Worklow


**Capture (Scan & Import into DEVEONthink)**

For regular-size paper documents (letter format):
- scanned with ScanSnap directly into DEVONthink global inbox.
- timestamp of the scan used as filename (yyyy-MM-dd-HH-mm-ss.pdf) 

For non-regular-sized paper documents (non-letter format - mostly receipts):
- scanned with Prizmo on iPhone (b/w)
    - includes OCR, basic adjustments (contrast ratio, borders etc.), auto-export PDF on iCloud
    - scans usually include multiple pages (one page per document/receipt)
    - filename includes 'tags' for target database and wether to split pages  
- iCloud sync of the PDF to the Mac
    - Hazel rule - split pages (optional)
- Import into DEVONthink target database or global inbox

**Analyze & Enrich**

Determine target database (when not defined) and move document to it.
- DEVONthink smart rule in Global Inbox to:
    - scan content for trigger words - move to target database's Inbox 

Identify document date - from the content not from the metadata.
- DEVONthink smart rule in target database Inbox to:
    - determine document date (DT: "Sortable Newest Document Date")
    - rename document to document date (when found) - new filename: yyyy-MM-dd.pdf

Add tags & custom meta data and rename document
- DEVONthink 'compare record' feature to select the most similar document from target database (by score with threshold)
- set non-date tags from most similar document (copy/paste)). Each document usually has theses tags:
    - date tags: day, month, year
    - non-date tags: sender, subject, context (optional)
    - individual tags
- set date tags from filename 
- set custom meta data to initial values based on tags: Date, Sender, Subject
- rename document by tags - new filename yyyy-MM-dd_[sender]_[subject].pdf

**Verify & Modify**

Note: Up until here the workflow is fully automated (except feeding ScanSnap / capture with iPhone) - showing a new document in appropriate database's Inbox with the standardized filename [Document Date]\_[Sender]\_[Subject].pdf

Verify analyze/classification results (proper date, sender, suject) and adjust when not.
- All adjustmens are done based on the tags.
- DEVONthink Menu Action (with keyboard shortcut) is used to rename the document and to update custom meta data. 

Manually add custom meta data with text fragments from the document - mostly for 'subject' (documents) and 'amout' (receipts).
- PopClip is used to add selected text from the document to the subject 

**Archive (when everything's done)**

When everything is done, the document is moved to archive folder.

- DEVONthink Menu Action (with keyboard shortcut) is used to move the document to archive folder: /[Year Group]/[Year]/[Month] (year groups are used for decades, e.g. "2010-2019")