classdef DataSubset < Dataset & matlab.mixin.CustomDisplay
    % A subset of a Dataset.
    %   Similar functionality to a Dataset except working with reduced
    %   ranges of the context parameters. For example, for a Dataset with a
    %   context parameter A such that 1 <= A <= 10, a DataSubset might have
    %   4 <= A <= 7.
    
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
        
    end
    
    methods (Access = protected)
        
        function params = getDesiredParameterValues(obj)
            % Get desired parameter values of DataSubset rather than
            % Dataset.
            params = obj.DesiredParameterValues;
        end
        
        function subjects = getDesiredSubjectValues(obj)
            % Get desired subject values of DataSubset rather than Dataset.
            subjects = obj.DesiredSubjectValues;
        end
        
        function values = getModelAdjustmentValues(obj)
            % Get values of the model parameter to use for adjustment.
            %   Extra logic compared to Dataset class; takes the
            %   intersection of the total model values and the subclass
            %   model parameter range.
            desired_values = obj.getDesiredParameterValues();
            model_values = desired_values{obj.ModelParameterIndex};
            values = intersect(obj.ModelAdjustmentValues, model_values);
        end
    
        function propgrp = getPropertyGroups(~)
            % Re-orders the property list of DataSubset objects.
            proplist = {'DatasetName', 'SubsetName', 'DesiredSubjectValues', ...
                'ContextParameters', 'DesiredParameterValues'};
            propgrp = matlab.mixin.util.PropertyGroup(proplist);
        end
    end
    
    methods (Access = private)
        
        function parsed_param_list = parseParameterList(obj, param_list)
            % Interpret user-provided parameter list.
            %   This function parses the name-value pairs of context parameter
            %   ranges provided by the user, and reformats them in to an 
            %   ordered cell array.
            if length(param_list) == 2 * obj.NContextParameters
                parsed_param_list = cell(1, obj.NContextParameters);
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
            obj.DesiredParameterValues = parsed_param_list;
        end 
    end
end

