clc
clear all
close all
tic

% MATLAB is amorphous on type -- everything is stored as the type of the RHS on assignment unless directly addressing the element of an existing array of a particular type.
% There's no concept of defining the type of the field of a struct; it takes on the type of the object stored in it on assignment.

endOfHeaderStr = ";---+--   ----+----  --+--  ----+---  +  -+ -- -- -- -- -- -- --";
CAN_DATA_SIZE = 1000000;% Max number of messages of PCAN-VIEW trace file
% File constants
canData = struct(...
    'msgNumber', zeros(1,CAN_DATA_SIZE),...
    'TimeMs', zeros(1,CAN_DATA_SIZE),...
    'Typemsg', zeros(1,CAN_DATA_SIZE),...
    'length', zeros(1,CAN_DATA_SIZE),...
    'ID', zeros(1,CAN_DATA_SIZE),...
    'dataBytes', zeros(8,CAN_DATA_SIZE)...
    );
%canData = canData_t;

% Define format specifiers
formatSpec = '%d) %f %*s %s %*s %d %x %x %x %x %x %x %x %x';
% Variables
numLinesInFile = 0; % Stores the number of lines (\n chars) in the file
numCanMessages = 0; % Stores the number of messages encoded in the file
ERROR_FLAG_BYTE = 0x80;
errorResponseCount = 0;

% Open the .trc file
fileToOpen = uigetfile(['*.trc']);
disp('Opening File')
[fileID, errmsg] = fopen(fileToOpen, "r", "s");
disp(errmsg);

% If file failed to open show error and abort
if fileID == -1
    error('Error opening file');
end

% Display file name and encoding format
%[filename,filePerimssions,fileMachineFormat,encoding] = fopen(fileID)

% Find how many lines are in the file
%%% This takes too long -- just assume worst case PCAN trace file 1 million
%%% messages = 1000014 lines to parse
% while ~feof(fileID)
%     fgetl(fileID);
%     numLinesInFile = numLinesInFile + 1;
% end
% frewind(fileID);
numLinesInFile = CAN_DATA_SIZE; % Assumes max file size of PCAN-VIEW trace file

% Read the header until the end of the file header
for i = 1:100
    header = fgetl(fileID);
    isHeaderEnd = strcmp(header, endOfHeaderStr);
    if isHeaderEnd
        disp('Reached end of header file')
        break;
    end
    if i == 100
        error("Could not find end of header = ABORT")
    end
end

% Calc how many lines remaining for decoding / importing
numCanMessages = numLinesInFile - i;

disp('Starting File Data Import')
displayImport = waitbar(0, sprintf('Importing Data - %d Messages Found', numLinesInFile))
index = 1; % index of the file being read
while ~feof(fileID)
    % Read message index number
    msgNum = fscanf(fileID, "%i)", 1);
    msgTime = fscanf(fileID, "%f", 1);
    msgType = fscanf(fileID, "%s", 1);
    msgID = fscanf(fileID, "%x", 1);
    msgLen = fscanf(fileID, "%i", 1);
    %while i=1:msgLen
    msgByte = fscanf(fileID, "%x ", msgLen);
    %msgByte = fscanf(fileID, "%x ", msgLen);
    %end

    canData.msgNumber(index) = msgNum;
    canData.TimeMs(index) = msgTime;
    %canData.Typemsg(index) = msgType;
    canData.length(index) = msgLen;
    canData.ID(index) = msgID;
    if msgLen > 0
        for k = 1:msgLen
            canData.dataBytes(k,index) = msgByte(k);
        end

    end
    %canData.dataBytes(index) = msgByte';

    index = index + 1;

    if mod(index, 10000) == 0
        %temp = sprintf('Messages Imported %u',index);
        %disp(temp)
        waitbar(index/numCanMessages, displayImport)
    end

end
close(displayImport)
disp('Finished Data Import')
numCanMessages = index - 1;
fclose(fileID);
disp('File closed')


%% Decode CANbus messages

