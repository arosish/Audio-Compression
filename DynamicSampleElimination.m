function [reducedFrame newFrameLength] = DynamicSampleElimination(frame, reductionPercent)

%Number of samples to remove
removeCount = floor(length(frame) * reductionPercent);
newFrameLength = length(frame) - removeCount;

%Calculate scaled log energy of the frames
frameLogEnergy = 10 * log10((frame.^2)) - max(10*log10(frame.^2)); %Pulls the first term to the 0 normal level

%find avarage energy
avrg = mean(frameLogEnergy);

%Sample threshold values
rangeHigh = 1.19;
rangeLow = 0.9;

%Make sure there are enough samples to remove with this while loop
boundedIndexes = [];
validIndexes = [];
validEnergies = [];
while (length(validIndexes) < removeCount) 
lowerT = avrg * rangeHigh;
upperT = avrg * rangeLow;
boundedIndexes = find( (frameLogEnergy > lowerT) & (frameLogEnergy < upperT));
boundedEnergies = frameLogEnergy(boundedIndexes);


%Check validity of boundedIndexes and check if the neighbouring samples are ?N TRANSITION
CHECK_RANGE = 3;
for ind = 1:length(boundedIndexes)
    if( (boundedIndexes(ind) > (1 + CHECK_RANGE*2)) && boundedIndexes(ind) < length(frame) - CHECK_RANGE*2)       
        previousEnergies = frameLogEnergy((boundedIndexes(ind) - CHECK_RANGE):(boundedIndexes(ind) - 1));
        nextEnergies = frameLogEnergy( (boundedIndexes(ind) + 1) : (boundedIndexes(ind) + CHECK_RANGE));

        if(mean(previousEnergies) < boundedEnergies(ind) && mean(nextEnergies) > boundedEnergies(ind))
            %'increasing'
            validIndexes  = [validIndexes boundedIndexes(ind)];
            validEnergies  = [validEnergies boundedEnergies(ind)];
        elseif (mean(previousEnergies) > boundedEnergies(ind) && mean(nextEnergies) < boundedEnergies(ind))
            %'decreasing'
            validIndexes  = [validIndexes boundedIndexes(ind)];
            validEnergies  = [validEnergies boundedEnergies(ind)];
        else
            %Bounded value is a peak
        end               
    end
end

%If there arent "valid" samples to remove, increase thresholds
if (length(validIndexes) < removeCount)
    rangeHigh = rangeHigh + (rangeHigh * 0.06);
    rangeLow = rangeLow - (rangeLow * 0.06);
end
end

%Find and remove <removeCount> samples by removing the smallest value first, then find the next smallest value, repeat
reducedFrame = frame;
for rc = 1:removeCount
    
    %switch between max and mix equally
    if (mod(rc, 2) == 0)
        [M, I] = max(validEnergies); 
    else
        [M, I] = min(validEnergies); 
    end
  
    SmoothedSamplePercent = 0.03; % framelength's x% of samples are smoothed out by a margin of the removed sample 
    SmoothHardness = 0.3;   %maximum additive from the sample that is going to be removed
    
    numberOfSamplesToSmooth = floor(newFrameLength * SmoothedSamplePercent);
    
    for Lrft = 1:numberOfSamplesToSmooth
        
        %Smooth out the neighbouring samples
        if(~(I - Lrft < 1))  %Previous samples
            reducedFrame(I - Lrft) = reducedFrame(I - Lrft) - (reducedFrame(I) * (SmoothHardness - SmoothHardness*((1/Lrft))));  %Reduce previous sample magnitude by a margin of the removed ssample
        end

        if(~(I + Lrft > newFrameLength))%Next samples
            reducedFrame(I + Lrft) =  reducedFrame(I + Lrft) + (reducedFrame(I)  *  (SmoothHardness - SmoothHardness*((1/Lrft)))); %increase next sample magnitude by a margin of the removed ssample
        end
    end

    reducedFrame(I) = [];   %Remove sample
end
end