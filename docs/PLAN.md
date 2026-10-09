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
3. **cairo asserts on a document with images.** Saving a PDF stops on
   `Assertion failed: !surface->finished` (cairo-surface.c), reached from
   `_cairo_surface_acquire_source_image` when the page is emitted.
   Cause: gnustep-gui's `-[NSImage drawInRect:fromRect:...]` draws from
   its screen cache (a window holding a screen resolution copy) whenever
   the context `-supportsDrawGState`, printing included. The PDF surface
   records the window's surface and reads it at `cairo_show_page`, when
   cairo's snapshot of the Windows DDB surface is already finished. The
   cache also prints images at screen resolution on every platform.
   **Fixed** by `patches/libs-gui/0001-NSImage-draw-the-image-s-own-
   representation-when-not.patch`: use the cache only when
   `-isDrawingToScreen`. Test: `Tests/gui/NSImage/printingDoesNotCache.m`
   in the patch (it aborts on stock 0.32.0 on Windows and passes with the
   patch). The 0.32.0 backport is in `backports/0.32.0/libs-gui`.
4. **The default paper size is 0 x 0 on Windows.** `[NSPrintInfo
   sharedPrintInfo]` has no paper size, and a print operation then makes
   one blank page. gnustep-gui's GSWIN32 print info doesn't ask Windows
   for the default printer's paper. The `GSWinPrint` bundle will; until
   then apps set a size (MarkdownViewer does).
5. **An image that crosses a page break loses its top part.** In a PDF of
   a document whose screenshot spans two pages, the second page shows the
   image's lower part and the first only the background. Not looked at
   yet; it may be gnustep-gui's text drawing (an attachment drawn only on
   the page that holds its glyph).

## Steps

1. Done: carry gnustep-back 57a446c for problem 2
   (`patches/libs-back/0001-...`); problem 3 fixed in gnustep-gui
   (`patches/libs-gui/0001-...`). Builds for both (step 2) are
   `Scripts/build-gnustep-back.sh` and `Scripts/build-gnustep-gui.sh`, and
   `Scripts/make-test-runtime.sh` makes a private runtime to test them in
   without touching the toolchain. That alone lets MarkdownViewer's Export as PDF
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
