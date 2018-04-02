function [stripInfo,registeredMovie,paddedReferenceImage,status]=aoRegStripOverlappingOneLine(refImage,desinusoidedMovie,sysPara,imagePara,varargin)
% Do registration with overlapping strips
%
% Syntax:
%    [registeredMovie,status]=aoRegStripOverlappingOneLine(refImage,desinusoidedMovie,sysPara,imagePara)
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
%    sysPara            -
%    imagePara          - Image parameters, such as size, frame number, and
%                         so on
%
% Outputs:
%    stripInfo          - Registration information for each strip in each
%                         frame in the input desinMovies
%    registeredMovie    - Registered movie, based on estimate motion
%    paddedReferenceImage - The reference image as padded for registration.
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
% Calculate number of strips that we will align in one frame.
nStrips = imagePara.H - (sysPara.stripSize-p.Results.LineIncrement);

%% Genereate ROI from reference image according to the sysPara.ROIx,sysPara.ROIy.
% First create an expanded image according to sysPara.ROIx,sysPara.ROIy
% parameters, then put reference image in the center.
paddedReferenceImage = p.Results.PadValue*(ones(2*sysPara.paddedSize+imagePara.H,2*sysPara.paddedSize+imagePara.W));
paddedReferenceImage = uint8(paddedReferenceImage);
paddedReferenceImage(sysPara.paddedSize+1:(sysPara.paddedSize+imagePara.H),...
    sysPara.paddedSize+1:(sysPara.paddedSize+imagePara.W))...
    = refImage;

%% Frame loop for motion estimation
for frameIdx = 1:length(desinusoidedMovie)
    if (p.Results.verbose)
        fprintf('Starting registration for frame %d\n',frameIdx);
    end
    
    % Get the frane for registration
    curImage = desinusoidedMovie(frameIdx).cdata;
    
    % Get all of the strips out of the current frame.
    % In a real time algorithm we would do this one strip at a time.
    %
    % This code needs to be modified to handle line increments greater than
    % 1.
    for i = 1:nStrips
        stripStart = i;
        stripData(:,:,i) = curImage(stripStart:(stripStart+sysPara.stripSize-1),:);
    end
    
    % Register each strip to the padded reference image
    for stripIdx = 1:nStrips
        if (p.Results.verbose)
            printN = 20;
            if (rem(stripIdx,printN) == 0)
                fprintf('\tStarting registration for strip %d of %d\n',stripIdx,nStrips);
            end
        end
        
        % Get current strip, as computed above
        curStrip = stripData(:,:,stripIdx);
        
        searchStripUpLeftx = stripIdx+sysPara.paddedSize;
        searchStripUpLefty = 1+sysPara.paddedSize;
        
        % Get the offset of search strip, based on last frame. If we have
        % searched the last strip in one frame, we use the movement as the
        % first strip offset in the next frame
        if (stripIdx==1 && frameIdx==1)
            % Call frame alignment routine here.  This searches until it
            % figures out where things area.  It may have to search more
            % widely.
            %
            % For first frame, has no history of eye positions to use.
            offsetSearchx = 0;
            offsetSearchy = 0;
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
        for dx = -sysPara.ROIx : sysPara.ROIx
            for dy = -sysPara.ROIy : sysPara.ROIy
                % Pull out a reference strip from the padded reference
                searchStripStartx = dx+searchStripUpLeftx;
                searchStripStarty = dy+searchStripUpLefty;
                %judge if the search exceed the border
                %                 if (searchStripStartx <= 0)
                %                     searchStripStartx = 1;
                %                 end
                %                 if (searchStripStarty <= 0)
                %                     searchStripStarty = 1;
                %                 end
                %Generate the search strip
                searchStrip = paddedReferenceImage(searchStripStartx:...
                    (searchStripStartx+sysPara.stripSize-1),...
                    searchStripStarty:...
                    (searchStripStarty+imagePara.W-1));
                %remove the padded effection by only calculating the strip
                % in the image area
                %                 if (searchStripStartx<sysPara.paddedSize)
                %                     searchStripStartx1 = 1;
                %                     searchStripEndx1 = sysPara.stripSize - (sysPara.paddedSize - searchStripStartx);
                %                 end
                %                 if (searchStripStartx>sysPara.paddedSize)
                %                     searchStripStartx1 = searchStripStartx - sysPara.paddedSize;
                %                     searchStripEndx1 = sysPara.stripSize-(searchStripStartx - sysPara.paddedSize);
                %                 end
                %                 if (searchStripStarty<sysPara.paddedSize)
                %                     searchStripStarty1 = 1;
                %                     searchStripEndy1 = imagePara.W - (sysPara.paddedSize - searchStripStarty)-1;
                %                 end
                %                 if (searchStripStarty>sysPara.paddedSize)
                %                     searchStripStarty1 = searchStripStarty - sysPara.paddedSize;
                %                     searchStripEndy1 = imagePara.W-(searchStripStarty - sysPara.paddedSize)-1;
                %                 end
                % limit the strips to remove the padded pixels
                %                 searchStrip1 = searchStrip(searchStripStartx1:searchStripEndx1,...
                %                                           searchStripStarty1:searchStripEndy1);
                %                 curStrip1 = curStrip(searchStripStartx1:searchStripEndx1,...
                %                                           searchStripStarty1:searchStripEndy1);
                % calculate the similarity for this offset
                theSimilarity = aoRegMatch(searchStrip,curStrip, ...
                    'SimilarityMethod',p.Results.SimilarityMethod);
                
                % Compare the results to what we've seen so far, always keeping
                % the best similarity match.
                if (theSimilarity>=bestSimilarity)
                    bestSimilarity = theSimilarity;
                    stripInfo(frameIdx,stripIdx).result = bestSimilarity;
                    stripInfo(frameIdx,stripIdx).dx = dx + offsetSearchx;
                    stripInfo(frameIdx,stripIdx).dy = dy + offsetSearchy;
                end
            end
        end
    end
    
    % Reconstruct a registered image given the motion estimate we obtained
    % above. This sits in the padded coordinate frame, because there is
    % no guarantee that it will fit exactly in the original size (that would
    % only happen if there is no movement.)
    %
    % This might turn into its own function soon.
    registeredImage = uint8((zeros(2*sysPara.paddedSize+imagePara.H,2*sysPara.paddedSize+imagePara.W)));
    for stripIdx = 1:nStrips
        
        % Calculate the up left point of the strip
        searchStripUpLeftx = stripIdx+sysPara.paddedSize;
        searchStripUpLefty = 1+sysPara.paddedSize;
        regStripStartx = stripInfo(frameIdx,stripIdx).dx+searchStripUpLeftx;
        regStripStarty = stripInfo(frameIdx,stripIdx).dy+searchStripUpLefty;
        
        % Fill the regImage
        registeredImage(regStripStartx:(regStripStartx+sysPara.stripSize-1),...
            regStripStarty:(regStripStarty+imagePara.W-1)) = stripData(:,:,stripIdx);
        
    end
    
    % Store this registered frame for output
    registeredMovie(:,:,frameIdx) = registeredImage;
    
    disp breakinghere;
end

%% Convert output back to uint8
registeredMovie = uint8(registeredMovie);

%% Report status.
%
% For now, always OK.
status = 1;

end