%REGEXPI Match regular expressions, ignoring case. 
%   START = REGEXPI(STRING,EXPRESSION) returns a row vector, START, which 
%   contains the indices of the substrings in STRING that match the regular 
%   expression string, EXPRESSION, regardless of case. 
% 
%   In EXPRESSION the following symbols have special meaning: 
% 
%               Symbol   Meaning 
%              --------  -------------------------------- 
%                  ^     start of string 
%                  $     end of string 
%                  .     any character 
%                  \     quote next character 
%                  *     match zero or more 
%                  +     match one or more 
%                  ?     match zero or one, or match minimally 
%                  {}    match a range of occurrances 
%                  []    set of characters 
%                  [^]   exclude a set of characters 
%                  ()    group subexpression 
%                  \w    match word [a-z_A-Z0-9] 
%                  \W    not a word [^a-z_A-Z0-9] 
%                  \d    match digit [0-9] 
%                  \D    not a digit [^0-9] 
%                  \s    match white space [ \t\r\n\f] 
%                  \S    not a white space [^ \t\r\n\f] 
%             <WORD\>    exact word match 
% 
%   Example 
%      str = 'My flowers may bloom in May'; 
%      pat = 'm\w*y'; 
%      regexpi(str, pat) 
%         returns [1 12 25] 
% 
%      which is a row vector of indices that match words that start with m, and 
%      end with y regardless of case. 
% 
%   When either STRING or EXPRESSION is a cell array of strings, REGEXPI returns 
%   an MxN cell array of row vectors of indices, where M is the the number of 
%   strings in STRING and N is the number of regular expression patterns in 
%   EXPRESSION. 
% 
%   [START,FINISH] = REGEXPI(STRING,EXPRESSION) returns an additional row 
%   vector, FINISH, which contains the indices of the last character of the 
%   corresponding substrings in START. 
% 
%   [START,FINISH,TOKENS] = REGEXPI(STRING,EXPRESSION) returns a 1xN cell array, 
%   TOKENS, of beginning and ending indices of tokens within the corresponding 
%   substrings in START and FINISH.  Tokens are denoted by parenthesis in 
%   EXPRESSION. 
% 
%   By default, REGEXPI returns all matches.  To find just the first match, use 
%   REGEXPI(STRING,EXPRESSION,'once'). If no matches are found then START, 
%   FINISH, and TOKENS are empty. 
% 
%   REGEXPI does not support international character sets. 
% 
%   See also REGEXP, REGEXPREP, STRCMPI, STRFIND, FINDSTR, STRMATCH. 
% 
 
% 
%   E. Mehran Mestchian 
%   J. Breslau 
%   Copyright 1984-2002 The MathWorks, Inc. 
%  $Revision: 1.5 $  $Date: 2002/04/09 00:33:35 $ 
% 