# CLAUDE.md

## Critical Rules

### NEVER HANDLE RAW XML ELEMENTS
You MUST NOT handle raw XML elements (such as those from Nokogiri) in HTML processing code. Any violation will be considered a serious error.

**Rule:** All HTML generation must go through the Docbook model classes only. If the Docbook models are insufficient, they MUST be improved to support the required functionality.

**Why:** Handling raw XML bypasses the abstraction layer and creates brittle, non-portable code that doesn't work with the established model infrastructure.

**How to apply:** When processing XML content for HTML output, always use the Lutaml::Model-based Docbook element classes (in `lib/docbook/elements/`). If an element type is not supported in the models, add it to the appropriate element class rather than processing raw XML nodes.

### Examples
- **WRONG:** `node.xpath('...')` or `Nokogiri::XML::Node` manipulation in HTML generation
- **RIGHT:** Use element classes like `Docbook::Elements::InformalFigure`, `Docbook::Elements::MediaObject`, etc.

### Image Path Resolution
Image paths should be resolved using the Docbook element's xml:base when available, per the Docbook spec. The `process_image` method in Html class handles this by searching parent paths as a fallback when xml:base is not preserved by the parser.