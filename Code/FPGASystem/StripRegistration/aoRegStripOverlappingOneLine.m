function [stripInfo,registeredMovie,status]=aoRegStripOverlappingOneLine(refImage,desinusoidedMovie,sysPara,imagePara,varargin)
% Do registration with overlapping strips
%
% Syntax:
%    [stripInfo,registeredMovie,status]=aoRegStripOverlappingOneLine(refImage,desinusoidedMovie,sysPara,imagePara,varargin)
%
% Description:
%    Registration algorithm, early draft
%
%    At present, just registers the first frame of the passed movie to the
%    reference frame.
%
% Inputs:
%    refImage           - Ref frame, used to registration.
%    desinusoidedMovie  - Movies after desinusoiding
%    sysPara            - system parameters
%    imagePara          - Image parameters, such as size, frame number, and
%                         so on
%
% Outputs:
%    stripInfo          - Registration information for each strip in each
%                         frame in the input desinMovies
%    registeredMovie    - Registered movie, based on estimate motion
%    status             - Status tells if things are ok.  1 means OK, 0
%                         means error.
%
% Optional key/value pairs:
%    'SimilarityMethod' - String, specify similarity method (default
%                         'NCC'). This is passed to the underlying routine
%                         asRegMatch that computes similarity.
%    'WhichFrame'       - Value.  If 0, the whole movie is analyzed.  If it
%                         is an integer greater than 1, we just analyze
%                         that frame (default 1).
%    'PadValue'         - The value to use to pad the reference image
%                         (default 0).
%    'NextFrameStripEdgeOffset' - After the first frame, we want to use the
%                         position obtained towards the end of the previous
%                         frame to guide the search locations.  The most
%                         natural strip to use seems like the last one, as
%                         that is most recent. But, there can be edge
%                         effcts making its position unreliable. So we back
%                         off from that by a specified number of strips.
%                         This parameter determines how many.
%    'LineIncrement'    - How far along we increment the strip in the
%                         vertical direction (default 1).
%    'verbose'          - Boolean, print out stuff (default true);
%
% See also: aoRegMatch.
%

% History:
%   03/14/18  tyh

% Parse
p = inputParser;
p.addParameter('SimilarityMethod','NCC',@ischar);
p.addParameter('WhichFrame',1,@isnumeric);
p.addParameter('PadValue',0,@isnumeric);
p.addParameter('NextFrameStripEdgeOffset',10,@isscalar);
p.addParameter('LineIncrement',1,@isnumeric);
p.addParameter('verbose',true,@islogical);
p.parse(varargin{:});

% Loop over movie frames
if (p.Results.WhichFrame > 0)
    theFramesToExamine = p.Results.WhichFrame;
else
    theFramesToExamine = 1:length(desinusoidedMovie);
end

%% Strip increments one line at a time.
%
%Initial the search center width and height
centerWidth = imagePara.W-2*sysPara.shrinkSize;
centerHeight = imagePara.H-2*sysPara.shrinkSize;

% Calculate number of strips that we will align in one frame.
nStrips = centerHeight - (sysPara.stripSize-p.Results.LineIncrement);

%Initialize the search range
% searchRangex = sysPara.searchRangeSmallx;
% searchRangey = sysPara.searchRangeSmally;
searchRangex = sysPara.searchRangeBigx;
searchRangey = sysPara.searchRangeBigy;

%Initial the best similarity
bestSimilarity = -inf;

%Movie size
[s1,s2,s3]=size(desinusoidedMovie);

