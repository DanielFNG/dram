classdef DynamicDataSubset < Dataset
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SubsetName
        SubjectValues
        ContextParameterValues
    end
    
    methods
        function obj = DynamicDataSubset(...
                root, name, subjects, varargin)
            obj@Dataset(root);
            obj.SubsetName = name;
            obj.SubjectValues = subjects;
            obj.parseParameterList(varargin);
        end
        
        function parseParameterList(obj, param_list)
            n_params = obj.getNContextParameters();
            if length(param_list) == 2 * n_params
                parsed_param_list = cell(1, n_params);
                for i=1:2:2 * n_params - 1
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
            obj.ContextParameterValues = parsed_param_list;
        end
    end
end

