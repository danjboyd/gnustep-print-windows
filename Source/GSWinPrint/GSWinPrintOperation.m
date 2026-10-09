/*
   GSWinPrintOperation.m

   Print operation for the GSWinPrint printing bundle

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

#import <GNUstepBase/GNUstep.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSValue.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSPrinter.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import "GSWinPrintOperation.h"
#import "GSWinPrintSupport.h"

/* What the cairo backend's CairoWin32PrintingSurface expects. */
static NSString *printerFormat = @"GSWin32PrinterFormat";
static NSString *printerDeviceContextKey = @"GSWin32PrinterDeviceContext";

@interface GSWinPrintOperation (Private)
- (NSGraphicsContext*) _createFileContext;
- (NSMutableData*) _devModeForPrinter: (NSString*)name;
- (NSString*) _documentName;
- (void) _abortDocument;
@end

@implementation GSWinPrintOperation

+ (id) allocWithZone: (NSZone*)zone
{
  return NSAllocateObject(self, 0, zone);
}

- (void) dealloc
{
  [self _abortDocument];
  [super dealloc];
}

- (NSGraphicsContext*) createContext
{
  NSPrintInfo *info;
  NSString *name;
  NSMutableData *devMode;
  NSData *wideName;
  NSData *wideDocument;
  NSData *wideOutput = nil;
  id outputFile;
  NSMutableDictionary *attributes;
  DOCINFOW document;

  if (_context != nil)
    {
      return _context;
    }
  info = [self printInfo];
  if ([[info jobDisposition] isEqual: NSPrintSpoolJob] == NO)
    {
      return [self _createFileContext];
    }

  name = [[info printer] name];
  if (name == nil)
    {
      name = [[NSPrintInfo defaultPrinter] name];
    }
  if (name == nil)
    {
      NSLog(@"(GSWinPrint) There is no printer to print on");
      return nil;
    }

  devMode = [self _devModeForPrinter: name];
  wideName = GSWinPrintWideFromString(name);
  _hdc = CreateDCW(L"WINSPOOL", [wideName bytes], NULL,
    [devMode bytes]);
  if (_hdc == NULL)
    {
      NSLog(@"(GSWinPrint) CreateDCW(%@) failed (%lu)", name,
        (unsigned long)GetLastError());
      return nil;
    }

  wideDocument = GSWinPrintWideFromString([self _documentName]);
  memset(&document, 0, sizeof(document));
  document.cbSize = sizeof(document);
  document.lpszDocName = [wideDocument bytes];
  outputFile = [[info dictionary] objectForKey: GSWinPrintOutputFileKey];
  if ([outputFile isKindOfClass: [NSString class]])
    {
      wideOutput = GSWinPrintWideFromString(outputFile);
      document.lpszOutput = [wideOutput bytes];
    }
  if (StartDocW(_hdc, &document) <= 0)
    {
      NSLog(@"(GSWinPrint) StartDocW on %@ failed (%lu)", name,
        (unsigned long)GetLastError());
      DeleteDC(_hdc);
      _hdc = NULL;
      return nil;
    }

  attributes = [NSMutableDictionary dictionaryWithDictionary:
    [info dictionary]];
  [attributes setObject: printerFormat
                 forKey: NSGraphicsContextRepresentationFormatAttributeName];
  [attributes setObject: [NSValue valueWithPointer: _hdc]
                 forKey: printerDeviceContextKey];
  _context = RETAIN([NSGraphicsContext
    graphicsContextWithAttributes: attributes]);
  if (_context == nil)
    {
      [self _abortDocument];
    }
  return _context;
}

/* The pages have been drawn and the graphics context released: end the
 * document, which hands the job to the spooler.
 */
- (BOOL) _deliverSpooledResult
{
  BOOL ok;

  if (_hdc == NULL)
    {
      return NO;
    }
  ok = (EndDoc(_hdc) > 0);
  if (ok == NO)
    {
      NSLog(@"(GSWinPrint) EndDoc failed (%lu)",
        (unsigned long)GetLastError());
    }
  DeleteDC(_hdc);
  _hdc = NULL;
  return ok;
}

- (void) cleanUpOperation
{
  [self _abortDocument];
  [super cleanUpOperation];
}

@end

@implementation GSWinPrintOperation (Private)