% Constants
ID_Node1 = 49;
FC_TPDO1 = 0x180 + ID_Node1;
FC_TPDO2 = 0x280 + ID_Node1;
FC_TPDO3 = 0x380 + ID_Node1;
FC_TPDO4 = 0x480 + ID_Node1;
FC_TPDO5 = 0x190 + ID_Node1;
FC_TPDO6 = 0x290 + ID_Node1;
functionCode_SDOResponse = 11;

% Can SDO mapping
SDO_OperationMode = struct('index', 0x4801, 'subindex', 0x00, 'numBytes', 2, 'type', 'uint16', 'scale', 1);
SDO_ChargeFault = struct('index', 0x4802, 'subindex', 0x00, 'numBytes', 2, 'type', 'uint16', 'scale', 1);
SDO_DischargeFault = struct('index', 0x4803, 'subindex', 0x00, 'numBytes', 2, 'type', 'uint16', 'scale', 1);
SDO_Current = struct('index', 0x4804, 'subindex', 0x00, 'numBytes', 2, 'type', 'int16', 'scale', 0.1);
SDO_MinCellTemperature = struct('index', 0x4808, 'subindex', 0x00, 'numBytes', 2, 'type', 'int16', 'scale', 0.125);
SDO_MaxCellTemperature = struct('index', 0x4809, 'subindex', 0x00, 'numBytes', 2, 'type', 'int16', 'scale', 0.125);
SDO_minCellVolt = struct('index', 0x480A, 'subindex', 0x00, 'numBytes', 2, 'type', 'uint16', 'scale', 1);
SDO_maxCellVolt = struct('index', 0x480B, 'subindex', 0x00, 'numBytes', 2, 'type', 'uint16', 'scale', 1);
SDO_Voltage = struct('index', 0x480E, 'subindex', 0x00, 'numBytes', 2, 'type', 'uint16', 'scale', 0.001);
SDO_HeaterStatus = struct('index', 0x4810, 'subindex', 0x00, 'numBytes', 2, 'type', 'uint16', 'scale', 1);
SDO_CumulativeTotalAhDischarge = struct('index', 0x484D, 'subindex', 0x00, 'numBytes', 4, 'type', 'uint32', 'scale', 2.5);
SDO_CumulativeTotalAhCharge = struct('index', 0x6050, 'subindex', 0x00, 'numBytes', 4, 'type', 'uint32', 'scale', 2.5);
SDO_SOC = struct('index', 0x6081, 'subindex', 0x00, 'numBytes', 1, 'type', 'uint8', 'scale', 1);
SDO_ATSAMChargeFault = struct('index', 0xD000, 'subindex', 0x3E, 'numBytes', 4, 'type', 'uint32', 'scale', 1);
SDO_ATSAMDiscaharge = struct('index', 0xD000, 'subindex', 0x3F, 'numBytes', 4, 'type', 'uint32', 'scale', 1);


% Create struct for TPDO data
TPDO1 = struct('index', 0, 'VB_numBatts', zeros(2,CAN_DATA_SIZE), 'VB_SOC', zeros(2,CAN_DATA_SIZE), 'VB_CurrentStoredAH', zeros(2,CAN_DATA_SIZE), 'VB_RemRuntime', zeros(2,CAN_DATA_SIZE), 'VB_RemChargeTime', zeros(2,CAN_DATA_SIZE));
TPDO2 = struct('index', 0, 'VB_Pack_Voltage', zeros(2,CAN_DATA_SIZE), 'VB_Current', zeros(2,CAN_DATA_SIZE), 'MaxContDisch_Curr', zeros(2,CAN_DATA_SIZE), 'ChargeCutOffCurrent', zeros(2,CAN_DATA_SIZE), 'VB_FullyCharge', zeros(2,CAN_DATA_SIZE));
TPDO3 = struct('index', 0, 'VB_Temperature', zeros(2,CAN_DATA_SIZE), 'DischargeCutOffVoltage', zeros(2,CAN_DATA_SIZE), 'InstantMaxChargeCurrent', zeros(2,CAN_DATA_SIZE), 'MaxAllowedChargeVoltage', zeros(2,CAN_DATA_SIZE));
TPDO4 = struct('index', 0, 'VB_SOH', zeros(2,CAN_DATA_SIZE), 'VB_NumBattFault', zeros(2,CAN_DATA_SIZE), 'VB_NumBattActive', zeros(2,CAN_DATA_SIZE), 'VBOperationMode', zeros(2,CAN_DATA_SIZE), 'VB_Charge_Fault', zeros(2,CAN_DATA_SIZE), 'VB_Discharge_Fault', zeros(2,CAN_DATA_SIZE));
TPDO5 = struct('index', 0, 'Regen_Current_Limit',zeros(2,CAN_DATA_SIZE), 'Min_Cell_Voltage', zeros(2,CAN_DATA_SIZE), 'Max_Cell_Voltage', zeros(2,CAN_DATA_SIZE), 'Cell_Balance_Status', zeros(2,CAN_DATA_SIZE));
TPDO6 = struct('index', 0, 'VB_Pack_Volt_ALL', zeros(2,CAN_DATA_SIZE), 'VB_SOC_ALL', zeros(2,CAN_DATA_SIZE), 'VB_Temperature_All', zeros(2,CAN_DATA_SIZE), 'Heater_Status', zeros(2,CAN_DATA_SIZE), 'Master_ID', zeros(2,CAN_DATA_SIZE));

