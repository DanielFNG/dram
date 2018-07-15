classdef DatasetElement < handle 

    properties (SetAccess = private)
        ParentDataset
        Subject
        ParameterValues
        IKComputed = false
        AdjustmentRRAComputed = false
        RRAComputed = false
        BodyKinematicsComputed = false
        IDComputed = false
        CMCComputed = false 
    end
    
    properties (SetAccess = private, GetAccess = private)
        DataFolderPath
        ModelFolderPath
        ModelPath
        AdjustedModelPath
        RawDataPath
        IKDataPath
        RRADataPath
    end
    
    methods

        function obj = DatasetElement(dataset, subject, parameters)
            obj.ParentDataset = dataset;
            obj.Subject = subject;
            obj.ParameterValues = parameters;
            obj.DataFolderPath = dataset.getDataFolderPath(subject);
            obj.ModelFolderPath = dataset.getModelFolderPath(subject);
            obj.constructRawDataPath();
            obj.constructModelPath();
        end
        
        function constructRawDataPath(obj)
            
            % Create the parameter string.
            name = [];
            for i=1:obj.ParentDataset.NContextParameters
                name = [name obj.ParentDataset.ContextParameters{i} ...
                    num2str(obj.ParameterValues(i)) filesep]; %#ok<*AGROW>
            end
            
            % Create the path to the appropriate data folder.
            obj.RawDataPath = [obj.DataFolderPath filesep name];
        end
        
        % This serves a similar purpose to constructDataPath, however this
        % results in an exact path to a model file. This accepts a full
        % list of parameter values but simply checks the value of the
        % ModelParameter.
        function constructModelPath(obj)
            
            % Create the path to the appropriate model. 
            obj.ModelPath = [obj.ModelFolderName filesep...
                obj.ParentDataset.getModelName(obj)];
            
        end
        
        function constructAdjustedModelPath(obj)
            
            % Create the path to the appropriate model. 
            [path, name, ext] = fileparts(obj.ModelPath);
            obj.AdjustedModelPath = ...
                [path filesep name obj.AdjustmentSuffix ext];
        end
    
        function prepareBatchIK(obj)
        
            output_dir = [obj.RawDataPath filesep ...
                obj.ParentDataset.IKDirectory];
            runBatchIK(obj.ModelPath, obj.RawDataPath, output_dir);
            obj.IKDataPath = output_dur;
            obj.IKComputed = true;
        end
        
        function prepareAdjustmentRRA(obj)
            
            if ~obj.IKComputed
                error('IK must be performed before doing RRA analyses.');
            end
            
            % Access data, model and output directories.
            output_dir = [obj.RawDataPath filesep ...
                obj.ParentDataset.AdjustmentRRADirectory];
            
            % Run adjustment RRA.
            [~, adjusted_model] = adjustmentRRA(...
                obj.ModelPath, obj.IKDataPath, obj.RawDataPath, output_dir, ...
                obj.ParentDataset.getLoadName(obj));
            
            % Copy the adjusted model file in to the appropriate location.
            obj.constructAdjustedModelPath();
            copyfile(adjusted_model, obj.AdjustedModelPath);
            obj.AdjustmentRRAComputed = true;
        end
        
        function prepareBatchRRA(obj)
            
            if ~obj.IKComputed
                error('IK must be performed before doing RRA analyses.');
            end
            
            output_dir = [obj.RawDataPath filesep ...
                obj.ParentDataset.RRADirectory];
            runBatchRRA(obj.AdjustedModelPath, obj.IKDataPath, ...
                obj.RawDataPath, output_dir, ...
                obj.ParentDataset.getLoadName(obj));
            obj.RRADataPath = output_dir;
            obj.RRAComputed = true;
        end
        
        function prepareBatchID(obj)
        
            if ~obj.RRAComputed
                error('Require RRA to compute ID.');
            end
            
            output_dir = [obj.RawDataPath filesep ...
                obj.ParentDataset.IDDirectory];
            runBatchID(obj.AdjustedModelPath, obj.RRADataPath, ...
                obj.RawDataPath, output_dir, ...
                obj.ParentDataset.getLoadName(obj));
            obj.IDComputed = true;
            end
        end
        
        function prepareBatchBodyKinematicsAnalysis(obj)
            
            output_dir = [obj.RawDataPath filesep ...
                obj.ParentDataset.BodyKinematicsDirectory];
            if obj.RRAComputed
                runBatchBodyKinematicsAnalysis(obj.AdjustedModelPath, ...
                    obj.RRADataPath, output_dir);
            elseif obj.IKComputed
                runBatchBodyKinematicsAnalysis(obj.ModelPath, ...
                    obj.IKDataPath, output_dir);
            else
                error('Require IK or RRA data to run BodyKinematicsAnalysis.');
            end
            obj.BodyKinematicsComputed = true;
        end
        
        function prepareBatchCMC(obj)
            
            if obj.RRAComputed
                error('Require RRA to compute CMC.');
            end
            
            output_dir = [obj.RawDataPath filesep ...
                obj.ParentDataset.CMCDirectory];
            runBatchCMC(obj.ModelPath, obj.RRADataPath, obj.RawDataPath, ...
                output_dir, obj.ParentDataset.getLoadName(obj));
            obj.CMCComputed = true;
        end
    
    end

end

