/*
   GSWinPrinter.h

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

#ifndef _GSWinPrinter_h
#define _GSWinPrinter_h

#import <AppKit/NSPrinter.h>

/* A printer installed in Windows.  Its type is the name of its driver and
 * its host the port it prints to.  Instead of a PPD file, its tables hold
 * what the driver reports: the papers it takes (PageSize, PaperDimension,
 * ImageableArea and their display names), the default paper
 * (DefaultPageSize), whether it prints colour (ColorDevice) and its
 * resolution (DefaultResolution).
 */
@interface GSWinPrinter : NSPrinter
{
}
@end

#endif /* _GSWinPrinter_h */
