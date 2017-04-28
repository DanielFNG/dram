function scaled_vector = stretchVector(input_vector, desired_size)
% Given a vector of so many elements, stretch/compress it to a specified
% desired size. Inputs should be vectors so Nx1 arrays, but inputs of size 1xN
% are converted to vectors so will also work.
    if size(input_vector,1) ~=1 && size(input_vector,2) ~= 1
        error('Input vector must be a row or column vector.');
    end
    % convert to column vector 
    if size(input_vector, 1) == 1
        input_vector = input_vector.';
    end
    x = 1:1:size(input_vector,1);
    z = 1:(size(input_vector,1)-1)/(desired_size-1):size(input_vector,1);
    scaled_vector = interp1(x, input_vector, z);
end

