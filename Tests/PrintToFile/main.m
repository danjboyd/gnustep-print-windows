/*
   main.m

   Prints a test document on a Windows printer, into a file

   Copyright (C) 2026 Daniel Boyd

   Author: Daniel Boyd <danieljboyd@icloud.com>
   Date: October 2026

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

/* Prints a three page test document with the GSWinPrint bundle on a
 * printer, with the job's output going to a file through the printer's
 * driver (GSWinPrintOutputFile), so nothing reaches paper.  With the
 * "Microsoft Print to PDF" printer the file is a PDF.  Each page has a
 * frame at the paper's margins, a title, a paragraph and a red square,
 * so the PDF shows whether pages, placement, text and colour come out.
 *
 * usage: PrintToFile <printer name> <output file> [Letter|A4]
 * Run with -GSPrinting GSWinPrint to select the bundle.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface TestPageView : NSView
{
}
@end

@implementation TestPageView

- (BOOL) knowsPageRange: (NSRangePointer)range
{
  range->location = 1;
  range->length = 3;
  return YES;
}

- (NSRect) rectForPage: (NSInteger)page
{
  NSSize paper = [[[NSPrintOperation currentOperation] printInfo]
    paperSize];

  return NSMakeRect(0, (3 - page) * paper.height, paper.width,
    paper.height);
}

- (void) drawRect: (NSRect)rect
{
  NSSize paper = [[[NSPrintOperation currentOperation] printInfo]
    paperSize];
  NSInteger page;
  NSDictionary *titleAttributes;
  NSDictionary *textAttributes;

  titleAttributes = [NSDictionary dictionaryWithObject:
    [NSFont boldSystemFontOfSize: 24] forKey: NSFontAttributeName];
  textAttributes = [NSDictionary dictionaryWithObject:
    [NSFont systemFontOfSize: 12] forKey: NSFontAttributeName];

  for (page = 1; page <= 3; page++)
    {
      NSRect pageRect = [self rectForPage: page];
      NSRect frame;

      if (NSIntersectsRect(rect, pageRect) == NO)
        {
          continue;
        }
      /* A frame half an inch inside the paper's edges. */
      frame = NSInsetRect(pageRect, 36, 36);
      [[NSColor blackColor] set];
      NSFrameRectWithWidth(frame, 1.0);

      [[NSString stringWithFormat: @"GSWinPrint test page %ld of 3",
        (long)page] drawAtPoint: NSMakePoint(NSMinX(frame) + 18,
          NSMaxY(frame) - 48) withAttributes: titleAttributes];
      [@"The quick brown fox jumps over the lazy dog. 0123456789"
        drawAtPoint: NSMakePoint(NSMinX(frame) + 18, NSMaxY(frame) - 80)
        withAttributes: textAttributes];
      [[NSString stringWithFormat: @"Paper %g x %g points", paper.width,
        paper.height] drawAtPoint: NSMakePoint(NSMinX(frame) + 18,
          NSMaxY(frame) - 100) withAttributes: textAttributes];

      [[NSColor redColor] set];
      NSRectFill(NSMakeRect(NSMinX(frame) + 18, NSMinY(frame) + 18,
        72, 72));
    }
}

@end

int
main(int argc, const char *argv[])
{
  NSAutoreleasePool *pool;
  NSString *printerName;
  NSString *output;
  NSPrinter *printer;
  NSPrintInfo *info;
  TestPageView *view;
  NSPrintOperation *operation;
  NSData *head;
  BOOL ok;

  pool = [NSAutoreleasePool new];
  [NSApplication sharedApplication];
  if (argc < 3)
    {
      fprintf(stderr,
        "usage: PrintToFile <printer name> <output file> [Letter|A4]\n");
      [pool release];
      return 2;
    }
  printerName = [NSString stringWithUTF8String: argv[1]];
  output = [NSString stringWithUTF8String: argv[2]];

  printf("printers:\n");
  {
    NSEnumerator *e = [[NSPrinter printerNames] objectEnumerator];
    NSString *name;

    while ((name = [e nextObject]) != nil)
      {
        printf("  %s\n", [name UTF8String]);
      }
  }
  printf("default printer: %s\n",
    [[[NSPrintInfo defaultPrinter] name] UTF8String]);

  printer = [NSPrinter printerWithName: printerName];
  printf("printer: %s, type %s, host %s, colour %d\n",
    [[printer name] UTF8String], [[printer type] UTF8String],
    [[printer host] UTF8String], [printer isColor]);
  printf("default paper: %s\n", [[printer stringForKey: @"DefaultPageSize"
    inTable: @"PPD"] UTF8String]);

  info = AUTORELEASE([[NSPrintInfo alloc] initWithDictionary: nil]);
  [info setPrinter: printer];
  if (argc > 3)
    {
      [info setPaperName: [NSString stringWithUTF8String: argv[3]]];
    }
  printf("paper: %s, %g x %g, imageable %s\n",
    [[info paperName] UTF8String], [info paperSize].width,
    [info paperSize].height,
    [NSStringFromRect([printer imageRectForPaper: [info paperName]])
      UTF8String]);
  if (getenv("PRINTTOFILE_SAVE_JOB") != NULL)
    {
      /* GNUstep's own PDF output instead of the printer's, to compare. */
      [info setJobDisposition: NSPrintSaveJob];
      [[info dictionary] setObject: output forKey: NSPrintSavePath];
    }
  else
    {
      [[info dictionary] setObject: output forKey: @"GSWinPrintOutputFile"];
    }
  [[NSFileManager defaultManager] removeFileAtPath: output handler: nil];

  view = AUTORELEASE([[TestPageView alloc] initWithFrame: NSMakeRect(0, 0,
    [info paperSize].width, 3 * [info paperSize].height)]);
  operation = [NSPrintOperation printOperationWithView: view
                                             printInfo: info];
  [operation setShowsPrintPanel: NO];
  [operation setShowsProgressPanel: NO];
  ok = [operation runOperation];
  printf("runOperation: %s\n", ok ? "YES" : "NO");

  /* The spooler writes the file after the job is handed over. */
  {
    int tries;

    for (tries = 0; tries < 60; tries++)
      {
        NSDictionary *a = [[NSFileManager defaultManager]
          fileAttributesAtPath: output traverseLink: NO];

        if (a != nil && [a fileSize] > 0)
          {
            break;
          }
        [NSThread sleepForTimeInterval: 0.5];
      }
  }
  head = [[NSFileHandle fileHandleForReadingAtPath: output]
    readDataOfLength: 5];
  printf("output: %s, %llu bytes, starts %s\n", [output UTF8String],
    [[[NSFileManager defaultManager] fileAttributesAtPath: output
      traverseLink: NO] fileSize],
    head ? [AUTORELEASE([[NSString alloc] initWithData: head
      encoding: NSASCIIStringEncoding]) UTF8String] : "(none)");

  [pool release];
  return ok ? 0 : 1;
}
