classdef ConfigExp
    %CONFIGEXP Configuration of an experiment.
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    %
    properties
        expId
        keys%cell
        general%containers.Map
        algorithm%containers.Map
        params%containers.Map
    end
    
    methods
        function obj = ConfigExp(id, k,g,a,p)
            obj.expId = id;
            obj.keys = k;
            obj.general = g;
            obj.algorithm = a;
            obj.params = p;
        end
        
        function obj = writeIni(obj,outFile)
            %Write object to an INI file especified by OUTFILE.
            
            idAsCell = cell(1,1);
            idAsCell{1,1} = obj.expId;
            
            genAsCell = cell(1,1);
            genAsCell{1,1} = 'general-conf';
            
            algAsCell = cell(1,1);
            algAsCell{1,1} = 'algorithm-parameters';
            
            parmAsCell = cell(1,1);
            parmAsCell{1,1} = 'algorithm-hyper-parameters-to-cv';
            
            
            keysGeneral = [repmat(idAsCell, obj.general.Count, 1) ...
                repmat(genAsCell, obj.general.Count, 1)...
                obj.general.keys' obj.general.values'];
            
            keysAlgorithm = [repmat(idAsCell, obj.algorithm.Count, 1) ...
                repmat(algAsCell, obj.algorithm.Count, 1)...
                obj.algorithm.keys' obj.algorithm.values'];
            
            if ~isempty(obj.params)
                paramAlgorithm = [repmat(idAsCell, obj.params.Count, 1) ...
                    repmat(parmAsCell, obj.params.Count, 1)...
                    obj.params.keys' obj.params.values'];
                writeKeys = [keysGeneral ; keysAlgorithm ; paramAlgorithm];
            else
                writeKeys = [keysGeneral ; keysAlgorithm];
            end
            
            inifile(outFile,'write',writeKeys,'plain');
            
        end
    end
end

