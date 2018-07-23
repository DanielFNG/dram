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
        
        % Interpet user-provided parameter list. 
        %   This function parses the name-value pairs of context parameter
        %   ranges provided by the user, and reformats them in to an ordered
        %   cell array.  
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
        
        %% These methods replace corresponding methods of the Dataset class.
        
        function params = getDesiredParameterValues(obj)
            params = obj.DesiredParameterValues;
        end
        
        function subjects = getDesiredSubjectValues(obj)
            subjects = obj.DesiredSubjectValues;
        end
        
        % Gets the values of the model parameter to be used for RRA adjustment.
        %   Note the extra logic compared to the dataset class; takes the 
        %   intersection of the total Dataset model values and the subclass 
        %   model parameter range.
        function adj_mod_values = getModelAdjustmentValues(obj)
            desired_values = obj.getDesiredParameterValues();
            model_values = desired_values{obj.getModelParameterIndex()};
            adj_mod_values = intersect(obj.ModelAdjustmentValues, model_values);
        end
    end
    
    %% Special methods. 
    methods (Access = protected)
    
        % Re-orders the property list of DataSubset objects.
        function propgrp = getPropertyGroups(~)
            proplist = {'DatasetName', 'SubsetName', 'DesiredSubjectValues', ...
                'ContextParameters', 'DesiredParameterValues'};
            propgrp = matlab.mixin.util.PropertyGroup(proplist);
        end
    end
end

