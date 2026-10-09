# gnustep-print-windows

Printing for GNUstep applications on Windows: the pages an app prints
reach the printer chosen in the print dialog, drawn by Windows' own
printing system.

## Why

GNUstep loads its printing code from a plug-in bundle, chosen by the
`GSPrinting` user default. On Windows that is gnustep-gui's `GSWIN32`
bundle, which spools the job as PostScript and sends it to the printer
as raw data. Most Windows printers, `Microsoft Print to PDF` among them,
can't read PostScript, so GNUstep apps can't print on Windows.

## What this is

- **`GSWinPrint.bundle`**: a printing bundle that replaces `GSWIN32`. It
  opens the printer chosen in the print panel, starts a Windows print
  job, and has GNUstep draw each page onto the printer's device context.
  Apps select it with the `GSPrinting` default (`GSWinPrint`).
- **Patches for gnustep-back** (`patches/libs-back`): a cairo drawing
  target for a Windows printer device context, next to gnustep-back's
  existing PDF and PostScript targets, plus fixes found on the way
  (PDF output on Windows). These are developed here and carried by the
  packages that need them until GNUstep has them.
- **A test app and tests** that print to `Microsoft Print to PDF` with an
  output file, so a print can be checked without a dialog or paper.

The print panel itself is the theme's business: WinUITheme shows the
Windows print dialog and records the printer, copies and page range in
the `NSPrintInfo`, which this bundle reads.

## Status

Started 2026-10-09. Nothing works yet. The plan and the known GNUstep
problems are in [docs/PLAN.md](docs/PLAN.md).

## Upstream

The aim is to offer this to GNUstep, as a replacement for `GSWIN32` and
as gnustep-back patches, once it works and has been checked on real
printers.

## License

LGPL-2.1-or-later, like GNUstep's libraries. See `COPYING.LIB`.
