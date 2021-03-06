function [status] = createBlockDirKinematicDH( rob, varargin )
%% CREATEBLOCKDIRKINEMATICDH Create Embedded Matlab Function block for the analytic forward kinematics.
% =========================================================================
%
%   [status] = createBlockDirKinematicDH( rob )
%   [status] = createBlockDirKinematicDH( rob, robOpts)
%
%
%  Input:
%    rob :    Robot definition struct.
%    robOpts: Optional robot model generation options struct.
%
%  Output:
%    status:  1 If block has been created.
%             0 If block has NOT been created.
%
%  Example:
%    rob = stanfordarm3;
%    status = createBlockDirKinematicDH(rob); 
%
%  Known Bugs:
%    ---
%
%  TODO:
%    ---
%
%  References:
%    ---
%
%  Authors:
%    J�rn Malzahn   
%
%  See also createDirKinematicDH,createBlockJacobianDH.
%
%  This software may be used under the terms of CC BY-SA 3.0 license 
%          < http://creativecommons.org/licenses/by-sa/3.0/ >
%    
%          2012 RST, Technische Universit�t Dortmund, Germany
%               < http://www.rst.e-technik.tu-dortmund.de >
% 
% ========================================================================

%% Handle robot modeling options
if nargin > 1
    robOpts = completeRobOpts(varargin{1});
else
    robOpts = getRobotModelOpts('default');
end

% Output to logfile?
if ~isempty(robOpts.logFile)
    logFid = fopen(robOpts.logFile,'a');
else
    logFid = [];
end

%% Prerequesites
status = 0;
curPath = fullfile(pwd, rob.name);                                          % compose path to output directory

if (~exist(curPath,'dir'))                                                 % check whether output directory exists, otherwise no blocks can be created
    error('Nothing to create a library from. Create files first.')
else
    addpath(curPath);                                                      % if the output directory exists, make sure it is on the search path
end

%% Gather information about the robot
nJoints = size(rob.DH,1);
mdlName = ['mdl',rob.name];

%% Open or create block library
load_system('simulink');
if exist(fullfile(curPath,mdlName),'file')                                  % open existing block library if it already exists
    open_system(mdlName)
else
    new_system(mdlName,'Library');                      % create new block library if none exists
    open_system(mdlName)
end
set_param(mdlName,'lock','off');                                           % unlock library to modify contents

%% Load Forward Kinematics
fName = fullfile(curPath,'DirKinematicDH.mat');                                    
if exist(fName,'file')
    tmpStruct = load(fName);                                               % read precomputed kinematics
    
    for iJoints = 1:nJoints                                                % acutal block creation
        if iJoints ~= nJoints
            blockAddress = [mdlName,'/dirKin',num2str(iJoints),'0'];       % treat intermediate transformations separately
            symExpr2SLBlock(blockAddress,tmpStruct.dirKinC{iJoints});
        else
            blockAddress = [mdlName,'/dirKin'];
            symExpr2SLBlock(blockAddress,tmpStruct.dirKinC{iJoints});      % full forward kinematics
        end
    end
    
    status = 1;                                                            % blocks successfully created, change return status
end

%% Tidy up, relock and close library
distributeBlocks( mdlName );
set_param(mdlName,'lock','on');                                             
save_system(mdlName, fullfile(curPath,mdlName));
close_system(mdlName);
end

