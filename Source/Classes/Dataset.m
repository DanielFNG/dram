classdef Dataset < handle
   
    properties (SetAccess = private)
        DatasetName
        ContextParameters
        ModelParameter
        SubsetName
        DesiredSubjects
        DesiredParameters
    end
    
    properties % (GetAccess = private, SetAccess = private)
        SubjectPrefix
        DataFolderName
        ModelFolderName
        NContextParameters
        ModelParameterIndex
        AdjustmentSuffix
        NModels
        ModelMap
        LoadMap
        SubsetRoot
    end
    
    methods
        
        % The varargin entry should represent a desired parameter list,
        % provided as a set of name-value pairs i.e. the name of a
        % parameter followed by a vector of values which that parameter
        % should take within this dataset. 
        function obj = Dataset(name, root, subjects, varargin)
            if nargin > 0
                obj.SubsetName = name;
                obj.SubsetRoot = root;
                obj.parseDatasetDescriptor();
                obj.DesiredSubjects = subjects;
                obj.DesiredParameters = containers.Map(...
                    obj.ContextParameters, obj.parseParameterList(varargin));
                obj.ModelParameterIndex = find(strcmp(obj.ContextParameters, ...
                    obj.ModelParameter));
            end
        end
    
        function parseDatasetDescriptor(obj)

            % Parse the DatasetDescriptor file.
            xml_data = xmlread([obj.SubsetRoot filesep ...
                'DatasetDescriptor.xml']);

            % Get the dataset name.
            obj.DatasetName = strtrim(char(...
                xml_data.getElementsByTagName('Name').item(0). ...
                    item(0).getData()));

            % Get the descriptor strings. 
            obj.SubjectPrefix = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'SubjectPrefix').item(0).item(0).getData()));
            obj.DataFolderName = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'DataFolderName').item(0).item(0).getData()));
            obj.ModelFolderName = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'ModelFolderName').item(0).item(0).getData()));

            % Get the context parameter data.
            parameters = xml_data.getElementsByTagName('Parameter');
            obj.NContextParameters = parameters.getLength();
            parameter_names = cell(obj.NContextParameters, 1);
            for i=0:obj.NContextParameters - 1
                parameter_names{i + 1} = ...
                    strtrim(char(parameters.item(i). ...
                    getElementsByTagName('Name'). ...
                    item(0).item(0).getData()));
            end
            obj.ContextParameters = parameter_names;
            obj.ModelParameter = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'ModelParameter').item(0).item(0).getData()));
            obj.AdjustmentSuffix = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'AdjustmentSuffix').item(0).item(0).getData()));
    
            % Get the model set data.
            model_set = xml_data.getElementsByTagName('Model');
            obj.NModels = model_set.getLength();
            model_names = cell(obj.NModels, 1);
            model_loads = cell(obj.NModels, 1);
            model_indices = cell(obj.NModels, 1);
            k = 1;
            for i=0:obj.NModels - 1
                model_names{i + 1} = strtrim(char(model_set.item(i). ...
                    getElementsByTagName('Name').item(0).item(0).getData()));
                model_loads{i + 1} = strtrim(char(model_set.item(i). ...
                    getElementsByTagName('Load').item(0).item(0).getData()));
                model_indices{i + 1} = str2num(strtrim(char(...
                    model_set.item(i).getElementsByTagName(...
                    'ParameterValues').item(0).item(0).getData()))); %#ok<ST2NM>
                for j=1:length(model_indices{i+1})
                    map_key{k} = model_indices{i + 1}(j);
                    map_value{k} = model_names{i + 1};
                    load_map_value{k} = model_loads{i + 1};
                    k = k + 1;
                end
            end
            obj.ModelMap = containers.Map(map_key, map_value);
            obj.LoadMap = containers.Map(map_key, load_map_value);
        end
        
        function parsed_param_list = parseParameterList(obj, param_list)
            if length(param_list) == 2 * obj.NContextParameters
                parsed_param_list = cell(obj.NContextParameters, 1);
                for i=1:2:2 * obj.NContextParameters - 1
                    if ~strcmp(obj.ContextParameters, param_list{i})
                        error('Context parameter name not recognised.');
                    else
                        parsed_param_list{strcmp(obj.ContextParameters, ...
                            param_list{i})} = param_list{i + 1};
                    end
                end
            else
                error(['The number of parameter values given ' ...
                    'does not match the number of ' ...
                    'context parameters in this Dataset.']);
            end
        end
        
    end
    
    methods %(Access = private)
        
        % Construct the path to the raw data files for a certain combination
        % of context parameters. The input argument should be an ordered
        % vector of context parameter values.
        function path = constructRawDataPath(obj, subject, parameters)
            
            % Create the parameter string.
            name = [];
            for i=1:obj.NContextParameters
                name = [name obj.ContextParameters{i} ...
                    num2str(parameters(i)) filesep]; %#ok<*AGROW>
            end
            
            % Create the path to the appropriate data folder.
            path = [obj.SubsetRoot filesep obj.SubjectPrefix ...
                num2str(subject) filesep obj.DataFolderName filesep ...
                name];
        end
        
        % This serves a similar purpose to constructDataPath, however this
        % results in an exact path to a model file. This accepts a full
        % list of parameter values but simply checks the value of the
        % ModelParameter.
        function path = constructModelPath(obj, subject, parameters)
            
            % Create the path to the appropriate model. 
            path = [obj.SubsetRoot filesep obj.SubjectPrefix ...
                num2str(subject) filesep obj.ModelFolderName filesep ...
                obj.ModelMap(parameters(obj.ModelParameterIndex))];
            
        end
        
        function path = constructAdjustedModelPath(obj, subject, parameters)
            
            % Create the path to the appropriate model. 
            [path, name, ext] = ...
                fileparts(obj.constructModelPath(subject, parameters));
            path = [path filesep name obj.AdjustmentSuffix ext];
        end
        
        function path = constructKinematicDataPath(...
                obj, mode, subject, parameters)
            if strcmp(mode, 'RRA')
                if obj.ComputedRRA
                    folder = 'RRA_Results';
                else
                    error('RRA has not been computed for this dataset.');
                end
            elseif strcmp(mode, 'IK')
                if obj.ComputedIK
                    folder = 'IK_Results';
                else
                    error('IK has not been computed for this dataset.');
                end
            else
                error('Mode not recognised.');
            end
            path = ...
                [obj.constructRawDataPath(subject, parameters) filesep folder];
        end
        
    end
    
    
    
end