% Create struct for each battery
batteryData = struct(...
    'SOC', zeros(2,CAN_DATA_SIZE), 'SOCindex', 0,...
    'Voltage', zeros(2,CAN_DATA_SIZE), 'Voltageindex', 0,...
    'Current', zeros(2,CAN_DATA_SIZE), 'Currentindex', 0,...
    'minCellVoltage', zeros(2,CAN_DATA_SIZE), 'minCellVoltageindex', 0,...
    'maxCellVoltage', zeros(2,CAN_DATA_SIZE), 'maxCellVoltageindex', 0, ...
    'cumChargeAh', zeros(2,CAN_DATA_SIZE), 'cumChargeAhindex', 0, ...
    'cumDischAh', zeros(2,CAN_DATA_SIZE), 'cumDischAhindex', 0 ...
    );
battery(1) = batteryData;
battery(2) = batteryData;
battery(3) = batteryData;
battery(4) = batteryData;
battery(5) = batteryData;
battery(6) = batteryData;
battery(7) = batteryData;
battery(8) = batteryData;
battery(9) = batteryData;
battery(10) = batteryData;
battery(11) = batteryData;
battery(12) = batteryData;


% Loop through all CAN messages and decode if in dictionary
disp('Starting CAN Message Decoding')
displayDecode = waitbar(0, sprintf('Decoding CAN Messages - %d Total',numCanMessages));
for i = 1:numCanMessages

    if mod(i, 10000) == 0
        waitbar(i/numCanMessages, displayDecode)
    end

    % Decode some packet info
    messageNodeFC = bitshift(canData.ID(i), -7);
    messageNodeID = bitand(canData.ID(i), 127);
    messageNodeIDOffset = messageNodeID - 48;

    % TPDO1
    if canData.ID(i) == FC_TPDO1
        TPDO1.index = TPDO1.index + 1;
        TPDO1.VB_numBatts(:,TPDO1.index) = [canData.TimeMs(i), canData.dataBytes(1,i)];
        TPDO1.VB_SOC(:,TPDO1.index) = [canData.TimeMs(i), canData.dataBytes(2,i) ];
        TPDO1.VB_CurrentStoredAH(:,TPDO1.index) = [canData.TimeMs(i), double(typecast( uint8(canData.dataBytes(3:4,i) ), 'uint16' )) ];
        TPDO1.VB_RemRuntime(:,TPDO1.index)  = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(5:6,i)), 'uint16')) ];
        TPDO1.VB_RemChargeTime(:,TPDO1.index)  = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(7:8,i)), 'uint16')) ];

    % TPDO2
    elseif canData.ID(i) == FC_TPDO2
        TPDO2.index = TPDO2.index + 1;
        TPDO2.VB_Pack_Voltage(:,TPDO2.index) = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(1:2,i)), 'uint16')) ];
        TPDO2.VB_Current(:,TPDO2.index) = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(3:4,i)), 'int16')) ];
        TPDO2.MaxContDisch_Curr(:,TPDO2.index) = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(5:6,i)), 'uint16')) ];
        TPDO2.ChargeCutOffCurrent(:,TPDO2.index) = [canData.TimeMs(i), canData.dataBytes(7,i) ];
        TPDO2.VB_FullyCharge(:,TPDO2.index) = [canData.TimeMs(i), canData.dataBytes(8,i) ];

    % TPDO3
     elseif canData.ID(i) == FC_TPDO3
        TPDO3.index = TPDO3.index + 1;
        TPDO3.VB_Temperature(:,TPDO3.index) = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(1:2,i)), 'int16')) ];
        TPDO3.DischargeCutOffVoltage(:,TPDO3.index) = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(3:4,i)), 'uint16')) ];
        TPDO3.InstantMaxChargeCurrent(:,TPDO3.index) = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(5:6,i)), 'uint16')) ];
        TPDO3.MaxAllowedChargeVoltage(:,TPDO3.index)  = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(7:8,i)), 'uint16')) ];

    % TPDO4
     elseif canData.ID(i) == FC_TPDO4
        TPDO4.index = TPDO4.index + 1;
        TPDO4.VB_SOH(:,TPDO4.index) = [canData.TimeMs(i), canData.dataBytes(1,i) ];
        TPDO4.VB_NumBattFault(:,TPDO4.index) = [canData.TimeMs(i), canData.dataBytes(2,i) ];
        TPDO4.VB_NumBattActive(:,TPDO4.index) = [canData.TimeMs(i), canData.dataBytes(3,i) ];
        TPDO4.VBOperationMode(:,TPDO4.index)  = [canData.TimeMs(i), canData.dataBytes(4,i) ];
        TPDO4.VB_Charge_Fault(:,TPDO4.index)  = [canData.TimeMs(i), typecast(uint8(canData.dataBytes(5:6,i)), 'uint16') ];
        TPDO4.VB_Discharge_Fault(:,TPDO4.index)  = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(7:8,i)), 'uint16')) ];

    % TPDO5
    elseif canData.ID(i) == FC_TPDO5
        TPDO5.index = TPDO5.index + 1;
        TPDO5.Regen_Current_Limit(:,TPDO5.index) = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(1:2,i)), 'uint16')) ];
        TPDO5.Min_Cell_Voltage(:,TPDO5.index) = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(3:4,i)), 'uint16')) ];
        TPDO5.Max_Cell_Voltage(:,TPDO5.index) = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(5:6,i)), 'uint16')) ];
        TPDO5.Cell_Balance_Status(:,TPDO5.index)  = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(7:8,i)), 'uint16')) ];

    % TPDO6
    elseif canData.ID(i) == FC_TPDO6
        TPDO6.index = TPDO6.index + 1;
        TPDO6.VB_Pack_Volt_ALL(:,TPDO6.index) = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(1:2,i)), 'uint16')) ];
        TPDO6.VB_SOC_ALL(:,TPDO6.index) = [canData.TimeMs(i), canData.dataBytes(3,i) ];
        TPDO6.Heater_Status(:,TPDO6.index) = [canData.TimeMs(i), double(typecast(uint8(canData.dataBytes(6:7,i)), 'uint16')) ];
        TPDO6.Master_ID(:,TPDO6.index)  = [canData.TimeMs(i), canData.dataBytes(8,i) ];

    % Check if its and SDO Recieve message 
    elseif messageNodeFC == functionCode_SDOResponse
        % Get index and subindex from payload
        messageCommandByte = canData.dataBytes(1,i);
        messageIndex = typecast(uint8(canData.dataBytes(2:3,i)), 'uint16');
        messageSubIndex =  canData.dataBytes(4,i);

        % Check if response is an error
        if messageCommandByte == ERROR_FLAG_BYTE
            errorResponseCount = errorResponseCount + 1;
        else

         % SOC
         if messageIndex == SDO_SOC.index
             if messageSubIndex == SDO_SOC.subindex
                 battery(messageNodeIDOffset).SOCindex = battery(messageNodeIDOffset).SOCindex + 1;
                 battery(messageNodeIDOffset).SOC(:, battery(messageNodeIDOffset).SOCindex) = [canData.TimeMs(i), canOpenDecode(SDO_SOC, canData.dataBytes(:,i)) ];
             end
         % Voltage
         elseif messageIndex == SDO_Voltage.index
             if messageSubIndex == SDO_Voltage.subindex
                 battery(messageNodeIDOffset).Voltageindex = battery(messageNodeIDOffset).Voltageindex + 1;
                 battery(messageNodeIDOffset).Voltage(:, battery(messageNodeIDOffset).Voltageindex) = [canData.TimeMs(i), canOpenDecode(SDO_Voltage, canData.dataBytes(:,i)) ];
             end
         % Current
         elseif messageIndex == SDO_Current.index
             if messageSubIndex == SDO_Current.subindex
                 battery(messageNodeIDOffset).Currentindex = battery(messageNodeIDOffset).Currentindex + 1;
                 battery(messageNodeIDOffset).Current(:, battery(messageNodeIDOffset).Currentindex) = [canData.TimeMs(i), canOpenDecode(SDO_Current, canData.dataBytes(:,i)) ];
             end
         % Min Cell Voltage
         elseif messageIndex == SDO_minCellVolt.index
             if messageSubIndex == SDO_minCellVolt.subindex
                 battery(messageNodeIDOffset).minCellVoltageindex = battery(messageNodeIDOffset).minCellVoltageindex + 1;
                 battery(messageNodeIDOffset).minCellVoltage(:, battery(messageNodeIDOffset).minCellVoltageindex) = [canData.TimeMs(i), canOpenDecode(SDO_minCellVolt, canData.dataBytes(:,i)) ];
             end
         % Max Cell Voltage
         elseif messageIndex == SDO_maxCellVolt.index
             if messageSubIndex == SDO_maxCellVolt.subindex
                 battery(messageNodeIDOffset).maxCellVoltageindex = battery(messageNodeIDOffset).maxCellVoltageindex + 1;
                 battery(messageNodeIDOffset).maxCellVoltage(:, battery(messageNodeIDOffset).maxCellVoltageindex) = [canData.TimeMs(i), canOpenDecode(SDO_maxCellVolt, canData.dataBytes(:,i)) ];
             end
         % Cumulative Charge
         elseif messageIndex == SDO_CumulativeTotalAhCharge.index
             if messageSubIndex == SDO_CumulativeTotalAhCharge.subindex
                 battery(messageNodeIDOffset).cumChargeAhindex = battery(messageNodeIDOffset).cumChargeAhindex + 1;
                 battery(messageNodeIDOffset).cumChargeAh(:, battery(messageNodeIDOffset).cumChargeAhindex) = [canData.TimeMs(i), canOpenDecode(SDO_CumulativeTotalAhCharge, canData.dataBytes(:,i)) ];
             end
         % Cumulative Discharge
         elseif messageIndex == SDO_CumulativeTotalAhDischarge.index
             if messageSubIndex == SDO_CumulativeTotalAhDischarge.subindex
                 battery(messageNodeIDOffset).cumDischAhindex = battery(messageNodeIDOffset).cumDischAhindex + 1;
                 battery(messageNodeIDOffset).cumDischAh(:, battery(messageNodeIDOffset).cumDischAhindex) = [canData.TimeMs(i), canOpenDecode(SDO_CumulativeTotalAhDischarge, canData.dataBytes(:,i)) ];
             end
        end

        end
    end
    
