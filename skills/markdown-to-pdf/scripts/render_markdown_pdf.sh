#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: render_markdown_pdf.sh <input.md> [output.pdf]" >&2
  exit 1
fi

INPUT="$1"
if [[ ! -f "$INPUT" ]]; then
  echo "Input file not found: $INPUT" >&2
  exit 1
fi

if [[ $# -eq 2 ]]; then
  OUTPUT="$2"
else
  OUTPUT="${INPUT%.*}.pdf"
fi

TMP_HTML="$(mktemp /tmp/markdown-to-pdf.XXXXXX.html)"
cleanup() {
  rm -f "$TMP_HTML"
}
trap cleanup EXIT

render_with_pandoc() {
  pandoc "$INPUT" -o "$OUTPUT"
}

render_html_with_python() {
  python3 - "$INPUT" "$TMP_HTML" <<'PY'
from __future__ import annotations

import html
import pathlib
import re
import sys

input_path = pathlib.Path(sys.argv[1])
output_path = pathlib.Path(sys.argv[2])
text = input_path.read_text(encoding="utf-8")

def inline_format(s: str) -> str:
    s = html.escape(s)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"\*([^*]+)\*", r"<em>\1</em>", s)
    return s

lines = text.splitlines()
parts: list[str] = []
in_code = False
code_lines: list[str] = []
in_list = False
paragraph: list[str] = []

def flush_paragraph() -> None:
    global paragraph
    if paragraph:
        joined = " ".join(p.strip() for p in paragraph).strip()
        if joined:
            parts.append(f"<p>{inline_format(joined)}</p>")
        paragraph = []

def flush_list() -> None:
    global in_list
    if in_list:
        parts.append("</ul>")
        in_list = False

for line in lines:
    if line.startswith("```"):
        flush_paragraph()
        flush_list()
        if in_code:
            parts.append("<pre><code>")
            parts.append(html.escape("\n".join(code_lines)))
            parts.append("</code></pre>")
            code_lines = []
            in_code = False
        else:
            in_code = True
        continue

    if in_code:
        code_lines.append(line)
        continue

    stripped = line.strip()
    if not stripped:
        flush_paragraph()
        flush_list()
        continue

    heading_match = re.match(r"^(#{1,6})\s+(.*)$", stripped)
    if heading_match:
        flush_paragraph()
        flush_list()
        level = len(heading_match.group(1))
        parts.append(f"<h{level}>{inline_format(heading_match.group(2))}</h{level}>")
        continue

    list_match = re.match(r"^[-*]\s+(.*)$", stripped)
    if list_match:
        flush_paragraph()
        if not in_list:
            parts.append("<ul>")
            in_list = True
        parts.append(f"<li>{inline_format(list_match.group(1))}</li>")
        continue

    flush_list()
    paragraph.append(stripped)

flush_paragraph()
flush_list()
if in_code:
    parts.append("<pre><code>")
    parts.append(html.escape("\n".join(code_lines)))
    parts.append("</code></pre>")

html_doc = f"""<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>{html.escape(input_path.name)}</title>
  <style>
    body {{
      font-family: Georgia, serif;
      margin: 48px;
      line-height: 1.5;
      color: #111;
    }}
    h1, h2, h3, h4, h5, h6 {{
      margin-top: 1.4em;
      margin-bottom: 0.4em;
    }}
    pre {{
      background: #f5f5f5;
      padding: 12px;
      overflow-x: auto;
      border: 1px solid #ddd;
    }}
    code {{
      font-family: Menlo, Consolas, monospace;
    }}
    p, ul {{
      margin: 0.7em 0;
    }}
  </style>
</head>
<body>
{''.join(parts)}
</body>
</html>
"""

output_path.write_text(html_doc, encoding="utf-8")
PY
}

render_with_weasyprint() {
  render_html_with_python
  weasyprint "$TMP_HTML" "$OUTPUT"
}

render_with_wkhtmltopdf() {
  render_html_with_python
  wkhtmltopdf "$TMP_HTML" "$OUTPUT"
}

render_with_chrome() {
  render_html_with_python

  local chrome_bin=""
  if command -v google-chrome >/dev/null 2>&1; then
    chrome_bin="$(command -v google-chrome)"
  elif command -v chromium >/dev/null 2>&1; then
    chrome_bin="$(command -v chromium)"
  elif [[ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]]; then
    chrome_bin="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  fi

  if [[ -z "$chrome_bin" ]]; then
    return 1
  fi

  "$chrome_bin" \
    --headless=new \
    --disable-gpu \
    --print-to-pdf="$OUTPUT" \
    "file://$TMP_HTML" >/dev/null 2>&1
}

if command -v pandoc >/dev/null 2>&1; then
  render_with_pandoc
  echo "Rendered $OUTPUT with pandoc"
  exit 0
fi

if command -v weasyprint >/dev/null 2>&1; then
  render_with_weasyprint
  echo "Rendered $OUTPUT with weasyprint"
  exit 0
fi

if command -v wkhtmltopdf >/dev/null 2>&1; then
  render_with_wkhtmltopdf
  echo "Rendered $OUTPUT with wkhtmltopdf"
  exit 0
fi

if render_with_chrome; then
  echo "Rendered $OUTPUT with headless Chrome"
  exit 0
fi

echo "No supported Markdown-to-PDF renderer found." >&2
echo "Install one of: pandoc, weasyprint, wkhtmltopdf, or Google Chrome." >&2
exit 1
