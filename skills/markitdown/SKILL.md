---
name: markitdown
description: Convert files to Markdown with Microsoft MarkItDown (PDF, Word, Excel, PowerPoint, images, audio, HTML, CSV/JSON/XML, ZIP, EPub, YouTube URLs) for LLM consumption, note-taking and indexing. Use when a document needs to become Markdown — e.g. feeding a Second Brain inbox, preparing files for search/indexing, or extracting readable text from Office/PDF files — instead of writing a one-off parser.
---

# MarkItDown — convert files to Markdown

Wrapper skill for Microsoft's [MarkItDown](https://github.com/microsoft/markitdown) (MIT, Python). The tool is **not** vendored in this repo; this skill tells the agent how and when to use it. Output is Markdown meant for LLMs and text pipelines — good structure (headings, lists, tables, links), not high-fidelity layout for human reading.

## Install (once per machine)

Python 3.10+ required. Prefer a venv; install only the formats you need, or all:

```sh
pip install 'markitdown[all]'          # everything
pip install 'markitdown[pdf,docx,xlsx,pptx]'   # leaner: common documents
```

Verify: `markitdown --help` runs, or `python3 -c "from markitdown import MarkItDown"`.

## Use

```sh
markitdown path/to/file.pdf -o output.md      # to a file
markitdown path/to/file.docx > output.md      # or stdout
cat file.pdf | markitdown                      # stdin works too
```

Python API for pipelines:

```python
from markitdown import MarkItDown
md = MarkItDown()
result = md.convert("report.xlsx")
print(result.markdown)
```

Supported inputs: PDF, PowerPoint, Word, Excel (incl. legacy .xls), images (EXIF + optional LLM captioning), audio (EXIF + optional transcription), HTML, CSV/JSON/XML and other text formats, ZIP (iterates contents), EPub, YouTube URLs. Image captioning and audio transcription need a web-hosted service / LLM client — without one those parts are skipped, everything else is local and offline.

## Rules

1. **Default converter for "file → Markdown" tasks.** Reach for this before writing a bespoke parser for a PDF/Office document.
2. **Not for precision extraction.** For financial statements, prospectuses or any table whose numbers must be exact, MarkItDown is a first pass only — verify figures against a dedicated extractor (e.g. the IPO pipeline's own tooling). General conversion loses fidelity on complex tables and multi-column layouts.
3. **Untrusted files:** MarkItDown reads with the privileges of the running process. Only convert files from sources you trust, and prefer the narrowest `convert_*` entry point in code.
4. **Skip the Azure extras by default.** Azure Document Intelligence / Content Understanding cost money per call and send the document to the cloud. Use them only when the user explicitly asks for higher-quality OCR/layout extraction.
5. **Keep the output.** Write the `.md` next to the source (or into the target notes/index folder) rather than pasting a whole converted document into chat; report the path, format and any pages/sections that failed or look garbled.