end

disp('Decoding Done')
close(displayDecode)


%% Trim data
TPDO1.VB_numBatts = B427TrimData(TPDO1.VB_numBatts,TPDO1.index);
TPDO1.VB_SOC = B427TrimData(TPDO1.VB_SOC,TPDO1.index);
TPDO1.VB_CurrentStoredAH = B427TrimData(TPDO1.VB_CurrentStoredAH,TPDO1.index);
TPDO1.VB_RemRuntime = B427TrimData(TPDO1.VB_RemRuntime,TPDO1.index);
TPDO1.VB_RemChargeTime = B427TrimData(TPDO1.VB_RemChargeTime,TPDO1.index);

TPDO2.VB_Pack_Voltage = B427TrimData(TPDO2.VB_Pack_Voltage,TPDO2.index);
TPDO2.VB_Current = B427TrimData(TPDO2.VB_Current,TPDO2.index);
TPDO2.MaxContDisch_Curr = B427TrimData(TPDO2.MaxContDisch_Curr,TPDO2.index);
TPDO2.ChargeCutOffCurrent = B427TrimData(TPDO2.ChargeCutOffCurrent,TPDO2.index);
TPDO2.VB_FullyCharge = B427TrimData(TPDO2.VB_FullyCharge,TPDO2.index);

