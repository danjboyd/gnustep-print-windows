## Project

Printing for GNUstep applications on Windows: a printing bundle
(`GSWinPrint`) and patches for gnustep-back. The aim is to have it merged
into GNUstep, so everything here is written as GNUstep code from the
first line. See `README.md` and `docs/PLAN.md`.

## Coding standards (strict)

Follow GNUstep's coding standards
(libs-base `Documentation/coding-standards.texi`), which add to the GNU
coding standards. In short:

- Indent in steps of two spaces, GNU brace style; no tabs.
  ```
  if (a < b)
    {
      return b;
    }
  ```
- Function names start in column 0 with the return type on the line
  before; braces of function and method bodies in column 0.
- Method declarations: `- (void) methodWithArg: (int)arg andOther: (id)x;`
  (a space after `-`/`+`, after the return type and after each colon).
- Calls: `foo(a, b)`, no space before the parenthesis; casts `(int)b`.
  Binary operators surrounded by spaces. `char *foo`, not `char* foo`.
- Lines under 80 columns; wrapped before an operator, two more spaces in.
  Message sends wrap with the colons lined up.
- Declare variables at the start of a block, separated from the code by
  a blank line. A blank line between function and method bodies.
- Traditional Objective-C with manual retain/release: no blocks, no dot
  syntax, no ARC, no properties where an accessor will do. Use `ASSIGN`,
  `ASSIGNCOPY`, `DESTROY`, `RETAIN`, `RELEASE`, `AUTORELEASE`,
  `ENTER_POOL` and `LEAVE_POOL`.
- `/* ... */` for multi-line comments. `#else` and `#endif` carry the
  condition as a comment: `#endif /* _WIN32 */`.
- Names: GS prefix for GNUstep extensions (never NS for something that
  isn't Apple API); a leading underscore only for private methods and
  ivars; accessors mirror their ivars.
- init methods release self and return nil on failure, with an NSLog
  saying why. Other methods raise on failure. Release Windows handles
  (HDC, HANDLE, DEVMODE memory) on every path, exceptions included.
- Document every public method in its header, in your own words (never
  copied from Apple's documentation).
- Every change gets a `ChangeLog` entry in GNU format (what changed, not
  why; the why goes in the code). Entries are indented with a tab, as
  in GNUstep's own ChangeLogs:
  ```
  2026-10-09  Daniel Boyd  <danieljboyd@icloud.com>

  	* Source/GSWinPrintOperation.m (-_deliverSpooledResult): ...
  ```
- File header: the usual GNUstep block (file name, one-line purpose,
  copyright, author, date, the LGPL 2.1-or-later notice). Copyright is
  Daniel Boyd for now. GNUstep's own files say Free Software Foundation,
  which needs a copyright assignment; that is Dan's decision.
- Keep code ASCII. Build warning-free with clang (MSYS2 CLANG64), and
  with gcc where it can be built with gcc.
- gnustep-back patches are made against gnustep-back `master` and must
  also apply to the 0.32.0 release the Windows packages build.

## Process

- Commit author `Daniel Boyd <danieljboyd@icloud.com>`; GitHub account
  `danjboyd`.
- Nothing goes to GNUstep (issues, patches, pull requests, mail) without
  Dan's sign-off, following ObjcMarkdown's `docs/UPSTREAM_POLICY.md`.
- Tests must not print to a physical printer or open the user's apps:
  print to `Microsoft Print to PDF` with an output file.
