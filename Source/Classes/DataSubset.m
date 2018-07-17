classdef DataSubset < Dataset & matlab.mixin.CustomDisplay
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        SubsetName
        DesiredSubjectValues
        DesiredParameterValues
    end
    
    methods
        function obj = DataSubset(...
                root, name, subjects, varargin)
            obj@Dataset(root);
            obj.SubsetName = name;
            obj.DesiredSubjectValues = subjects;
            obj.parseParameterList(varargin);
        end
        
        function parsed_param_list = parseParameterList(obj, param_list)
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
            obj.DesiredParameterValues = parsed_param_list;
        end
    end
    
    methods (Access = protected)
        function propgrp = getPropertyGroups(~)
            proplist = {'DatasetName', 'SubsetName', 'DesiredSubjectValues', ...
                'ContextParameters', 'DesiredParameterValues'};
            propgrp = matlab.mixin.util.PropertyGroup(proplist);
        end
    end
end

