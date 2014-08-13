function s = aesinit(key)
% AESINIT Generate structure with s-boxes, expanded key, etc.
% Usage:            s = aesinit([23 34 168 ... 39])
% key:              16 (AES-128), 24 (AES-192), and 32 (AES-256)
%                   items array with bytes of key
% s:                AES structure for AES parameters and tables

% Stepan Matejka, 2011, matejka[at]feld.cvut.cz
% $Revision: 1.1.0 $  $Date: 2011/10/12 $

validateattributes(key,...
    {'numeric'},...
    {'real', 'vector', '>=', 0, '<=', 255});

key = key(:);
lengthkey = length(key);

switch (lengthkey)
    case 16
        rounds = 10;
    case 24
        rounds = 12;
    case 32
        rounds = 14;
    otherwise
        error('Only AES-128, AES-192, and AES-256 are supported.');
end

% fill s structure
s = {};
s.key = key;
s.bytes = lengthkey;
s.length = lengthkey * 8;
s.rounds = rounds;
% irreducible polynomial for multiplication in a finite field 0x11b
% bin2dec('100011011');
s.mod_pol = 283;

% s-box method 1 (slow)
% ---------------------
    
%     % multiplicative inverse table
%     % first is zero, calculate rest
%     inverse = zeros(1,256);
%     for i = 2:256
%         inverse(i) = find_inverse(i - 1, s.mod_pol);
%     end
%     
%     % generate s-box
%     s_box = zeros(1,256);
%     for i = 1:256
%         % affine transformation
%         s_box(i) = aff_trans(inverse(i));
%     end
%     s.s_box = s_box;
%     
%     % generate inverse s-box
%     inv_s_box(s_box(1:256) + 1) = (1:256) - 1;
%     s.inv_s_box = inv_s_box;

% s-box method 2 (faster)
% -----------------------

% first build logarithm lookup table and it's inverse
aes_logt = zeros(1,256);
aes_ilogt = zeros(1,256);
gen = 1;
for i = 0:255
    aes_logt(gen + 1) = i;
    aes_ilogt(i + 1) = gen;
    gen = poly_mult(gen, 3, s.mod_pol);
end
% store log tables
s.aes_logt = aes_logt;
s.aes_ilogt = aes_ilogt;
% build s-box and it's inverse
s_box = zeros(1,256);
loctable = [1 2 4 8 16 32 64 128 1 2 4 8 16 32 64 128];
for i = 0:255
    if (i == 0)
        inv = 0;
    else
        inv = aes_ilogt(255 - aes_logt(i + 1) + 1);
    end
    temp = 0;
    for bi = 0:7
        temp2 = sign(bitand(inv, loctable(bi + 1)));
        temp2 = temp2 + sign(bitand(inv, loctable(bi + 4 + 1)));
        temp2 = temp2 + sign(bitand(inv, loctable(bi + 5 + 1)));
        temp2 = temp2 + sign(bitand(inv, loctable(bi + 6 + 1)));
        temp2 = temp2 + sign(bitand(inv, loctable(bi + 7 + 1)));
        temp2 = temp2 + sign(bitand(99, loctable(bi + 1)));
        if (rem(temp2,2))
            temp = bitor(temp, loctable(bi + 1));
        end
    end
    s_box(i + 1) = temp;
end
inv_s_box(s_box(1:256) + 1) = (0:255);
% table correction (must be)
s_box(1 + 1) = 124;
inv_s_box(124 + 1) = 1;
inv_s_box(99 + 1) = 0;
s.s_box = s_box;
s.inv_s_box = inv_s_box;

% tables for fast MixColumns
mix_col2 = zeros(1,256);
mix_col3 = mix_col2;
mix_col9 = mix_col2;
mix_col11 = mix_col2;
mix_col13 = mix_col2;
mix_col14 = mix_col2;
for i = 1:256
    mix_col2(i) = poly_mult(2, i - 1, s.mod_pol);
    mix_col3(i) = poly_mult(3, i - 1, s.mod_pol);
    mix_col9(i) = poly_mult(9, i - 1, s.mod_pol);
    mix_col11(i) = poly_mult(11, i - 1, s.mod_pol);
    mix_col13(i) = poly_mult(13, i - 1, s.mod_pol);
    mix_col14(i) = poly_mult(14, i - 1, s.mod_pol);
end
s.mix_col2 = mix_col2;
s.mix_col3 = mix_col3;
s.mix_col9 = mix_col9;
s.mix_col11 = mix_col11;
s.mix_col13 = mix_col13;
s.mix_col14 = mix_col14;

