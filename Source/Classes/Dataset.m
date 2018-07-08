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
        
    end
    
end