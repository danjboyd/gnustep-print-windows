/*
   GSWinPrintSupport.m

   Windows helpers shared by the GSWinPrint printing bundle

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
#import <Foundation/NSDebug.h>
#import "GSWinPrintSupport.h"
#include <winspool.h>
#include <wchar.h>

/* Windows papers with the names GNUstep's PostScript tables use. */
static const struct
{
  short paper;
  const char *name;
} paperNames[] = {
  { DMPAPER_LETTER, "Letter" },
  { DMPAPER_LEGAL, "Legal" },
  { DMPAPER_EXECUTIVE, "Executive" },
  { DMPAPER_TABLOID, "Tabloid" },
  { DMPAPER_LEDGER, "Ledger" },
  { DMPAPER_STATEMENT, "Statement" },
  { DMPAPER_A3, "A3" },
  { DMPAPER_A4, "A4" },
  { DMPAPER_A5, "A5" },
  { DMPAPER_A6, "A6" },
  { DMPAPER_B4, "B4" },
  { DMPAPER_B5, "B5" },
  { DMPAPER_ENV_10, "Env10" },
  { DMPAPER_ENV_DL, "EnvDL" },
  { DMPAPER_ENV_C5, "EnvC5" },
  { DMPAPER_ENV_MONARCH, "EnvMonarch" },
  { 0, NULL }
};

NSString *
GSWinPrintStringFromWide(const WCHAR *wide)
{
  if (wide == NULL)
    {
      return nil;
    }
  return [NSString stringWithCharacters: (const unichar *)wide
                                 length: wcslen(wide)];
}

NSData *
GSWinPrintWideFromString(NSString *string)
{
  NSMutableData *data;
  NSUInteger length;

  length = [string length];
  data = [NSMutableData dataWithLength: (length + 1) * sizeof(WCHAR)];
  [string getCharacters: (unichar *)[data mutableBytes]
                  range: NSMakeRange(0, length)];
  return data;
}

NSString *
GSWinPrintDefaultPrinterName(void)
{
  DWORD size = 0;
  NSMutableData *buffer;

  GetDefaultPrinterW(NULL, &size);
  if (size == 0)
    {
      return nil;
    }
  buffer = [NSMutableData dataWithLength: size * sizeof(WCHAR)];
  if (GetDefaultPrinterW([buffer mutableBytes], &size) == FALSE)
    {
      return nil;
    }
  return GSWinPrintStringFromWide([buffer bytes]);
}

NSData *
GSWinPrintDefaultDevMode(NSString *printerName)
{
  NSData *wideName;
  HANDLE printer = NULL;
  LONG size;
  NSMutableData *devMode = nil;

  wideName = GSWinPrintWideFromString(printerName);
  if (OpenPrinterW((LPWSTR)[wideName bytes], &printer, NULL) == FALSE)
    {
      NSDebugLLog(@"GSPrinting", @"OpenPrinterW(%@) failed (%lu)",
        printerName, (unsigned long)GetLastError());
      return nil;
    }
  size = DocumentPropertiesW(NULL, printer, (LPWSTR)[wideName bytes],
    NULL, NULL, 0);
  if (size > 0)
    {
      devMode = [NSMutableData dataWithLength: size];
      if (DocumentPropertiesW(NULL, printer, (LPWSTR)[wideName bytes],
        [devMode mutableBytes], NULL, DM_OUT_BUFFER) != IDOK)
        {
          devMode = nil;
        }
    }
  ClosePrinter(printer);
  return devMode;
}

NSString *
GSWinPrintNameForPaper(short paper, NSString *windowsName)
{
  int i;

  for (i = 0; paperNames[i].name != NULL; i++)
    {
      if (paperNames[i].paper == paper)
        {
          return [NSString stringWithUTF8String: paperNames[i].name];
        }
    }
  return windowsName;
}

short
GSWinPrintPaperForName(NSString *name)
{
  int i;

  for (i = 0; paperNames[i].name != NULL; i++)
    {
      if ([name isEqualToString:
        [NSString stringWithUTF8String: paperNames[i].name]])
        {
          return paperNames[i].paper;
        }
    }
  return 0;
}