%% Frame loop for motion estimation
for frameIdx = 1:s3
    if (p.Results.verbose)
        fprintf('Starting registration for frame %d\n',frameIdx);
    end
    
    % Get the frame for registration
    curImage = desinusoidedMovie(:,:,frameIdx);
    
    % Initial bigMovementFlag. When big movement appears the 
    bigMovementFlag = 0;
    
    %Initial the abnormal count. The abnormal means the small similarity.
    StripsAbnormalCount = 0;
    
    %Initial the current frame flag, frameAvailableFlag = 1 means it is
    %good for registration.
    stripInfo(frameIdx).frameAvailableFlag = 1;
    
    % Get all of the strips out of the current frame.
    % In a real time algorithm we would do this one strip at a time.
    for i = 1:nStrips
        stripStart = i+sysPara.shrinkSize;
        stripData(:,:,i) = curImage(stripStart:(stripStart+sysPara.stripSize-1),sysPara.shrinkSize+1:centerWidth+sysPara.shrinkSize);
    end
    
    % Register each strip to the padded reference image
    for stripIdx = 1:nStrips
        if (p.Results.verbose)
            printN = 20;
            if (rem(stripIdx,printN) == 0)
                fprintf('\tStarting registration for strip %d of %d',stripIdx,nStrips);
                fprintf('\tSimilarity is equal to %d\n', bestSimilarity);
            end
        end
        
        % Get current strip. Choose the center part
        curStrip = stripData(:,:,stripIdx);
        
        % Set the up left point place
        searchStripUpLeftx = stripIdx+sysPara.shrinkSize;
        searchStripUpLefty = 1+sysPara.shrinkSize;
                
        % Get the offset of search strip, based on last frame. If we have
        % searched the last strip in one frame, we use the movement as the
        % first strip offset in the next frame
        if (stripIdx==1 && frameIdx==1 || bigMovementFlag==1) 
            % Call frame alignment routine here.  This searches until it
            % figures out where things area.  It may have to search more
            % widely.
            %
            % For first frame, has no history of eye positions to use.
            offsetSearchx = 0;
            offsetSearchy = 0;
            
            %adjust to be big search arange
            searchRangex = sysPara.searchRangeBigx;
            searchRangey = sysPara.searchRangeBigy;
        elseif (stripIdx==1 && frameIdx>1)
            % Call frame alignment routine here.  This searches until it
            % figures out where things area.  It may have to search more
            % widely.
            %
            % If previous frame was successfully aligned, can use dx and dy
            % positions from that frame to guess where eye is at start of
            % frame.  May want to use linear prediction.
            offsetSearchx = stripInfo(frameIdx-1,nStrips-p.Results.NextFrameStripEdgeOffset).dx;
            offsetSearchy = stripInfo(frameIdx-1,nStrips-p.Results.NextFrameStripEdgeOffset).dy;
        else
            % Call strip alignment routine here.  This has the advantage of
            % receiving a pretty good estimate of where things are.
            offsetSearchx = stripInfo(frameIdx,stripIdx-1).dx;
            offsetSearchy = stripInfo(frameIdx,stripIdx-1).dy;
        end
        
        % Add offset based on our best guess for alignment
        searchStripUpLeftx = searchStripUpLeftx + offsetSearchx;
        searchStripUpLefty = searchStripUpLefty + offsetSearchy;
        
        % Here we loop over all possible regions of the reference image and
        % compute the similarity between that and the current strip for each.
        % We retain the dx,dy shift that leads to the best similarity.
        %
        % Start by initializing the similarity to very small value
        bestSimilarity = -Inf;
        
        % Then the loop
        for dx = -searchRangex : searchRangex
            for dy = -searchRangey : searchRangey
                % Pull out a reference strip from the padded reference
                searchStripStartx = dx+searchStripUpLeftx;
                searchStripStarty = dy+searchStripUpLefty;
                
                %Limit the start range to prevent overflow
                if (searchStripStartx < 1)
                    searchStripStartx = 1;
                elseif (searchStripStartx > imagePara.H-sysPara.stripSize)
                    searchStripStartx = imagePara.H-sysPara.stripSize;
                end
                if (searchStripStarty < 1)
                    searchStripStarty = 1;
                elseif (searchStripStarty > imagePara.W-centerWidth)
                    searchStripStarty = imagePara.W-centerWidth;
                end
                                
                %Generate the search strip
                searchStrip = refImage(searchStripStartx:...
                    (searchStripStartx+sysPara.stripSize-1),...
                    searchStripStarty:...
                    (searchStripStarty+centerWidth-1));
 
                % calculate the similarity for this offset
                theSimilarity = aoRegMatch(searchStrip,curStrip, ...
                    'SimilarityMethod',p.Results.SimilarityMethod);
                
                % Compare the results to what we've seen so far, always keeping
                % the best similarity match.
                if (theSimilarity>bestSimilarity)
                    bestSimilarity = theSimilarity;
                    dxTemp = dx;
                    dyTemp = dy;
                end
            end
        end
        
        % Keeping the best similarity match
        stripInfo(frameIdx,stripIdx).result = bestSimilarity;
        
        % If the matching is not good, namely the similarity is too
        % small, the matching is unvalid and the match of the last strip is
        % looked as the current strip's.
        if ((stripIdx == 1) & (bestSimilarity<sysPara.similarityThrBig))
            stripInfo(frameIdx,stripIdx).dx =  offsetSearchx;
            stripInfo(frameIdx,stripIdx).dy =  offsetSearchy;
        elseif (bestSimilarity<sysPara.similarityThrBig)
            stripInfo(frameIdx,stripIdx).dx =  stripInfo(frameIdx,stripIdx-1).dx;
            stripInfo(frameIdx,stripIdx).dy =  stripInfo(frameIdx,stripIdx-1).dy;
        else
            stripInfo(frameIdx,stripIdx).dx =  dxTemp + offsetSearchx;
            stripInfo(frameIdx,stripIdx).dy =  dyTemp + offsetSearchy;
        end
        
        % If current strip has good similarity, adjust the search range to 
        % be small so that the code can be ran fast. Otherwise, adjust the
        % range to the big search range.
        if (bestSimilarity>sysPara.similarityThrBig)
            searchRangex = sysPara.searchRangeSmallx;
            searchRangey = sysPara.searchRangeSmally;
            bigMovementFlag = 0;
        elseif (bestSimilarity<sysPara.similarityThrSmall)
            searchRangex = sysPara.searchRangeBigx;
            searchRangey = sysPara.searchRangeBigy;
            bigMovementFlag = 1;
        end
        
        % If the next 3 strips has small similarity, stop this frame search
        if (bigMovementFlag)
            StripsAbnormalCount = StripsAbnormalCount +1;
        else
            StripsAbnormalCount = 0;
        end
        
        %If count to max, the search failed and give one flag to save this. 
        if (StripsAbnormalCount==sysPara.maxStripsAbnormalCount)
            
            %Set flag to 0, means this frame is bad for registration.
            stripInfo(frameIdx).frameAvailableFlag = 0;
            
            %Set result to 0
            for iz=stripIdx:nStrips
                stripInfo(frameIdx,iz).result = 0;
                stripInfo(frameIdx,iz).dx =  0;
                stripInfo(frameIdx,iz).dy =  0;
            end
            
            %reset the counter
            StripsAbnormalCount = 0;
            
            %quit the strip loop
            break;
            
        else
            
            %Set flag to 1, means this frame is bad for registration.
            stripInfo(frameIdx).frameAvailableFlag = 1;
            
        end
    end
           
    % Reconstruct a registered image given the motion estimate we obtained
    % above. This sits in the padded coordinate frame, because there is
    % no guarantee that it will fit exactly in the original size (that would
    % only happen if there is no movement.)
    %
    % This might turn into its own function soon.
    registeredImage = uint8((zeros(imagePara.H,imagePara.W)));
    for stripIdx = 1:nStrips
        
        % Calculate the up left point of the strip
        searchStripUpLeftx = stripIdx+sysPara.shrinkSize;
        searchStripUpLefty = 1+sysPara.shrinkSize;
        regStripStartx = stripInfo(frameIdx,stripIdx).dx+searchStripUpLeftx;
        regStripStarty = stripInfo(frameIdx,stripIdx).dy+searchStripUpLefty;
        
        %Limite the range to prevent overflow
        if (regStripStartx < 1)
            regStripStartx = 1;
        end
        if (regStripStarty < 1)
            regStripStarty = 1;
        end
        % Fill the regImage
%         registeredImage(regStripStartx:(regStripStartx+sysPara.stripSize-1),...
%             regStripStarty:(regStripStarty+centerWidth-1)) = stripData(:,:,stripIdx);
        registeredImage(regStripStartx,...
            regStripStarty:(regStripStarty+centerWidth-1))...
                       = stripData(1,:,stripIdx);
        
    end
    
    % Store this registered frame for output
    registeredMovie(:,:,frameIdx) = registeredImage;
end

%% Convert output back to uint8
registeredMovie = uint8(registeredMovie);

%% Report status.
%
% For now, always OK.
status = 1;

end