/*
   GSWinPrintSupport.h

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

#ifndef _GSWinPrintSupport_h
#define _GSWinPrintSupport_h

#include <windows.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>

/* The key under which an NSPrintInfo's dictionary may hold the printer
 * driver's settings, as the bytes of a DEVMODEW (NSData).  A print panel
 * that shows the Windows print dialog stores them there so the job keeps
 * what the user chose in the driver's own pages (tray, duplex, colour).
 * PROVISIONAL: the name is still to be agreed with the theme that writes it.
 */
#define GSWinPrintDevModeKey @"GSWin32DevMode"

/* The key under which an NSPrintInfo's dictionary may name a file for a
 * spooled job: the printer's driver writes its output there instead of
 * sending it to the printer, as Windows' "Print to file" does.  For the
 * Microsoft Print to PDF printer this is the PDF file, written without
 * asking the user for a name.
 */
#define GSWinPrintOutputFileKey @"GSWinPrintOutputFile"

/* Returns a string made from a NUL terminated UTF-16 string, or nil. */
NSString *GSWinPrintStringFromWide(const WCHAR *wide);

/* Returns the string as NUL terminated UTF-16, in an autoreleased data
 * object whose -bytes may be passed to the wide Windows functions.
 */
NSData *GSWinPrintWideFromString(NSString *string);

/* The name of the printer Windows prints to by default, or nil. */
NSString *GSWinPrintDefaultPrinterName(void);

/* The printer's default driver settings (a DEVMODEW), or nil. */
NSData *GSWinPrintDefaultDevMode(NSString *printerName);

/* The PostScript name GNUstep uses for a Windows paper (DMPAPER_*), such
 * as Letter or A4, or windowsName when the paper has no common name.
 */
NSString *GSWinPrintNameForPaper(short paper, NSString *windowsName);

/* The Windows paper (DMPAPER_*) for a PostScript paper name, or 0. */
short GSWinPrintPaperForName(NSString *name);

#endif /* _GSWinPrintSupport_h */
