classdef Dataset < handle
   
    properties (SetAccess = private)
        Name
        ContextParameters
    end
    
    properties (GetAccess = private, SetAccess = private)
        SubjectPrefix
        DataFolderName
        ModelFolderName
        NContextParameters
        ModelParameter
        ModelParameterIndex
        NModels
        ModelNames
        ModelIndices
    end
    
    methods
       
        function obj = Dataset(name, strings, contexts, models)
            if nargin > 0
                obj.Name = name;
                obj.SubjectPrefix = strings.subject_prefix;
                obj.DataFolderName = strings.data_folder;
                obj.ModelFolderName = strings.model_folder;
                obj.NContextParameters = contexts.n_context_parameters;
                obj.ContextParameters = contexts.parameter_names;
                obj.ModelParameter = contexts.model_parameter;                 
                obj.ModelParameterIndex = find(strcmp(...
                    obj.ContextParameters, obj.ModelParameter));
                obj.NModels = models.n_models;
                obj.ModelNames = models.model_names;
                obj.ModelIndices = models.model_indices;
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
                if length(varargin{1} ~= obj.NContextParameters)
                    error(['The number of parameter values given to ' ...
                        'constructDataPath does not match the number of ' ...
                        'context parameters in this Dataset.']);
                else
                    param_values = varargin{1}; 
                end
            elseif length(varargin) == 2 * obj.NContextParameters
                param_values = zeros(obj.NContextParameters, 1);
                for i=1:2:2 * obj.NContextParameters - 1
                    if ~find(strcmp(obj.ContextParameters, varargin{i}))
                        error('Context parameter name not recognised.');
                    else
                        param_values(find(strcmp(obj.ContextParameters, ...
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
                    num2str(param_values(i))];
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

            
        end
        
    end
    
end