/*
   GSWinPrintInfo.m

   NSPrintInfo for the GSWinPrint printing bundle

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
#import <Foundation/NSUserDefaults.h>
#import <AppKit/NSPrinter.h>
#import "GSWinPrintInfo.h"
#import "GSWinPrintSupport.h"

static NSString *defaultPrinterKey = @"GSWinPrintDefaultPrinter";

@implementation GSWinPrintInfo

+ (id) allocWithZone: (NSZone*)zone
{
  return NSAllocateObject(self, 0, zone);
}

+ (NSPrinter*) defaultPrinter
{
  NSArray *names;
  NSString *name;

  names = [NSPrinter printerNames];
  if ([names count] == 0)
    {
      return nil;
    }
  name = [[NSUserDefaults standardUserDefaults] stringForKey:
    defaultPrinterKey];
  if (name == nil || [names containsObject: name] == NO)
    {
      name = GSWinPrintDefaultPrinterName();
    }
  if (name == nil || [names containsObject: name] == NO)
    {
      name = [names objectAtIndex: 0];
    }
  return [NSPrinter printerWithName: name];
}

/* Remembers the printer as the application's default.  Windows' own
 * default printer is the user's to change, not an application's.
 */
+ (void) setDefaultPrinter: (NSPrinter*)printer
{
  [[NSUserDefaults standardUserDefaults] setObject: [printer name]
                                            forKey: defaultPrinterKey];
}

@end
