function [outputValue] = canOpenDecode(messageStruct, canDataBytes)
%CANOPENDECODE Summary of this function goes here
%   Detailed explanation goes here
% struct('index', 0x4801, 'subindex', 0x00, 'numBytes', 2, 'type', 'uint16', 'scale', 1);

% If only one byte extract it
if messageStruct.numBytes < 2
    rawValue = canDataBytes(5);
else
% Else extract number of bytes for data
    lastByteIndex = 5 + messageStruct.numBytes-1;
    rawValue = typecast( uint8(canDataBytes(5:lastByteIndex)), messageStruct.type);
end

% Type cast to double
outputValue = double(rawValue);

% Scale the value
outputValue = outputValue * messageStruct.scale;

end

