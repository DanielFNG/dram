classdef Dataset < handle
   
    properties (SetAccess = private)
        SubsetName
        DatasetName
        ContextParameters
        ParameterValues
    end
    
    properties (GetAccess = private, SetAccess = private)
        SubjectPrefix
        DataFolderName
        ModelFolderName
        NContextParameters
        ModelParameter                                                
        ModelMap
        DesiredParameters
    end
    
    methods
        
        % Desired parameters should either be a cell array of length 
        % obj.NContextParameters, where each element is a vector of parameters 
        % to go through, or a set of name-value pairs providing the same
        % information.  
        function obj = Dataset(name, root, desired_parameters)
            if nargin > 0
                obj.SubsetName = name;
                obj.parseDatasetDescriptor(root);
                obj.DesiredParameters = desired_parameters;
            end
        end
        
        % Construct the path to the raw data files for a certain combination
        % of context parameters. The input argument(s) should either be a 
        % vector of ordered values corresponding to the context parameters, or 
        % a list of name-value pairs.
        function path = constructDataPath(obj, root, subject, varargin)
        
            % Parse the parameter list and create an ordered list of parameter 
            % values.
            if length(varargin) == 1
                if length(varargin{1}) ~= obj.NContextParameters
                    error(['The number of parameter values given to ' ...
                        'constructDataPath does not match the number of ' ...
                        'context parameters in this Dataset.']);
                else
                    param_values = varargin{1}; 
                end
            elseif length(varargin) == 2 * obj.NContextParameters
                param_values = zeros(obj.NContextParameters, 1);
                for i=1:2:2 * obj.NContextParameters - 1
                    if ~strcmp(obj.ContextParameters, varargin{i})
                        error('Context parameter name not recognised.');
                    else
                        param_values(strcmp(obj.ContextParameters, ...
                            varargin{i})) = varargin{i + 1};
                    end
                end
            else
                error(['The number of parameter values given to ' ...
                        'constructDataPath does not match the number of ' ...
                        'context parameters in this Dataset.']);
            end
            
            % Create the path to the appropriate data folder. 
            param_path = [];
            for i=1:obj.NContextParameters
                param_path = [param_path obj.ContextParameters{i} ...
                    num2str(param_values(i))]; %#ok<*AGROW>
            end
            path = [root filesep obj.SubjectPrefix num2str(subject) ...
                filesep obj.DataFolderName filesep param_path];
        end
        
        % This serves a similar purpose to constructDataPath, however this 
        % results in an exact path to a model file. Additionally, this function
        % must take in to account only the ModelParameter in order to identify 
        % the correct model file, therefore the input mvalue must be an 
        % integer. 
        function path = constructModelPath(obj, root, subject, mvalue)
        end
    
        function parseDatasetDescriptor(obj, root)

            % Parse the DatasetDescriptor file.
            xml_data = xmlread([root filesep 'DatasetDescriptor.xml']);

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
            parameter_names = cell(context_info.n_context_parameters, 1);
            for i=0:context_info.n_context_parameters - 1
                parameter_names{i + 1} = ...
                    strtrim(char(parameters.item(i). ...
                    getElementsByTagName('Name'). ...
                    item(0).item(0).getData()));
            end
            obj.ContextParameters = parameter_names;
            obj.ModelParameter = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'ModelParameter').item(0).item(0).getData()));
    
            % Get the model set data.
            model_set = xml_data.getElementsByTagName('Model');
            obj.NModels = model_set.getLength();
            model_names = cell(model_info.n_models, 1);
            model_indices = cell(model_info.n_models, 1);
            k = 1;
            for i=0:model_info.n_models - 1
                model_names{i + 1} = strtrim(char(model_set.item(i). ...
                    getElementsByTagName('Name').item(0).item(0).getData()));
                model_indices{i + 1} = str2num(strtrim(char(...
                    model_set.item(i).getElementsByTagName(...
                    'ParameterValues').item(0).item(0).getData()))); %#ok<ST2NM>
                for j=1:length(model_indices{i+1})
                    map_key{k} = model_indices{i + 1}(j);
                    map_value{k} = model_names{i + 1};
                    k = k + 1;
                end
            end
            obj.ModelMap = containers.Map(map_key, map_value);
        end
    
    end
    
end