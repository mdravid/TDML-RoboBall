% AUTHOR INFORMATION AND SCRIPT OVERVIEW, V1.0, 12/2020
%{
Author:________________________________________Fabio Vulpi (Github: Ph0bi0) 

                                 PhD student at Polytechnic of Bari (Italy)
                     Researcher at National Research Council of Italy (CNR)

This is the main script to train and test deep terrain classification
models:
- Convolutional Neural Network (CNN)
- Long Short-Term Memory recurrent neural network (LSTM)
- Convolutional Long Short-Term Memory recurrent neural network (CLSTM)

The script also uses a state of the art Support Vector Machine (SVM) as
benchmark
%}
%-------------------------------------------------------------------------%
clear all, close all, clc;
% Determine where your m-file's folder is.
folder = fileparts(which(mfilename)); 
% Add that folder plus all subfolders to the path.
addpath(genpath(folder));

% automatically attaches to your working directory
DataDir = strcat(folder,'/datasets');

% PRELIMINARY SETTINGS AND DATA ORGANIZATION
%{
The user can easily change the datasets folder to consider more terrain
classes or add samples.
The folder datasets must contain as many folders as the terrain classes
available. 
All data available for a specific terrain must be contained in the
folder named after that terrain label. 

Sensor data provided at a certain frequency must be contained in the same
.mat file and have the same sensor label name <SensorName>
Each recording available for a single terrain must have the recording
number specified. (e.g. <SensorName>_<RecordingNumber>)
 
Each .mat file must:
- have size [ nObs , nSensChan+1 ], where:
  - nObs are the number of observations
  - nSensChan are the number of sensor channels measuring at the same
  sampling frequency 
- contain timestamps on first column 
%}

%CHANNEL SELECTION
%{
The user can select sensor channels and consider different sampling
frequencies changing fields of the struct "Channels" coherently with the
dataset.
Channels struct contains as many fields as different sampling frequencies
availabe. 
Each field of Channels must be named after the <SensorName> of the .mat
file.
Each field of Channels must be a struct with two fields:
- "sf": a double corresponding to the nominal sampling frequency associated
to <SensorName>
- "on": a cell of dimensions [ nSensChan , 2 ] where:
  - The first column contains a 'char' with a name rapresentative of the
  specific sensor channel
  - The second column contains a 'double' that can be either 1 or 0,
  1 if the specific sensor channel has to be considered in the analysis
  0 if not.

The function "Get_Recordings" returns a struct "REC" containing the
extracted data recordings with the selected channels.
The function "Get_Recordings" used here can be found in the directory
"./functions/data functions" with a function overview that the user can
read to better understand it.
%}

Channels.imu.sf = 200; %[Hz] sampling frequency of imu data
Channels.imu.on = {'gyrX', 1;...
                   'gyrY', 1;...
                   'gyrZ', 1;...
                   'accX', 1;...
                   'accY', 1;...
                   'accZ', 1;...
                   'Pressure', 1};

% Channels.pro.sf = 15; %[Hz] sampling frequency of pro data
% Channels.pro.on = {'Lvel', 1;...
%                    'Rvel', 1;...
%                    'Lcur', 1;...
%                    'Rcur', 1};

REC = Get_Recordings(DataDir,Channels);

KFOLD = 5;
PART_WINDOW = 5; %[s] time window used for partition data
SAMP_WINDOWS = [3.5,3.6,3.7,3.8]; %[s] time windows of samples

RNG.seed = 21;
RNG.generator = 'twister';

[Train,Test] = Partition_Data(REC,Channels,KFOLD,PART_WINDOW,RNG);

AUG.sliding_window = 0.1; %[s] 
AUG.same = 1; %(1 or 0)
MODELS = {'CNN'};

% CNN SETTINGS
%{
The user can access 4 parameters related to the Convoluted Neural Network
model by changing the struct "CNNpar".
The struct "CNNpar" has 4 fields:
    - TimeWindow, containing the time window used for building spectrograms
    - TimeOvrlap, containing the time overlap used for building
    spectrograms
    - FilterSize, an array containing the size of the convolutional filters
    of the model
    - numFilters, containing the number of filters to optimize during
    training

!! CAUTION !! ( 0 < TimeOvrlap < TimeWindow )
The time overlap must be strictly smaller the time selected time window.

The function "MCS_Data" returns 2 structs "TrainMCS" and "TestMCS"
containig the multichannel spectrograms data according to the parameters
specified in the struct "CNNpar".
The function "MCS_Data" used here can be found in the directory
"./functions/data functions" with a function overview that the user can
read to better understand it.

The user can access training options for CNN training through the cell
"CNN_TrainOpt".
The user can change any of the following training options:
    - validation percentage, "valid_perc", the percentage of the training
    set used for validation, between 0 (0%) and 1 (100%)
    - initial learning rate, "init_learn_rate", the initial learning rate
    of the training process
    - learnining drop factor, "learn_drop_factor", a scalar from 0 to 1, a
    multiplicative factor to apply to the learning rate every time a
    10 epochs passes (10 is default epoch period)
    - maximum number of epochs, "max_epochs", the maximum number of times
    the learning process passes through the entire training set, after
    which training will stop
    - mini batch size, "minibatch_size", the number of samples that
    constitute the minibatch, the training process passes through the
    minibatch every iteration to update the computed weights and biases
    - validation patience, "valid_patience", the number of times that the
    loss on the validation set can be larger than or equal to the
    previously smallest loss before network training stops
    - validation frequency, "valid_frequency", the number of iteration
    after which the training process will check the validation set
    - gradient treshold, "gradient_treshold", Inf or a positive scalar, if
    the gradient exceeds the value of gradient_treshold, then the gradient
    is clipped according to L2 Norm method (default gradient treshold
    method in matlab) 

The function used to train and test the CNN model is "Conv_NeuralNet".
The function "Conv_NeuralNet" can be found in the directory
"./functions/model functions" with a function overview that the user can
read to better understand the process.
%}

