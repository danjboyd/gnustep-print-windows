/*
   GSWinPrinter.m

   NSPrinter for printers known to the Windows print spooler

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
#import <Foundation/NSArray.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import "GSWinPrinter.h"
#import "GSWinPrintSupport.h"
#include <winspool.h>

/* NSPrinter's own table storage, which its PPD parser uses. */
@interface NSPrinter (GSWinPrintTables)
- (id) addString: (NSString*)string
          forKey: (NSString*)key
         inTable: (NSString*)table;
@end

@interface GSWinPrinter (Private)
+ (NSDictionary*) _printers;
- (void) _loadCapabilitiesWithPort: (NSString*)port;
@end

/* Tenths of a millimetre to points. */
static double
pointsFromTenthsOfMM(long tenths)
{
  return tenths * 72.0 / 254.0;
}

@implementation GSWinPrinter

+ (id) allocWithZone: (NSZone*)zone
{
  return NSAllocateObject(self, 0, zone);
}

+ (NSPrinter*) printerWithName: (NSString*)name
{
  NSDictionary *entry;
  GSWinPrinter *printer;

  entry = [[self _printers] objectForKey: name];
  if (entry == nil)
    {
      [NSException raise: NSGenericException
                  format: @"(GSWinPrint) Could not find printer named %@",
                    name];
      return nil;
    }
  printer = [[self alloc] initWithName: name
                              withType: [entry objectForKey: @"Driver"]
                              withHost: [entry objectForKey: @"Port"]
                              withNote: [entry objectForKey: @"Comment"]];
  [printer _loadCapabilitiesWithPort: [entry objectForKey: @"Port"]];
  return AUTORELEASE(printer);
}

+ (NSArray*) printerNames
{
  return [[self _printers] allKeys];
}

@end

@implementation GSWinPrinter (Private)

/* The installed printers, local and network connections, keyed by name,
 * each with its driver, port and comment.
 */
+ (NSDictionary*) _printers
{
  DWORD flags = PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS;
  DWORD needed = 0;
  DWORD count = 0;
  NSMutableData *buffer;
  PRINTER_INFO_2W *info;
  NSMutableDictionary *printers;
  DWORD i;

  printers = [NSMutableDictionary dictionary];
  EnumPrintersW(flags, NULL, 2, NULL, 0, &needed, &count);
  if (needed == 0)
    {
      return printers;
    }
  buffer = [NSMutableData dataWithLength: needed];
  if (EnumPrintersW(flags, NULL, 2, [buffer mutableBytes], needed,
    &needed, &count) == FALSE)
    {
      NSLog(@"(GSWinPrint) EnumPrintersW failed (%lu)",
        (unsigned long)GetLastError());
      return printers;
    }
  info = (PRINTER_INFO_2W *)[buffer mutableBytes];
  for (i = 0; i < count; i++)
    {
      NSString *name = GSWinPrintStringFromWide(info[i].pPrinterName);
      NSString *driver = GSWinPrintStringFromWide(info[i].pDriverName);
      NSString *port = GSWinPrintStringFromWide(info[i].pPortName);
      NSString *comment = GSWinPrintStringFromWide(info[i].pComment);

      if (name == nil)
        {
          continue;
        }
      [printers setObject: [NSDictionary dictionaryWithObjectsAndKeys:
        (driver ? driver : @""), @"Driver",
        (port ? port : @""), @"Port",
        (comment ? comment : @""), @"Comment",
        nil] forKey: name];
    }
  return printers;
}

