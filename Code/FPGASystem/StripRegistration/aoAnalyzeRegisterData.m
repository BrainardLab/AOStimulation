function aoAnalyzeRegisterData(theData,outputDir)


% Unpack some info for analysis/plotting
for frameIdx = 1:theData.actualMovieLength
    testDx(:,frameIdx) = [theData.stripInfo(frameIdx,:).dx];
    testDy(:,frameIdx) = [theData.stripInfo(frameIdx,:).dy];
    testSimilarity(:,frameIdx) = [theData.stripInfo(frameIdx,:).result];
end
            
%% Analyze results
%
%  Initialize the total movement dx/dy
dxValuesTotal = [];
dyValuesTotal = [];

% Initialize all frames' similarity
bestSimilarityTotal = [];

% Make plots showing diff between different method
for ii = 1:actualMovieLength
    % Get movement data for this frame
    dxValues = testDx(:,ii,1)-testDx(:,ii,2);
    dxValuesTotal = [dxValuesTotal dxValues'];
    dyValues = testDy(:,ii,1)-testDy(:,ii,2);
    dyValuesTotal = [dyValuesTotal dyValues'];
    
    %     % Plot movement data
    %     figure; hold on
    %     plot(1:length(dxValues),dxValues,'ro','MarkerSize',8,'MarkerFaceColor','r');
    %     plot(1:length(dyValues),dyValues,'bo','MarkerSize',6,'MarkerFaceColor','b');
    %     ylim([-9*theData.sysPara.searchRangeSmallx 9*theData.sysPara.searchRangeSmallx]);
    %     ylabel('Displacement (pixels)')
    %     xlabel('Strip number');
    %     title(sprintf('Frame %d',ii));
    
    % Report the matching result? CC value
    bestSimilarity = testSimilarity(:,ii,1)-testSimilarity(:,ii,2);
    bestSimilarityTotal = [bestSimilarityTotal bestSimilarity'];
    %     figure;
    %     plot(1:length(bestSimilarity),bestSimilarity,'ro','MarkerSize',6,'MarkerFaceColor','r');
    %     ylabel('Similarity')
    %     xlabel('Strip number');
    %     title(sprintf('Frame %d',ii));
    
    % Report largest strip-by-strip shifts
    maxLineDx = max(abs(diff(dxValues)));
    maxLineDy = max(abs(diff(dyValues)));
    fprintf('Frame %d, maximum dx difference: %d, maximum dy  difference: %d\n',ii,maxLineDx,maxLineDy);
end

% Plot the all frames' dy/dx
frame_length = length(dxValuesTotal)/actualMovieLength;

% Figure for displacement
figure;hold on
for ii=1:actualMovieLength
    dxValues=dxValuesTotal(1+(ii-1)*frame_length:ii*frame_length);
    dyValues=dyValuesTotal(1+(ii-1)*frame_length:ii*frame_length);
    if (mod(ii,2)==0)
        plot(1+(ii-1)*frame_length:ii*frame_length,dxValues,'ro','MarkerSize',3,'MarkerFaceColor','r');
        plot(1+(ii-1)*frame_length:ii*frame_length,dyValues,'bo','MarkerSize',3,'MarkerFaceColor','b');
    else
        plot(1+(ii-1)*frame_length:ii*frame_length,dxValues,'go','MarkerSize',3,'MarkerFaceColor','g');
        plot(1+(ii-1)*frame_length:ii*frame_length,dyValues,'yo','MarkerSize',3,'MarkerFaceColor','y');
    end
    
    %         plot(ii,dxValuesTotal(ii),'o','color',[bestSimilarityTotal(ii) 0 0],'MarkerFaceColor',[bestSimilarityTotal(ii) 0 0]);
    %         plot(ii,dyValuesTotal(ii),'o','color',[0 0 bestSimilarityTotal(ii)],'MarkerFaceColor',[0 0 bestSimilarityTotal(ii)]);
    
    ylim([-9 9]);
end
ylabel('Displacement diff (pixels)')
xlabel('Strip number');
title(sprintf('All Frames displacement diff'));
hold off

% Plot all similarity
figure; hold on
for ii=1:actualMovieLength
    bestSimilarity1=bestSimilarityTotal(1+(ii-1)*frame_length:ii*frame_length);
    if (mod(ii,2)==0)
        plot(1+(ii-1)*frame_length:ii*frame_length,bestSimilarity1,'ro','MarkerSize',3,'MarkerFaceColor','r');
    else
        plot(1+(ii-1)*frame_length:ii*frame_length,bestSimilarity1,'go','MarkerSize',3,'MarkerFaceColor','g');
    end
    ylim([-1 1]);
end
ylabel('Similarity diff')
xlabel('Strip number');
title(sprintf('All Frames Similiary diff'));
hold off

end
