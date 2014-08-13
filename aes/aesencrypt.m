function [out] = aesencrypt(s, in)
% AESENCRYPT  Encrypt 16-bytes vector.
% Usage:            out = aesencrypt(s, in)
% s:                AES structure
% in:               input 16-bytes vector (plaintext)
% out:              output 16-bytes vector (ciphertext)

% Stepan Matejka, 2011, matejka[at]feld.cvut.cz
% $Revision: 1.1.0 $  $Date: 2011/10/12 $

if (nargin ~= 2)
    error('Bad number of input arguments.');
end

validateattributes(s, {'struct'}, {});
validateattributes(in, {'numeric'}, {'real', 'vector', '>=', 0, '<', 256});

% copy input to local
% 16 -> 4 x 4
state = reshape(in, 4, 4);

% Initial round
% AddRoundKey keyexp(1:4)
state = bitxor(state, (s.keyexp(1:4, :))');

% Loop over (s.rounds - 1) rounds
for i = 1:(s.rounds - 1)
    % SubBytes - lookup table
    state = s.s_box(state + 1);
    % ShiftRows
    state = shift_rows(state, 0);
    % MixColumns
    state = mix_columns(state, s);
    % AddRoundKey keyexp(i*4 + (1:4))
    state = bitxor(state, (s.keyexp((1:4) + 4*i, :))');
end

% Final round
% SubBytes - lookup table
state = s.s_box(state + 1);
% ShiftRows
state = shift_rows(state, 0);
% AddRoundKey keyexp(4*s.rounds + (1:4))
state = bitxor(state, (s.keyexp(4*s.rounds + (1:4), :))');

% copy local to output
% 4 x 4 -> 16
out = reshape(state, 1, 16);

% ------------------------------------------------------------------------
function out = mix_columns(in, s)
% Each column of the state is multiplied with a fixed polynomial mod_pol

% Slow version
% out = zeros(size(in));
% for col = 1:4
%     for row = 1:4
%         % for each element
%         temp = 0;
%         for i = 1:4
%             % Multiplication in a finite field of
%             % row vector of poly_mat and
%             % column vector of the in
%             % finally xor
%             temp = bitxor(temp,...
%                 poly_mult(s.poly_mat(row, i),...
%                 in(i, col),...
%                 s.mod_pol, s.aes_logt,s.aes_ilogt));
%         end
%         % place to out
%         out(row, col) = temp;
%     end
% end

% Faster implementation
% out = zeros(size(in));
% for col = 1:4
%     temp = bitxor(in(3,col),in(4,col));
%     temp = bitxor(temp, poly_mult(2,in(1,col),s.mod_pol,s.aes_logt,s.aes_ilogt));
%     out(1,col) = bitxor(temp, poly_mult(3,in(2,col),s.mod_pol,s.aes_logt,s.aes_ilogt));
%     temp = bitxor(in(1,col),in(4,col));
%     temp = bitxor(temp, poly_mult(2,in(2,col),s.mod_pol,s.aes_logt,s.aes_ilogt));
%     out(2,col) = bitxor(temp, poly_mult(3,in(3,col),s.mod_pol,s.aes_logt,s.aes_ilogt));
%     temp = bitxor(in(1,col),in(2,col));
%     temp = bitxor(temp, poly_mult(2,in(3,col),s.mod_pol,s.aes_logt,s.aes_ilogt));
%     out(3,col) = bitxor(temp, poly_mult(3,in(4,col),s.mod_pol,s.aes_logt,s.aes_ilogt));
%     temp = bitxor(in(2,col),in(3,col));
%     temp = bitxor(temp, poly_mult(3,in(1,col),s.mod_pol,s.aes_logt,s.aes_ilogt));
%     out(4,col) = bitxor(temp, poly_mult(2,in(4,col),s.mod_pol,s.aes_logt,s.aes_ilogt));
% end

% Faster faster implementation
% out = zeros(size(in));
% for col = 1:4
%     temp = bitxor(in(3,col),in(4,col));
%     temp = bitxor(temp, s.mix_col2(in(1,col) + 1));
%     out(1,col) = bitxor(temp, s.mix_col3(in(2,col) + 1));
%     temp = bitxor(in(1,col),in(4,col));
%     temp = bitxor(temp, s.mix_col2(in(2,col) + 1));
%     out(2,col) = bitxor(temp, s.mix_col3(in(3,col) + 1));
%     temp = bitxor(in(1,col),in(2,col));
%     temp = bitxor(temp, s.mix_col2(in(3,col) + 1));
%     out(3,col) = bitxor(temp, s.mix_col3(in(4,col) + 1));
%     temp = bitxor(in(2,col),in(3,col));
%     temp = bitxor(temp, s.mix_col3(in(1,col) + 1));
%     out(4,col) = bitxor(temp, s.mix_col2(in(4,col) + 1));
% end

% Faster faster faster implementation
% slice1 = zeros(4,4);
% slice2 = slice1;
% slice3 = slice1;
% slice4 = slice1;
% for col = 1:4
%     slice1(1,col) = in(3,col);
%     slice2(1,col) = in(4,col);
%     slice3(1,col) = s.mix_col2(in(1,col) + 1);
%     slice4(1,col) = s.mix_col3(in(2,col) + 1);
%     slice1(2,col) = in(1,col);
%     slice2(2,col) = in(4,col);
%     slice3(2,col) = s.mix_col2(in(2,col) + 1);
%     slice4(2,col) = s.mix_col3(in(3,col) + 1);
%     slice1(3,col) = in(1,col);
%     slice2(3,col) = in(2,col);
%     slice3(3,col) = s.mix_col2(in(3,col) + 1);
%     slice4(3,col) = s.mix_col3(in(4,col) + 1);
%     slice1(4,col) = in(2,col);
%     slice2(4,col) = in(3,col);
%     slice3(4,col) = s.mix_col3(in(1,col) + 1);
%     slice4(4,col) = s.mix_col2(in(4,col) + 1);
% end
% out = bitxor(bitxor(bitxor(slice1, slice2), slice3), slice4);

% Faster faster faster faster implementation
out = bitxor(bitxor(bitxor([in(3,1:4); in(1,1:4); in(1,1:4); in(2,1:4)],...
    [in(4,1:4); in(4,1:4); in(2,1:4); in(3,1:4)]),...
    [s.mix_col2(in(1,1:4) + 1); s.mix_col2(in(2,1:4) + 1); s.mix_col2(in(3,1:4) + 1); s.mix_col3(in(1,1:4) + 1)]),...
    [s.mix_col3(in(2,1:4) + 1); s.mix_col3(in(3,1:4) + 1); s.mix_col3(in(4,1:4) + 1); s.mix_col2(in(4,1:4) + 1)]);

% ------------------------------------------------------------------------
function p = poly_mult(a, b, mod_pol, aes_logt, aes_ilogt)
% Multiplication in a finite field

% Old slow implementation
% p = 0;
% for counter = 1:8
%     if (rem(b,2))
%         p = bitxor(p,a);
%         b = (b - 1)/2;
%     else
%         b = b/2;
%     end
%     a = 2*a;
%     if (a>255)
%         a = bitxor(a,mod_pol);
%     end
% end

% Faster implementaion
if (a && b)
    p = aes_ilogt(mod((aes_logt(a + 1) + aes_logt(b + 1)), 255) + 1);
else
    p = 0;
end

% ------------------------------------------------------------------------
function out = shift_rows(in, dir)
% ShiftRows cyclically shift the rows of the 4 x 4 matrix.
%
%   dir = 0 (to left)
%  | 1 2 3 4 |
%  | 2 3 4 1 |
%  | 3 4 1 2 |
%  | 4 1 2 3 |
%
%   dir ~= 0 (to right)
%  | 1 2 3 4 |
%  | 4 1 2 3 |
%  | 3 4 1 2 |
%  | 2 3 4 1 |
%

if (dir == 0)
    % left
    % use linear indexing in 2d array
    out = reshape(in([1 6 11 16 5 10 15 4 9 14 3 8 13 2 7 12]),4,4);
    % old safe method
%     temp = reshape(in,16,1);
%     temp = temp([1 6 11 16 5 10 15 4 9 14 3 8 13 2 7 12]);
%     out = reshape(temp,4,4);
else
    % right
    % use linear indexing in 2d array
    out = reshape(in([1 14 11 8 5 2 15 12 9 6 3 16 13 10 7 4]),4,4);
    % old safe method
%     temp = reshape(in,16,1);
%     temp = temp([1 14 11 8 5 2 15 12 9 6 3 16 13 10 7 4]);
%     out = reshape(temp,4,4);
end

% ------------------------------------------------------------------------
% end of file