% expanded key
s.keyexp = key_expansion(s.key, s.s_box, s.rounds, s.mod_pol, s.aes_logt, s.aes_ilogt);

% poly & invpoly
s.poly_mat = [...
    2 3 1 1;...
    1 2 3 1;...
    1 1 2 3;...
    3 1 1 2];

s.inv_poly_mat =[...
    14 11 13  9;...
    9  14 11 13;...
    13  9 14 11;...
    11 13  9 14];

% end of aesinit.m
% ------------------------------------------------------------------------

function p = poly_mult(a, b, mod_pol)
% Multiplication in a finite field
% For loop multiplication - slower than log/ilog tables
% but must be used for log/ilog tables generation

p = 0;
for counter = 1 : 8
    if (rem(b, 2))
        p = bitxor(p, a);
        b = (b - 1)/2;
    else
        b = b/2;
    end
    a = 2*a;
    if (a > 255)
        a = bitxor(a, mod_pol);
    end
end

% ------------------------------------------------------------------------
function inv = find_inverse(in, mod_pol)
% Multiplicative inverse for an element a of a finite field
% very bad calculate & test method
% Not used in faster version

% loop over all possible bytes
for inv = 1 : 255
    % calculate polynomial multiplication and test to be 1
    if (1 == poly_mult(in, inv, mod_pol))
        % we find it
        break
    end
end
inv = 0;

% ------------------------------------------------------------------------
function out = aff_trans(in)
% Affine transformation over GF(2^8)
% Not used for faster s-box generation

% modulo polynomial for multiplication in a finite field
% bin2dec('100000001');
mod_pol = 257;

% multiplication polynomial
% bin2dec('00011111');
mult_pol = 31;

% addition polynomial
% bin2dec('01100011');
add_pol = 99;

% polynomial multiplication
temp = poly_mult(in, mult_pol, mod_pol);

% xor with addition polynomial
out = bitxor(temp, add_pol);

% ------------------------------------------------------------------------
function expkey = key_expansion(key, s_box, rounds, mod_pol, aes_logt, aes_ilogt)
% Expansion of key

% This is old version for AES-128 (192?, 256? not tested):
% rcon = ones(1,rounds);
% for i = 2:rounds
%     rcon(i) = poly_mult(rcon(i - 1), 2, mod_pol);
% end
% % fill bytes 2, 3, and 4 by 0
% rcon = [rcon(:), zeros(rounds, 3)];
% 
% kcol = length(key)/4;
% expkey = (reshape(key, kcol, 4))';
% for i = (kcol + 1):(4*rounds + 4)
%     % copy the previous row of the expanded key into a buffer
%     temp = expkey(i - 1, :);
%     % each fourth row
%     if (mod(i, 4) == 1)
%         % shift temp
%         temp = temp([2 3 4 1]);
%         % s-box transform
%         temp = s_box(temp + 1);
%         % compute the current round constant
%         r = rcon((i - 1)/4, :);
%         % xor
%         temp = bitxor(temp, r);
%     else
%         if ((kcol > 6) && (mod(i, kcol) == 0))
%             temp = s_box(temp);
%         end
%     end
%     % generate new row of the expanded key
%     expkey(i, :) = bitxor(expkey(i - 4, :), temp);
% end

% This is new faster version for all AES:
rcon = 1;
kcol = length(key)/4;
expkey = (reshape(key,4,kcol))';
% traverse for all rounds
for i = kcol:(4*(rounds + 1) - 1)
    % copy the previous row of the expanded key into a buffer
    temp = expkey(i, :);
    % each kcol row
    if (mod(i, kcol) == 0)
        % rotate word
        temp = temp([2 3 4 1]);
        % s-box transform
        temp = s_box(temp + 1);
        % xor
        temp(1) = bitxor(temp(1), rcon);
        % new rcon
        % 1. classic poly_mult
        % rcon = poly_mult(rcon, 2, mod_pol);
        % 2. or faster version with log/ilog tables
        % note rcon is never zero here
        % rcon = aes_ilogt(mod((aes_logt(rcon + 1) + aes_logt(2 + 1)), 255) + 1);
        rcon = aes_ilogt(mod((aes_logt(rcon + 1) + 25), 255) + 1);
    else
        if ((kcol > 6) && (mod(i, kcol) == 4))
            temp = s_box(temp + 1);
        end
    end
    % generate new row of the expanded key
    expkey(i + 1, :) = bitxor(expkey(i - kcol + 1, :), temp);
end

% ------------------------------------------------------------------------
% end of file