/* A save or preview job: a PDF or PostScript file, as the other printing
 * bundles make.
 */
- (NSGraphicsContext*) _createFileContext
{
  NSMutableDictionary *info;
  NSString *output;

  info = [[self printInfo] dictionary];
  output = [info objectForKey: NSPrintSavePath];
  if (output == nil)
    {
      output = [NSString stringWithFormat: @"GSWinPrint-%@.pdf",
        [[NSProcessInfo processInfo] globallyUniqueString]];
      output = [NSTemporaryDirectory()
        stringByAppendingPathComponent: output];
    }
  ASSIGN(_path, output);
  [info setObject: _path forKey: @"NSOutputFile"];
  if ([[[_path pathExtension] lowercaseString] isEqualToString: @"ps"])
    {
      [info setObject: NSGraphicsContextPSFormat
               forKey: NSGraphicsContextRepresentationFormatAttributeName];
    }
  else
    {
      [info setObject: NSGraphicsContextPDFFormat
               forKey: NSGraphicsContextRepresentationFormatAttributeName];
    }
  _context = RETAIN([NSGraphicsContext graphicsContextWithAttributes: info]);
  return _context;
}

/* The driver settings for the job: those the print panel stored, else the
 * printer's defaults, with the print info's copies, collation and paper.
 * The orientation stays portrait: for a landscape job gui rotates the
 * page itself, and the driver turning the paper too would rotate it twice.
 */
- (NSMutableData*) _devModeForPrinter: (NSString*)name
{
  NSPrintInfo *info;
  NSDictionary *dict;
  NSData *stored;
  NSMutableData *data;
  DEVMODEW *devMode;
  id copies;
  id collate;
  short paper;

  info = [self printInfo];
  dict = [info dictionary];
  stored = [dict objectForKey: GSWinPrintDevModeKey];
  if ([stored isKindOfClass: [NSData class]]
    && [stored length] >= sizeof(DEVMODEW))
    {
      data = AUTORELEASE([stored mutableCopy]);
    }
  else
    {
      data = AUTORELEASE([GSWinPrintDefaultDevMode(name) mutableCopy]);
    }
  if (data == nil)
    {
      return nil;
    }
  devMode = [data mutableBytes];

  copies = [dict objectForKey: NSPrintCopies];
  if (copies != nil && [copies intValue] > 0)
    {
      devMode->dmCopies = (short)[copies intValue];
      devMode->dmFields |= DM_COPIES;
    }
  collate = [dict objectForKey: NSPrintMustCollate];
  if (collate != nil)
    {
      devMode->dmCollate = [collate boolValue] ? DMCOLLATE_TRUE
        : DMCOLLATE_FALSE;
      devMode->dmFields |= DM_COLLATE;
    }

  paper = GSWinPrintPaperForName([info paperName]);
  if (paper != 0)
    {
      devMode->dmPaperSize = paper;
      devMode->dmFields |= DM_PAPERSIZE;
      devMode->dmFields &= ~(DM_PAPERLENGTH | DM_PAPERWIDTH);
    }
  else if ([info paperSize].width > 0 && [info paperSize].height > 0)
    {
      NSSize size = [info paperSize];

      if ([info orientation] == NSLandscapeOrientation)
        {
          size = NSMakeSize(size.height, size.width);
        }
      devMode->dmPaperSize = 0;
      devMode->dmPaperWidth = (short)(size.width * 254.0 / 72.0 + 0.5);
      devMode->dmPaperLength = (short)(size.height * 254.0 / 72.0 + 0.5);
      devMode->dmFields &= ~DM_PAPERSIZE;
      devMode->dmFields |= DM_PAPERLENGTH | DM_PAPERWIDTH;
    }

  devMode->dmOrientation = DMORIENT_PORTRAIT;
  devMode->dmFields |= DM_ORIENTATION;
  return data;
}

/* The name the spooler shows for the job: the printed window's title. */
- (NSString*) _documentName
{
  NSString *title;

  title = [[[self view] window] title];
  if (title == nil || [title length] == 0)
    {
      title = [[NSProcessInfo processInfo] processName];
    }
  return title;
}

- (void) _abortDocument
{
  if (_hdc != NULL)
    {
      AbortDoc(_hdc);
      DeleteDC(_hdc);
      _hdc = NULL;
    }
}

@end
