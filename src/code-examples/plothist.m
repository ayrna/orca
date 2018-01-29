function [retval] = plothist (A,bins,color)
    %plothist function to plot one or several histograms allowing transparency
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    %
[y1 x1] = hist(A,bins);

[ys1 xs1] = stairs(y1, x1);

xs1 = [xs1(1); xs1; xs1(end)]; 
ys1 = [0; ys1; 0];

hold on; 
h1=fill(xs1,ys1,color);

set(h1,'facealpha',0.6);

end
