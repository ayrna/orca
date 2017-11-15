% Make file for MATLAB and OCTAVE that processes make() in all the subfolders 
% with C/C++ code. 
function make()
try
  cd libsvm-weights-3.12/matlab/
  make
  cd ../..
  cd libsvm-rank-2.81/matlab/
  make
	cd ../..
  cd SVOREX
  make
	cd ..
  cd SVORIM
  make
	cd ..
catch err
	fprintf('Error: %s failed (line %d)\n', err.stack(1).file, err.stack(1).line);
	disp(err.message);
	fprintf('=> Please check README for detailed instructions.\n');
end
