# DEVONthink Tag Filing by First Character

## Purpose

`Rule - Move by First Character` files a selected DEVONthink tag into an alphabet bucket below its current parent group.

Example:

- Selected tag: `Apple`
- Current parent group: `Senders`
- Result: the tag is moved to `Senders/A`

If the target child group does not exist yet, the script creates it first and then moves the tag into it.

Verified target state of the created bucket:

- It is created inside the existing Tags hierarchy.
- It is a normal DEVONthink group.
- `Exclude from Tagging` is set to `true`.
- It therefore acts as a non-tagging container for nested tags.

## Implementation Notes

The implementation lives in:

- `src/DEVONthink Smart Rules/Rule - Move by First Character.applescript`
- `src/Libs/DocLibrary.applescript`

The relevant handler is `moveByFirstCharacter(theRecords)` in `DocLibrary.applescript`.

## Why `tag type` Is Used

In DEVONthink scripting, `type of rec` is not sufficient to distinguish a normal group from a tag, because both can report as `group`.

For this rule, the selected record is expected to be a tag. The script therefore checks `tag type` first. This avoids treating the selected tag as a normal group and accidentally skipping it.

Source:

- DEVONtechnologies Community, “Distinguishing tags from (ordinary) groups in scripts”:
  [https://discourse.devontechnologies.com/t/distinguishing-tags-from-ordinary-groups-in-scripts/78789](https://discourse.devontechnologies.com/t/distinguishing-tags-from-ordinary-groups-in-scripts/78789)

## Why `location group` Is Used

For selected tags, parent/container relationships can be ambiguous or awkward to use in AppleScript. In practice, `location group` is the more reliable way to get the actual parent group the selected tag is currently filed in.

This rule therefore uses `location group` as the parent group reference and then searches or creates the alphabet child group below that group.

Source:

- DEVONtechnologies Community, “AppleScript: Parent of record returns tag, not the name of parent group”:
  [https://discourse.devontechnologies.com/t/applescript-parent-of-record-returns-tag-not-the-name-of-parent-group/73194](https://discourse.devontechnologies.com/t/applescript-parent-of-record-returns-tag-not-the-name-of-parent-group/73194)

## Group Creation Behavior

The helper handler `moveRecordToChildGroupNamed(theRecord, theParentGroup, theChildGroupName)` performs these steps:

1. Normalize the target child-group name to uppercase.
2. Search the children of the parent group for an existing group with the same normalized name.
3. Create the child group if none exists yet.
4. Ensure the destination group is excluded from tagging.
5. Move the selected tag into that child group.

This means no manual preparation of `A`, `B`, `C`, ... folders is required.

## Why `tag type` Is Not Set Explicitly

According to DEVONthink's scripting definition, `tag type` is a read-only property. The `create record with` command also documents its supported properties explicitly, and `tag type` is not among them.

That means the script cannot reliably set `tag type` either after creation or as part of `create record with`.

In addition, DEVONthink defines `group tag` as a group tag located outside of the Tags group, while `ordinary tag` is located inside the Tags group. For a container inside the Tags hierarchy, the relevant mechanism is `exclude from tagging`, not forcing `group tag`.

The script therefore creates the alphabet bucket as a normal group and sets `exclude from tagging` to `true`. This mirrors the UI action `Exclude from Tagging` and turns the node into a non-tagging container inside the Tags hierarchy.

This is the intended final structure for this rule. It does not try to force `group tag` inside `/Tags`, because that would conflict with DEVONthink's own tag-type model.

Source:

- DEVONthink scripting definition, `tag type` enumeration:
  `ordinary tag` = inside the Tags group, `group tag` = outside of the Tags group.
- DEVONthink scripting definition, `tag type` property:
  read-only (`access="r"`).
- DEVONthink scripting definition, `create record with`:
  supported properties do not include `tag type`, but do include exclusions such as `exclude from tagging`.
- DEVONthink scripting definition, `exclude from tagging` property:
  writable boolean property on groups.
- DEVONthink manual:
  `Exclude From… > Tagging` inhibits the tag from being applied to any item and is used with group tags and tag groups.
