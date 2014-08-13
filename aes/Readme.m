% AES-128, AES-192, and AES-256 encryption/decription functions.
% Download up-to-date version from
% http://radio.feld.cvut.cz/personal/matejka/wiki/doku.php?id=root:en:projects
% Stepan Matejka, 2011, matejka[at]feld.cvut.cz
% $Revision: 1.1.0 $  $Date: 2011/11/20 $
%
% Files:
% High level functions:
%   aesinit         - Generate structure with s-boxes, expanded key, etc.
%   aes             - Encrypt/decrypt array of bytes by AES.
%   aesinfo         - Display info about AES setting in AES structure.
% Low level 4x4 block functions:
%   aesdecrypt      - Decrypt 16-bytes vector.
%   aesencrypt      - Encrypt 16-bytes vector.
% Test functions:
%   aestest         - AES test script.
%   AES_GET_COUNTER - Generates counter for aes.m - an example.
