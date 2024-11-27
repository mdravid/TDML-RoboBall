function [mSpect,pSpect,TimeGrid,FreqGrid] = Spectrogram(Signal,TimeStamps,sf,tw,to)

% FUNCTION OVERVIEW
%{
This function computes the spectrogram of the signal contained in the array
"Signal" according to the time window "tw" and the time overlap "to".
Returns:
    - the magnitude spectrogram in the matrix "mSpect"
    - the corresponding phase spectrogram in the matrix "pSpect"
    - the time grid (useful for plots) in the matrix "TimeGrid"
    - the frequency grid (useful for plots) in the matrix "FreqGrid"
Uses the information of the sampling frequency at which the signal is
provided contained as a double in the input variable "sf".
%}

% disp('Spectrogram function called with:');
% disp(['Signal size: ', num2str(size(Signal))]);
% disp(['TimeStamps size: ', num2str(size(TimeStamps))]);
% disp(['Sampling frequency: ', num2str(sf)]);
% disp(['Time window: ', num2str(tw)]);
% disp(['Time overlap: ', num2str(to)]);

t0 = table2array(TimeStamps(1,1));
t1 = t0+tw;
k = 1;
a=table2array(TimeStamps(end,1));
% // while t1 <= a
% //     TimePoints(k,1) = t1;
% //     timevalue=TimeStamps.Timestamp;
% //     [~,e0] = min(abs(t0-(timevalue)));
% //     [~,e1] = min(abs(t1-(timevalue)));
% //    SignalArray = table2array(Signal);
% 
% 
% // %disp(['Processing segment: ', num2str(e0), ' to ', num2str(e1)]);
% // %disp(['Segment size: ', num2str(size(SignalArray(e0:e1)))]);
% // [x, y, Freq] = DFT(SignalArray((e0):(e1)),sf);
% 
% // mSpect = x;
% // pSpect =y;
% //     k = k + 1;
% //     t0 = t1-to;
% //     t1 = t0+tw;
% // end

expectedSegmentSize = 14;

while t1 <= a
    TimePoints(k,1) = t1;
    timevalue = TimeStamps.Timestamp;
    [~, e0] = min(abs(t0 - timevalue));
    [~, e1] = min(abs(t1 - timevalue));
    SignalArray = table2array(Signal);

    segmentSize = e1 - e0 + 1;
    %disp(['Processing segment: ', num2str(e0), ' to ', num2str(e1)]);
    %disp(['Segment size: ', num2str(segmentSize)]);

    % Ensure the segment size is consistent
    if segmentSize ~= expectedSegmentSize
        disp(['Segment size is inconsistent, expected: ', num2str(expectedSegmentSize), ', got: ', num2str(segmentSize)]);
        % Adjust e1 to ensure consistent segment size
        e1 = e0 + expectedSegmentSize - 1;
        if e1 > length(SignalArray)
            disp('Adjusted segment exceeds signal length, skipping this segment.');
            break;
        end
    end

    % Extract the segment and adjust its size
    segment = SignalArray(e0:e1);
    if length(segment) < expectedSegmentSize
        % Pad the segment with zeros if it is too short
        segment = [segment; zeros(expectedSegmentSize - length(segment), 1)];
    elseif length(segment) > expectedSegmentSize
        % Truncate the segment if it is too long
        segment = segment(1:expectedSegmentSize);
    end

    [x, y, Freq] = DFT(segment, sf);
%     if k == 1
%         mSpect = zeros(length(Freq), 0);  % Initialize with zero columns
%         pSpect = zeros(length(Freq), 0);  % Initialize with zero columns
%     end
    % Dynamically resize mSpect and pSpect to accommodate new data
    mSpect = x;
    pSpect = y;
    k = k + 1;

    t0 = t1 - to;
    t1 = t0 + tw;
end

[TimeGrid,FreqGrid]= meshgrid(TimePoints,Freq);
% disp(['Output mSpect size: ', num2str(size(mSpect))]);
% disp(['Output pSpect size: ', num2str(size(pSpect))]);
% disp(['Output TimeGrid size: ', num2str(size(TimeGrid))]);
% disp(['Output FreqGrid size: ', num2str(size(FreqGrid))]);

end

% disp('Spectrogram function called with:');
% disp(['Signal size: ', num2str(size(Signal))]);
% disp(['TimeStamps size: ', num2str(size(TimeStamps))]);
% disp(['Sampling frequency: ', num2str(sf)]);
% disp(['Time window: ', num2str(tw)]);
% disp(['Time overlap: ', num2str(to)]);
% 
% t0 = table2array(TimeStamps(1,1));
% t1 = t0 + tw;
% k = 1;
% a = table2array(TimeStamps(end,1));
% TimePoints = [];
% 
% while t1 <= a
%     TimePoints(k,1) = t1;
%     timevalue = TimeStamps.Timestamp;
%     [~, e0] = min(abs(t0 - timevalue));
%     [~, e1] = min(abs(t1 - timevalue));
%     SignalArray = table2array(Signal);
% 
% %     segmentSize = e1 - e0 + 1;
% %     disp(['Processing segment: ', num2str(e0), ' to ', num2str(e1)]);
% %     disp(['Segment size: ', num2str(segmentSize)]);
% 
%     % Ensure the segment size is consistent
%     expectedSegmentSize = 17;
%     if segmentSize ~= expectedSegmentSize
%         disp(['Segment size is inconsistent, expected: ', num2str(expectedSegmentSize), ', got: ', num2str(segmentSize)]);
%         % Adjust e1 to ensure consistent segment size
%         e1 = e0 + expectedSegmentSize - 1;
%         if e1 > length(SignalArray)
%             disp('Adjusted segment exceeds signal length, skipping this segment.');
%             break;
%         end
%     end
% 
%     [x, y, Freq] = DFT(SignalArray(e0:e1), sf);
%     if k == 1
%         mSpect = zeros(length(Freq), 0);  % Initialize with zero columns
%         pSpect = zeros(length(Freq), 0);  % Initialize with zero columns
%     end
%     % Dynamically resize mSpect and pSpect to accommodate new data
%     mSpect(:, k) = x;
%     pSpect(:, k) = y;
%     k = k + 1;
% 
%     t0 = t1 - to;
%     t1 = t0 + tw;
% end
% 
% [TimeGrid, FreqGrid] = meshgrid(TimePoints, Freq);
% 
% disp(['Output mSpect size: ', num2str(size(mSpect))]);
% disp(['Output pSpect size: ', num2str(size(pSpect))]);
% disp(['Output TimeGrid size: ', num2str(size(TimeGrid))]);
% disp(['Output FreqGrid size: ', num2str(size(FreqGrid))]);
% 
% end