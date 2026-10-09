/*
   GSWinPrintPrincipalClass.m

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

#import "GSWinPrintPrincipalClass.h"
#import "GSWinPrintInfo.h"
#import "GSWinPrintOperation.h"
#import "GSWinPrinter.h"

@implementation GSWinPrintPrincipalClass

+ (Class) printInfoClass
{
  return [GSWinPrintInfo class];
}

+ (Class) printOperationClass
{
  return [GSWinPrintOperation class];
}

+ (Class) printerClass
{
  return [GSWinPrinter class];
}

+ (Class) gsPrintOperationClass
{
  return [GSWinPrintOperation class];
}

@end