TPDO3.VB_Temperature = B427TrimData(TPDO3.VB_Temperature, TPDO3.index);
TPDO3.DischargeCutOffVoltage = B427TrimData(TPDO3.DischargeCutOffVoltage, TPDO3.index);
TPDO3.InstantMaxChargeCurrent = B427TrimData(TPDO3.InstantMaxChargeCurrent, TPDO3.index);
TPDO3.MaxAllowedChargeVoltage = B427TrimData(TPDO3.MaxAllowedChargeVoltage, TPDO3.index);

TPDO4.VB_SOH = B427TrimData(TPDO4.VB_SOH, TPDO4.index);
TPDO4.VB_NumBattFault = B427TrimData(TPDO4.VB_NumBattFault, TPDO4.index);
TPDO4.VB_NumBattActive = B427TrimData(TPDO4.VB_NumBattActive, TPDO4.index);
TPDO4.VBOperationMode = B427TrimData(TPDO4.VBOperationMode, TPDO4.index);
TPDO4.VB_Charge_Fault = B427TrimData(TPDO4.VB_Charge_Fault, TPDO4.index);
TPDO4.VB_Discharge_Fault = B427TrimData(TPDO4.VB_Discharge_Fault, TPDO4.index);

TPDO5.Regen_Current_Limit = B427TrimData(TPDO5.Regen_Current_Limit, TPDO5.index);
TPDO5.Min_Cell_Voltage = B427TrimData(TPDO5.Min_Cell_Voltage, TPDO5.index);
TPDO5.Max_Cell_Voltage = B427TrimData(TPDO5.Max_Cell_Voltage, TPDO5.index);
TPDO5.Cell_Balance_Status = B427TrimData(TPDO5.Cell_Balance_Status, TPDO5.index);