/* Fills the printer's tables from what its driver reports. */
- (void) _loadCapabilitiesWithPort: (NSString*)port
{
  NSData *wideName;
  NSData *widePort;
  NSData *devModeData;
  const DEVMODEW *devMode = NULL;
  HDC ic;
  int count;
  int i;
  double left = 0.0;
  double top = 0.0;
  double right = 0.0;
  double bottom = 0.0;
  int resolution = 0;
  NSString *defaultName = nil;

  [_tables setObject: [NSMutableDictionary dictionary] forKey: @"PPD"];
  [_tables setObject: [NSMutableDictionary dictionary]
              forKey: @"PPDOptionTranslation"];

  wideName = GSWinPrintWideFromString([self name]);
  widePort = GSWinPrintWideFromString(port);
  devModeData = GSWinPrintDefaultDevMode([self name]);
  if (devModeData != nil)
    {
      devMode = [devModeData bytes];
    }

  /* The margins the driver can't print in, for its default paper.  They
   * are used for every paper: asking for each would mean a device context
   * per paper.
   */
  ic = CreateICW(L"WINSPOOL", [wideName bytes], NULL, devMode);
  if (ic != NULL)
    {
      int dpiX = GetDeviceCaps(ic, LOGPIXELSX);
      int dpiY = GetDeviceCaps(ic, LOGPIXELSY);

      if (dpiX > 0 && dpiY > 0)
        {
          double paperW = GetDeviceCaps(ic, PHYSICALWIDTH) * 72.0 / dpiX;
          double paperH = GetDeviceCaps(ic, PHYSICALHEIGHT) * 72.0 / dpiY;
          double printW = GetDeviceCaps(ic, HORZRES) * 72.0 / dpiX;
          double printH = GetDeviceCaps(ic, VERTRES) * 72.0 / dpiY;

          left = GetDeviceCaps(ic, PHYSICALOFFSETX) * 72.0 / dpiX;
          top = GetDeviceCaps(ic, PHYSICALOFFSETY) * 72.0 / dpiY;
          right = paperW - printW - left;
          bottom = paperH - printH - top;
          resolution = dpiX;
        }
      DeleteDC(ic);
    }

  count = DeviceCapabilitiesW([wideName bytes], [widePort bytes],
    DC_PAPERS, NULL, NULL);
  if (count > 0)
    {
      NSMutableData *papers;
      NSMutableData *names;
      NSMutableData *sizes;
      const WORD *paper;
      const WCHAR *paperName;
      const POINT *size;

      papers = [NSMutableData dataWithLength: count * sizeof(WORD)];
      names = [NSMutableData dataWithLength: count * 64 * sizeof(WCHAR)];
      sizes = [NSMutableData dataWithLength: count * sizeof(POINT)];
      DeviceCapabilitiesW([wideName bytes], [widePort bytes], DC_PAPERS,
        [papers mutableBytes], NULL);
      DeviceCapabilitiesW([wideName bytes], [widePort bytes],
        DC_PAPERNAMES, [names mutableBytes], NULL);
      DeviceCapabilitiesW([wideName bytes], [widePort bytes], DC_PAPERSIZE,
        [sizes mutableBytes], NULL);
      paper = [papers bytes];
      paperName = [names bytes];
      size = [sizes bytes];

      for (i = 0; i < count; i++)
        {
          WCHAR display[65];
          NSString *windowsName;
          NSString *name;
          double width;
          double height;

          /* Each name is 64 characters, not always NUL terminated. */
          wcsncpy(display, paperName + i * 64, 64);
          display[64] = 0;
          windowsName = GSWinPrintStringFromWide(display);
          name = GSWinPrintNameForPaper(paper[i], windowsName);
          if (name == nil || [name length] == 0)
            {
              continue;
            }
          width = pointsFromTenthsOfMM(size[i].x);
          height = pointsFromTenthsOfMM(size[i].y);

          [self addString: name forKey: @"PageSize" inTable: @"PPD"];
          [self addString: windowsName
                   forKey: [@"PageSize/" stringByAppendingString: name]
                  inTable: @"PPDOptionTranslation"];
          [self addString: [NSString stringWithFormat: @"%g %g",
            width, height]
                   forKey: [@"PaperDimension/" stringByAppendingString: name]
                  inTable: @"PPD"];
          [self addString: [NSString stringWithFormat: @"%g %g %g %g",
            left, bottom, width - right, height - top]
                   forKey: [@"ImageableArea/" stringByAppendingString: name]
                  inTable: @"PPD"];
          if (devMode != NULL && (devMode->dmFields & DM_PAPERSIZE)
            && devMode->dmPaperSize == paper[i])
            {
              defaultName = name;
            }
        }
    }

  if (defaultName != nil)
    {
      [self addString: defaultName forKey: @"DefaultPageSize"
              inTable: @"PPD"];
    }
  [self addString: (DeviceCapabilitiesW([wideName bytes], [widePort bytes],
    DC_COLORDEVICE, NULL, NULL) == 1) ? @"True" : @"False"
           forKey: @"ColorDevice"
          inTable: @"PPD"];
  if (resolution > 0)
    {
      [self addString: [NSString stringWithFormat: @"%ddpi", resolution]
               forKey: @"DefaultResolution"
              inTable: @"PPD"];
    }
}

@end
