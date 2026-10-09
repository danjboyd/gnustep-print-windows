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
   `NSPrintSavePath` `C:/.../out.pdf` writes a correct PDF named `C` in
   the working directory (`out.pdf` gives a file named `o`). gnustep-back
   0.32.0's `CairoPDFSurface` and `CairoPSSurface` pass
   `-fileSystemRepresentation` to cairo, which on Windows is UTF-16, so
   cairo reads one character. **Already fixed upstream** by gnustep-back
   57a446c ("give cairo a UTF-8 filename for PS and PDF output", #140,
   July 2026), after 0.32.0; MSYS2 ships 0.32.0. To do: carry that commit
   in the Windows packages' GNUstep build. Reproducer:
   `Tests/Reproducers/PDFSavePath`.
3. **cairo asserts on a real document.** Exporting MarkdownViewer's
   README.md to PDF stops in `_cairo_surface_acquire_source_image` (CRT
   assert dialog). A one-word document works. Probably an image whose
   source surface the PDF surface can't read. Not narrowed down yet: a
   text view with an image attachment (PNG) saves without the assert.

## Steps

1. Carry gnustep-back 57a446c for problem 2; find and fix problem 3
   (assert) as a gnustep-back patch, with a reproducer. That alone lets MarkdownViewer's Export as PDF
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

Agreed with the theme session on 2026-10-09. WinUITheme's print panel
(#69, branch native-dialogs, not yet released) runs `PrintDlgW` and
writes the user's choices into the `NSPrintInfo`; this bundle reads them:

| What | Key | Written by the theme |
|---|---|---|
| Printer | `-[NSPrintInfo printer]`, named as Windows names it (DEVNAMES device) | Yes, when GNUstep knows the printer |
| Copies | `NSPrintCopies` | Yes |
| Page range | `NSPrintAllPages`, `NSPrintFirstPage`, `NSPrintLastPage` (1-based) | Yes |
| Collate | `NSPrintMustCollate` | Yes |
| Paper, orientation | `-setPaperName:`, `-setPaperSize:`, `-setOrientation:` | Yes (Letter, Legal, Executive, Tabloid, A3, A4, A5, B5) |
| Driver settings (tray, duplex, colour, ...) | The `DEVMODEW` bytes as `NSData` | Not yet: the key's name is Dan's call |
| Print to file | - | No: the theme hides it (`PD_HIDEPRINTTOFILE`) |

Until the DEVMODE is passed on, the bundle builds one from the printer's
default (`DocumentPropertiesW`) and applies copies, collation, paper and
orientation from the keys above.

Page setup belongs to the theme: it runs `PageSetupDlgW` from
`-[NSApplication runPageLayout:]` and NSDocument's
`-runModalPageLayoutWithPrintInfo:...`, writing the same keys plus
margins. (`+[NSPageLayout pageLayout]` itself fails on Windows with gui
0.32: "Could not load page layout panel resource".)

Windows 11 shows its modern print dialog for `PrintDlgW`; it takes the
same input and returns the same values.

## Open questions

- Text: GNUstep on Windows draws text with FreeType fonts; cairo's
  Windows printing surface may print such text as fallback images (300
  dpi by default) rather than as fonts. Acceptable on paper; check the
  spool size.
- The DEVMODE key's name: this bundle's own or a GNUstep-wide one.
