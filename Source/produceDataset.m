% Create Dataset.
eml = Dataset(pwd);

% Perform model adjustment.
eml.performModelAdjustment();

% Compute what's needed for the XPBoS metric - namely BK, which needs IK.
eml.process({'IK', 'BK', 'ID'});

% Load the data needed for the XPBoS metric - markers, grfs & BK.
eml.load({'Markers', 'GRF', 'IK', 'BK', 'ID'});