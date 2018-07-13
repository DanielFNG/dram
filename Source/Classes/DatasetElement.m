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
        IKDirectory = 'IK_Results'
        AdjustmentRRADirectory = 'AdjustmentRRA_Results'
        RRADirectory = 'RRA_Results'
        BodyKinematicsDirectory = 'BodyKinematics_Results'
        IDDirectory = 'ID_Results'
        CMCDirectory = 'CMC_Results'
    end
    
    methods

        function obj = DatasetElement(dataset, subject, parameters)
            obj.ParentDataset = dataset;
            obj.Subject = subject;
            obj.ParameterValues = parameters;
        end
    
        function prepareBatchIK(obj)
            
            % Access data, model and output directories.
            data_path = Dataset.constructRawDataPath(obj.ParentDataset, ...
                obj.Subject, obj.ParameterValues);
            model_path = Dataset.constructModelPath(obj.ParentDataset, ...
                obj.Subject, obj.ParameterValues);
            output_dir = [data_path filesep obj.IKDirectory];
            
            % Run IK. 
            runBatchIK(model_path, data_path, output_dir);
        end
        
        function prepareAdjustmentRRA(obj)
            
            % Access data, model and output directories.
            grf_path = Dataset.constructRawDataPath(obj.ParentDataset, ...
                obj.Subject, obj.ParameterValues);
            ik_path = Dataset.constructKinematicDataPath(obj.ParentDataset, ...
                'IK', obj.Subject, obj.ParameterValues);
            model_path = Dataset.constructModelPath(obj.ParentDataset, ...
                obj.Subject, obj.ParameterValues);
            output_dir = [grf_path filesep obj.AdjustmentRRADirectory];
            
            % Run adjustment RRA.
            [~, adjusted_model] = adjustmentRRA(...
                model_path, ik_path, grf_path, output_dir, ...
                obj.ParentDataset.LoadMap(...
                obj.ParameterValues(obj.ParentDataset.ModelParameterIndex)));
            
            % Copy the adjusted model file in to the appropriate location.
            copyfile(adjusted_model, ...
                obj.ParentDataset.constructAdjustedModelPath(...
                obj.Subject, obj.ParameterValues));
        end
        
        function prepareBatchRRA(obj)
            
            % Access data, model and output directories.
            grf_path = Dataset.constructRawDataPath(obj.ParentDataset, ...
                obj.Subject, obj.ParameterValues);
            ik_path = Dataset.constructKinematicDataPath(obj.ParentDataset, ...
                'IK', obj.Subject, obj.ParameterValues);
            model_path = Dataset.constructAdjustedModelPath(
            
            
    
    end

end

