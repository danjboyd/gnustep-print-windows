# Plan

Context: ObjcMarkdown (MarkdownViewer) issue #82. Today MarkdownViewer
prints on Windows by rendering HTML to PDF with a headless Edge and
handing the PDF to the shell's `print` verb, bypassing GNUstep printing
and the theme's print dialog.

## Known GNUstep problems on Windows (found 2026-10-09)

Built against MSYS2 CLANG64 GNUstep with the cairo backend (gnustep-back
0.32), WinUITheme as the theme.

1. **Jobs reach the printer as raw PostScript.** gnustep-gui's
   `Printing/GSWIN32/GSWIN32PrintOperation.m` spools PostScript and sends
   it with `WritePrinter` and datatype `RAW`. Only PostScript printers
   can read that. Not yet confirmed with a real job.
2. **A PDF save job writes to the wrong file.** `NSPrintSaveJob` with
   `NSPrintSavePath` `C:/.../out.pdf` produced a correct PDF named `C` in
   the working directory. gnustep-back's `CairoPDFSurface` passes
   `NSOutputFile` straight to `cairo_pdf_surface_create`, so the path is
   cut somewhere else. Cause not found yet.
3. **cairo asserts on a real document.** Exporting MarkdownViewer's
   README.md to PDF stops in `_cairo_surface_acquire_source_image` (CRT
   assert dialog). A one-word document works. Probably an image whose
   source surface the PDF surface can't read. Not narrowed down yet.

## Steps

1. Fix problem 2 (path) and problem 3 (assert) as gnustep-back patches,
   with a reproducer each. That alone lets MarkdownViewer's Export as PDF
   stop using Edge.
2. A cairo target for a printer device context in gnustep-back
   (`cairo_win32_printing_surface_create`), chosen by a print context
   attribute.
3. `GSWinPrint.bundle`: printer from the `NSPrintInfo` (`CreateDCW` with
   the panel's `DEVMODE` when there is one), `StartDocW`, a page per
   `StartPage`/`EndPage`, copies and page range from the print info.
4. Tests: print to `Microsoft Print to PDF` with `DOCINFO.lpszOutput`
   set, and compare page count and text with the expected document.
5. Check on real printers (an inkjet and a network laser at least).
6. MarkdownViewer: Print and Export as PDF through `NSPrintOperation` on
   Windows, keeping the Edge path as a fallback until this ships.

## Interface with WinUITheme

To agree with the theme (plugins-themes-winuitheme #69): which
`NSPrintInfo` keys carry the printer, copies, page range, collation and
the `DEVMODE` from `PrintDlgW`, so this bundle prints what the user chose.

## Open questions

- Text: GNUstep on Windows draws text with FreeType fonts; cairo's
  Windows printing surface may print such text as fallback images (300
  dpi by default) rather than as fonts. Acceptable on paper; check the
  spool size.
- Whether the theme or this bundle should own the page setup dialog
  (`PageSetupDlgW`).
