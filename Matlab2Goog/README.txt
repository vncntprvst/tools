2011/04/27
This set of matlab functions will allow creating
Google spreadsheets, adding worksheets to them, modifying the
worksheets, and placing data in them. The delete worksheet
function works intermittently so far (the DELETE request throws
400/Bad request sometimes).

Please see Matlab2GoogTest.m for sample usage (you'll need to
enter your gmail username/password).

Please note that you need to have urlreadwrite.m (unmodified as
available in the Matlab distribution in
MATLABROOT/toolbox/matlab/iofun/private/urlreadwrite.m) on your
path.

This was very much inspired by submission of Ofir Bibi (Create
Google Calendar event with SMS and Email notification, File ID:
#25698).

2011/6/20
The Google login box was inspired by submission of Matt Fig (41
Complete GUI Examples, File ID: #24861). Some of the code was
somewhat simplified, there is a new function, getWorksheetCell,
that reads both the cell value and the forumula. editWorksheetCell
supports entering formulas as string (see Google Spreadsheet
API for examples).