CNNpar.TimeWindow = 0.4;
CNNpar.TimeOvrlap = 0.2;
CNNpar.FilterSize = [3 3];
CNNpar.numFilters = 3;

CNN_TrainOpt = {'valid_perc'       , 0.1  ;...
                'init_learn_rate'  , 0.005;...
                'learn_drop_factor', 0.1  ;...
                'max_epochs'       , 200  ;...
                'minibatch_size'   , 10   ;...
                'valid_patience'   , 8    ;...
                'valid_frequency'  , 100  ;...
                'gradient_treshold', 5};


% SVM SETTINGS
%{
The user can access 1 parameter related to the Support Vector Machine model
by changing the struct "SVMpar". 
The struct "SVMpar" has 1 field:
    - nStatMom, containing the number of statistical moments of time
    signals to be computed and used for SVM training

The user can access training options for SVM training through the cell
"SVM_TrainOpt".
The user can change any of the following training options:
    - Kernel function, "kernel_function", the function regulating the type
    of kernel
    - Polynomial order, "polynomial_order", the polynomial order of the
    kernel
    - Kernel scale, "kernel_scale", a scaling parameter for the input data
    default: 'auto' 
    - Box constraint, "box_constraint", controls the maximum penalty
    imposed on margin-violating observations, and aids in preventing
    overfitting. Increasing this parameter causes the SVM to assign fewer
    support vectors but can lead to longer training times.
    - Standardize, "standardize", flag indicating whether the software
    should standardize the predictors before training the classifier
    default: 1 (True)  
    - Coding, "coding", the coding type ('onevsone' or 'onevsall')

The function used to train and test the SVM model is
"SupportVectorMachine".
The function "SupportVectorMachine" can be found in the directory
"./functions/model functions" with a function overview that the user can
read to better understand the process.
%}
% 
% SVMpar.nStatMom = 4;
% 
% SVM_TrainOpt = {'kernel_function'  , 'polynomial' ;...
%                 'polynomial_order' , 4            ;...
%                 'kernel_scale'     , 'auto'       ;...
%                 'box_constraint'   , 100          ;...
%                 'standardize'      , 1            ;...
%                 'coding'           , 'onevsone'  };

% SAVE RESULTS 
%{
The user can set a custom name in "SaveName".
The code will automatically save the results of training and testing of all
models in the directory "./results" with the choosen name for future
analysis of the results.
%}

SaveName = 'TrainingResults_4';

for i = 1:numel(SAMP_WINDOWS)
    
    w = SAMP_WINDOWS(i);
    [AugTrain,AugTest] = Augment_Data(Train,Test,Channels,w,AUG);
    
    disp(strcat('Training models for sampling window of'," ",num2str(w)," ",'seconds'))
    disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
    for j = 1:numel(MODELS)
        model = MODELS{j};
        switch model
            case 'CNN'
                [TrainMCS,TestMCS] = MCS_Data(AugTrain,AugTest,Channels,CNNpar);
                RES.(model).(strcat('SampWindow_',num2str(w*1000),'ms')) = ...
                    Conv_NeuralNet(TrainMCS,TestMCS,CNNpar,CNN_TrainOpt,RNG);
%             case 'LSTM'
%                 [TrainDS,TestDS]= DownSample_Data(AugTrain,AugTest,Channels);
%                 RES.(model).(strcat('SampWindow_',num2str(w*1000),'ms')) = ...
%                     LSTM_RecurrentNet(TrainDS,TestDS,LSTMpar,LSTM_TrainOpt,RNG);
%             case 'CLSTM'
%                 [TrainDS,TestDS]= DownSample_Data(AugTrain,AugTest,Channels);
%                 RES.(model).(strcat('SampWindow_',num2str(w*1000),'ms')) = ...
%                     CLSTM_RecurrentNet(TrainDS,TestDS,CLSTMpar,CLSTM_TrainOpt,RNG);
%             case 'SVM'
%                 RES.(model).(strcat('SampWindow_',num2str(w*1000),'ms')) = ...
%                     SupportVectorMachine(AugTrain,AugTest,SVMpar,SVM_TrainOpt);
        end
    end
end

% store channels settings
RES.Channels = Channels;
% store terrain lables
DIR = dir(DataDir);
j = 1;
for i = 1:numel(DIR)
    switch DIR(i).name
        case {'.','..','.DS_Store'}
        otherwise
            RES.TerLabls{1,j} = strrep(DIR(i).name,'_',' ');
            j = j+1;
    end
end

save(strcat(folder,'/results/',SaveName,'.mat'),'RES')
