/*
   GSWinPrintOperation.h

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

#ifndef _GSWinPrintOperation_h
#define _GSWinPrintOperation_h

#include <windows.h>
#import "GNUstepGUI/GSPrintOperation.h"

/* A spooled job is printed through the Windows print spooler: the
 * operation opens a device context on the chosen printer with its
 * driver's settings, adjusted to the print info (copies, collation,
 * paper), starts a document on it, and has the cairo backend draw each
 * page there.  The spooler gets the pages in the driver's own language,
 * so any installed printer can print them.  A job saved to a file is
 * written as PDF (or PostScript, for a path ending in .ps) instead.
 */
@interface GSWinPrintOperation : GSPrintOperation
{
  HDC _hdc;
}
@end

#endif /* _GSWinPrintOperation_h */
