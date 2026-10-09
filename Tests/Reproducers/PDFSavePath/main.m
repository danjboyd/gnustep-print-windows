/*
   main.m

   Reproducer: save a page to a PDF file with an NSPrintOperation

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

/* Saves some text, and optionally an image, to a PDF file with an
 * NSPrintOperation save job, then reports whether the file is where it
 * was asked for.
 *
 * usage: PDFSavePath <output.pdf> [text] [image]
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

int
main(int argc, const char *argv[])
{
  NSAutoreleasePool     *pool;
  NSString              *path;
  NSString              *text;
  NSTextView            *view;
  NSPrintInfo           *info;
  NSPrintOperation      *operation;
  NSFileManager         *files;
  BOOL                  ok;
  BOOL                  exists;

  pool = [NSAutoreleasePool new];
  [NSApplication sharedApplication];

  if (argc < 2)
    {
      fprintf(stderr, "usage: PDFSavePath <output.pdf> [text] [image]\n");
      [pool release];
      return 2;
    }
  path = [NSString stringWithUTF8String: argv[1]];
  text = (argc > 2) ? [NSString stringWithUTF8String: argv[2]] : @"hello";

  view = AUTORELEASE([[NSTextView alloc]
    initWithFrame: NSMakeRect(0, 0, 468, 200)]);
  [view setString: text];
  if (argc > 3)
    {
      NSImage                   *image;
      NSTextAttachment          *attachment;
      NSAttributedString        *string;

      image = AUTORELEASE([[NSImage alloc] initWithContentsOfFile:
        [NSString stringWithUTF8String: argv[3]]]);
      attachment = AUTORELEASE([[NSTextAttachment alloc] init]);
      [(NSTextAttachmentCell *)[attachment attachmentCell] setImage: image];
      string = [NSAttributedString attributedStringWithAttachment: attachment];
      [[view textStorage] appendAttributedString: string];
    }

  info = AUTORELEASE([[NSPrintInfo sharedPrintInfo] copy]);
  /* On Windows the shared print info has no paper size (0 x 0), and
   * nothing is drawn on such a page; use US Letter then.
   */
  if ([info paperSize].width <= 0 || [info paperSize].height <= 0)
    {
      fprintf(stderr, "default paper size is %g x %g; using Letter\n",
        [info paperSize].width, [info paperSize].height);
      [info setPaperSize: NSMakeSize(612, 792)];
    }
  [info setJobDisposition: NSPrintSaveJob];
  [[info dictionary] setObject: path forKey: NSPrintSavePath];

  operation = [NSPrintOperation printOperationWithView: view
                                             printInfo: info];
  [operation setShowsPrintPanel: NO];
  [operation setShowsProgressPanel: NO];
  ok = [operation runOperation];

  files = [NSFileManager defaultManager];
  exists = [files fileExistsAtPath: path];
  printf("runOperation=%s exists=%s path=%s cwd=%s\n",
    ok ? "YES" : "NO", exists ? "YES" : "NO",
    [path UTF8String], [[files currentDirectoryPath] UTF8String]);

  [pool release];
  return (ok && exists) ? 0 : 1;
}
