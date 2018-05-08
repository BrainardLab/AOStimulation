function aoAnalyzeRegisterData(theData,outputDir)
% Analyze the registration algorithm's performance
%
% Syntax:
%    aoAnalyzeRegisterData(theData,outputDir)
%
% Description:
%    Analyze and plot how well a registration worked. Save out information
%    so we can look at it later.
%
% Inputs:
%    theData          - Algorithms's data
%    outputDir        - Output directory
%
% Optional key/value pairs:
%    None.
%
% See also:
%

% History:
%   05/07/18  tyh

%% Unpack some info for analysis/plotting
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
for ii = 1:theData.actualMovieLength
    % Get movement data for this frame
    dxValues = testDx(:,ii);
    dxValuesTotal = [dxValuesTotal dxValues'];
    dyValues = testDy(:,ii);
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
    bestSimilarity = testSimilarity(:,ii);
    bestSimilarityTotal = [bestSimilarityTotal bestSimilarity'];
    %     figure;
    %     plot(1:length(bestSimilarity),bestSimilarity,'ro','MarkerSize',6,'MarkerFaceColor','r');
    %     ylabel('Similarity')
    %     xlabel('Strip number');
    %     title(sprintf('Frame %d',ii));
    
    % Report largest strip-by-strip shifts
    %maxLineDx = max(abs(diff(dxValues)));
    %maxLineDy = max(abs(diff(dyValues)));
    %fprintf('Frame %d, maximum dx difference: %d, maximum dy  difference: %d\n',ii,maxLineDx,maxLineDy);
end

% Plot the all frames' dy/dx
frame_length = length(dxValuesTotal)/theData.actualMovieLength;

% Figure for displacement
dFig = figure;hold on
for ii=1:theData.actualMovieLength
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
    
    ylim([-150 150]);
end
ylabel('Displacement (pixels)')
xlabel('Strip number');
title(sprintf('All Frames displacement for %s', theData.similarityMethod));
hold off

% Save Figure
figureName = fullfile(outputDir,'displacment.jpg');
saveas(dFig, figureName);

% Plot all similarity
sFig = figure; hold on
for ii=1:theData.actualMovieLength
    bestSimilarity1=bestSimilarityTotal(1+(ii-1)*frame_length:ii*frame_length);
    if (mod(ii,2)==0)
        plot(1+(ii-1)*frame_length:ii*frame_length,bestSimilarity1,'ro','MarkerSize',3,'MarkerFaceColor','r');
    else
        plot(1+(ii-1)*frame_length:ii*frame_length,bestSimilarity1,'go','MarkerSize',3,'MarkerFaceColor','g');
    end
    ylim([0 2]);
end
ylabel('Similarity')
xlabel('Strip number');
title(sprintf('All Frames Similiary for %s', theData.similarityMethod));
hold off

% Save Figure
figureName1 = fullfile(outputDir,'similarity.jpg');
saveas(sFig, figureName1);

end
