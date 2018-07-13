classdef DatasetElement

    properties (SetAccess = private)
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
            obj.Dataset = dataset;
            obj.Subject = subject;
            obj.ParameterValues = parameters;
        end
    
        function prepareBatchIK(obj)
            data_path = Dataset.constructRawDataPath(obj.Dataset, ...
                obj.Subject, obj.ParameterValues);
            model_path = Dataset.constructModelPath(obj.Dataset, ...
                obj.Subject, obj.ParameterValues);
            output_dir = [data_path filesep obj.IKDirectory];
            runBatchIK(model_path, data_path, output_dir);
        end
        
        function prepareAdjustmentRRA(obj)
        
            % Access data and model filenames.
            data_path = Dataset.constructRawDataPath(obj.Dataset, ...
                obj.Subject, obj.ParameterValues);
            model_path = Dataset.constructModelPath(obj.Dataset, ...
                obj.Subject, obj.ParameterValues);
            output_dir = [data_path filesep obj.AdjustmentRRADirectory];
            
            % Access the first motion and grf file. 
            ik_files = [
                
            % Run adjustment RRA.
            [~, path] = adjustmentRRA(model_path, first_ik, 
            
            % Copy the adjusted model file in to the appropriate location.
            [~, model_name, ~] = fileparts(model_path);
            [~, new_model_name, ext] = fileparts(path);
        end
    
    end

end

