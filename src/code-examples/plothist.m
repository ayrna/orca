## Copyright (C) 2018 Javier Sánchez
## 
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*- 
## @deftypefn {Function File} {@var{retval} =} plothist (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: Javier Sánchez jsanchez at uco.es
## Created: 2018-01-25

function [retval] = plothist (A,bins,color)
[y1 x1] = hist(A,bins);

[ys1 xs1] = stairs(y1, x1);

xs1 = [xs1(1); xs1; xs1(end)]; 
ys1 = [0; ys1; 0];

hold on; 
h1=fill(xs1,ys1,color);

set(h1,'facealpha',0.6);

endfunction
