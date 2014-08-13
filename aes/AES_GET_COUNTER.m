function [out] = AES_GET_COUNTER(i)
% AES_GET_COUNTER Generates counter for aes.m - an example.
% Example function implemented to simulate counter for aestest.
% Change this function to correspond to your requirements.
% i:           counter call number; 1, 2, 3,...
% out:         counter value for given counter call

% Stepan Matejka, 2011, matejka[at]feld.cvut.cz
% $Revision: 1.1.0 $  $Date: 2011/10/12 $

counterh = {'f0' 'f1' 'f2' 'f3' 'f4' 'f5' 'f6' 'f7'...
    'f8' 'f9' 'fa' 'fb' 'fc' 'fd' 'fe' 'ff'};
counter = hex2dec(counterh);

switch (i)
    case 1
        out = counter;
    case 2
        counter(15:16) = [255 0];
        out = counter;
    case 3
        counter(15:16) = [255 1];
        out = counter;
    case 4
        counter(15:16) = [255 2];
        out = counter;
    otherwise
        error('Index out of bounds.');
end

% ------------------------------------------------------------------------
% end of file