TPDO6.VB_Pack_Volt_ALL = B427TrimData(TPDO6.VB_Pack_Volt_ALL, TPDO6.index);
TPDO6.VB_SOC_ALL = B427TrimData(TPDO6.VB_SOC_ALL, TPDO6.index);
TPDO6.Heater_Status = B427TrimData(TPDO6.Heater_Status, TPDO6.index);
TPDO6.Master_ID = B427TrimData(TPDO6.Master_ID, TPDO6.index);

for j = 1:12
    battery(j).SOC =  B427TrimData(battery(j).SOC, battery(j).SOCindex);
    battery(j).Voltage =  B427TrimData(battery(j).Voltage, battery(j).Voltageindex);
    battery(j).Current =  B427TrimData(battery(j).Current, battery(j).Currentindex);
    battery(j).minCellVoltage =  B427TrimData(battery(j).minCellVoltage, battery(j).minCellVoltageindex);
    battery(j).maxCellVoltage =  B427TrimData(battery(j).maxCellVoltage, battery(j).maxCellVoltageindex);
    battery(j).cumChargeAh =  B427TrimData(battery(j).cumChargeAh, battery(j).cumChargeAhindex);
    battery(j).cumDischAh =  B427TrimData(battery(j).cumDischAh, battery(j).cumDischAhindex);
end


scriptTime = toc



%% Log total time in hours
totalTimeHours = (TPDO1.VB_numBatts(1,end) - TPDO1.VB_numBatts(1,1)) / 1000 / 60 / 60

%% Battery Discharge and Charge Ah deltas for each battery

batteryCumulDischargeAh = zeros(12,1);
batteryCumulChargeAh = zeros(12,1);
for j = 1:12
    batteryCumulDischargeAh(j) = battery(j).cumDischAh(2,end) - battery(j).cumDischAh(2,1);
    batteryCumulChargeAh(j) = battery(j).cumChargeAh(2,end) - battery(j).cumChargeAh(2,1);
end












