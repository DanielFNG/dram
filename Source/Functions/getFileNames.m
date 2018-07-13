function filenames = getFileNames(directory, extension, n)

    if nargin == 2
        n = 1;
    elseif nargin < 2 || nargin > 3
        error('Incorrect number of arguments to getGRFFileNames.');
    end
    
    if n < 1 || rem(x, 1) ~= 0
        error('Require integer n to getGRFFileNames.');
    end
    
    filenames = cell(n, 1);
    files = dir([directory filesep '*' extension]);
    for i=1:n
        filenames{i} = [directory filesep files(i).name];
    end

end