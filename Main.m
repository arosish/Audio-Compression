clc;
clear;
close all;

SCALING_FACTOR = 0.05;  %DSE Factor
CAST_FACTOR = 2;        %DCTC Factor
FRAME_LENGTH_SECONDS = 0.005;
OVERLAP_RATIO = 0.2;

[rec, fs] = audioread('sample.wav');
rec = highpass(rec,100,fs); %remove DC and 60 Hz hum  

%Convert to mono (rastarize channels)
channelCount = length(rec(1,:));
if(channelCount ~=1 )
   rec = sum(rec,2)/channelCount;   
end

%Set frame parameters
chunkSizeSeconds = FRAME_LENGTH_SECONDS;   
frameShiftSeconds = chunkSizeSeconds * OVERLAP_RATIO; 

frameLength = ceil(chunkSizeSeconds*fs);
recordingLength = length(rec);
frameShiftLength = frameShiftSeconds*fs;
frameShiftCount = ceil(frameShiftLength);

frameCount = floor(recordingLength/(frameShiftCount/3)) - floor(frameLength/frameShiftCount);   

%Split audio into frames
frames = [];
for  frame=1:frameCount

    frameStart = (frame - 1)* frameLength+1 - ( (frame-1)*frameShiftCount); % Select start and end of the frame 
    frameEnd = frameStart + frameLength-1;
    
    if(frameEnd > recordingLength)  %Sanity check 
       break; 
    end
    
    frames(frame,:) = (rec(frameStart:frameEnd).*hamming(frameLength)); %Add the new frame to the list
    
    clc;
    f = sprintf('Building frames: %d / %d', frame, frameCount);
    disp(f);
    
end
 
%dynamic compression
reducedFrames = []; %Process frames list
for frame = 1:length(frames(:,1))

    [reducedFrame, newFrameLength] = DynamicSampleElimination(frames(frame,:), SCALING_FACTOR); %Apply dynamic compression
    reducedFrames(frame,:) = reducedFrame;  %Save reduced frame to list
    
    clc;
    f = sprintf('Reducing Frames: %d / %d', frame, length(frames(:,1)));
    disp(f);
    
end
newSamplingFreq = fs*(1 - SCALING_FACTOR);
newRecordingLength = floor(recordingLength*(1 - SCALING_FACTOR));
frameLength = newFrameLength;
frames = reducedFrames;

%rebuild from frames using overlap and add method
skipCount = floor((frameLength - frameShiftCount) * (1-SCALING_FACTOR)); 
rebuiltSignal = [];
rebuiltSignal( 1, (skipCount*(1-1) + 1 ):(skipCount*(1-1) + length(frames(1,:)))) =  frames(1,:);
for i = 2:length(frames(:,1))

    rebuiltSignal( 2, (skipCount*(i-1) + 1 ):(skipCount*(i-1) + length(frames(i,:)))) =  frames(i,:);
    rebuiltSignal = sum(rebuiltSignal);

    clc;
    f = sprintf('Processing frames: %d / %d', i, length(frames(:,1)));
    disp(f);
end

rebuiltSignal = rebuiltSignal';

fs = ((length(rebuiltSignal)/length(rec)) * fs);
[downsamplescompressed, compressed] = BandwidthCompression(rebuiltSignal, frameLength, CAST_FACTOR);  
audiowrite('Comp3.wav',downsamplescompressed, ceil(fs/CAST_FACTOR))

figure(1)
subplot(2,1,1)
plot(rec);
xlabel('sample'),ylabel('AMP'),title('Input audio');
subplot(2,1,2)
plot(compressed);
xlabel('sample'),ylabel('AMP'),title('Compressed Audio');

figure(2)
subplot(2,1,1)
specgram(rec);
title('Input audio');
subplot(2,1,2)
specgram(compressed);
title('Compressed Audio');

'done'