/*
   GSWinPrintPrincipalClass.h

   Principal class for the GSWinPrint printing bundle

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

#ifndef _GSWinPrintPrincipalClass_h
#define _GSWinPrintPrincipalClass_h

#import "GNUstepGUI/GSPrinting.h"

/* The printing bundle for Windows: it prints through the Windows print
 * spooler on the printer's own driver.  Select it with the GSPrinting
 * user default (GSWinPrint).
 */
@interface GSWinPrintPrincipalClass : GSPrintingPrincipalClass
{
}
@end

#endif /* _GSWinPrintPrincipalClass_h */
