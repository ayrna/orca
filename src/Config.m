classdef Config
    %Config Class to manage configuration files
    %   This class provides INI files loading to get a cell of CONFIGEXP objects 
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    %
    properties
        % Cell containing a Map of key, values to store experiments configuration
        iniFile;
        exps;
        keys;
        sections;
        subsections;
    end
    
    methods
        function obj = Config(confFile)
            %CONFIG Construct an instance of this class and parses CONFFILE
            obj = obj.parseconfig(confFile);
        end
    end
    
    methods (Access = private)
        
        function obj = parseconfig(obj,confFile)
            %PARSECONFIG parses INI file and returns a cell of ConfigExp.
            %Each ConfigExpt object corresponds to one experiment (a Section
            %in the INI file)
            try
                [obj.keys,obj.sections,obj.subsections] = inifile(confFile,'readall');
            catch ME
                error('Cannot read or parse %s. \nError: %s', confFile, ME.identifier)
            end
            
            if isempty(obj.keys) || isempty(obj.keys{1,1})
                error('File %s does not contain valid experiments descriptions', confFile)
            end
            obj.iniFile = confFile;
            obj.exps = cell(numel(obj.sections), 1);
            
            %for each section (experiment) build a mapObj
            for i=1:numel(obj.sections)
                % Extract keys for each experiment
                expKeys = obj.keys(strcmp(obj.keys(:, 1), obj.sections{i}), :);
                
                mapObjGeneral = containers.Map(expKeys(strcmp(expKeys(:, 2), 'general-conf'), 3), ...
                    expKeys(strcmp(expKeys(:, 2), 'general-conf'), 4));
                
                mapObjAlgorithm = containers.Map(expKeys(strcmp(expKeys(:, 2), 'algorithm-parameters'), 3), ...
                    expKeys(strcmp(expKeys(:, 2), 'algorithm-parameters'), 4));
                
                mapObjParametersOpt = containers.Map(expKeys(strcmp(expKeys(:, 2), 'algorithm-hyper-parameters-to-cv'), 3), ...
                    expKeys(strcmp(expKeys(:, 2), 'algorithm-hyper-parameters-to-cv'), 4));
                
                eObj = ConfigExp(obj.sections{i},expKeys, mapObjGeneral, mapObjAlgorithm, mapObjParametersOpt);
                
                obj.exps{i}=eObj;
            end
            
            
            %             % TODO
            %             if Config.validateconfig(exps)
            %                 return
            %             else
            %                 error('Invalid INI file %s', confFile)
            %             end
        end
    end
    
    methods(Static = true, Access = private)
        
        function valid = validateconfig(exps)
            %VALIDATECONFIG Validates set of experiments
            %TODO         
        end
    end
end
