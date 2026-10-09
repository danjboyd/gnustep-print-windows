#
#  GSWinPrint printing bundle makefile
#
#  Copyright (C) 2026 Daniel Boyd
#
#  Author: Daniel Boyd <danieljboyd@icloud.com>
#  Date: October 2026
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; see the file COPYING.LIB.
#  If not, see <http://www.gnu.org/licenses/> or write to the
#  Free Software Foundation, 51 Franklin Street, Fifth Floor,
#  Boston, MA 02110-1301, USA.

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = GSWinPrint
BUNDLE_INSTALL_DIR = $(GNUSTEP_BUNDLES)/GSPrinting
GSWinPrint_PRINCIPAL_CLASS = GSWinPrintPrincipalClass

GSWinPrint_OBJC_FILES = \
  GSWinPrintPrincipalClass.m \
  GSWinPrintInfo.m \
  GSWinPrintOperation.m \
  GSWinPrinter.m \
  GSWinPrintSupport.m

GSWinPrint_BUNDLE_LIBS += -lgnustep-gui -lgnustep-base -lobjc
ADDITIONAL_OBJCFLAGS += -Wall
ADDITIONAL_OBJC_LIBS += -lwinspool -lgdi32

include $(GNUSTEP_MAKEFILES)/bundle.make
