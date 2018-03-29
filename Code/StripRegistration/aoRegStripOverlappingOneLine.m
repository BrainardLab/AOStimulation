function [stripInfo,registeredImage,status]=aoRegStripOverlappingOneLine(refImage,desinusoidedMovie,sysPara,imagePara,varargin)
% Do registration with overlapping strips
%
% Syntax:
%    [regImage,status]=aoRegStripOverlappingOneLine(refImage,desinusoidedMovie,sysPara,imagePara)
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
%    registeredImage    - Registered image, based on estimate motion
%    status             - Status tells if things are ok.  1 means OK, 0
%                         means error.
%
% Optional key/value pairs:
%    'SimilarityMethod' - String, specify similarity method (default
%                         'NCC'). This is passed to the underlying routine
%                         asRegMatch that computes similarity.
%    'verbose'          - Boolean, print out stuff (default true);
%
% See also: aoRegMatch.
%

% History:
%   03/14/18  tyh

% Parse
p = inputParser;
p.addParameter('SimilarityMethod','NCC',@ischar);
p.addParameter('verbose',true,@islogical);
p.parse(varargin{:});

% Loop over movie frames
% This will become a loop over frames at
% some point.
theFrameToExamine = 1;
for frameIdx = theFrameToExamine
    if (p.Results.verbose)
        fprintf('Starting registration for frame %d\n',frameIdx);
    end
    
    % Get the frane for registration
    curImage = desinusoidedMovie(frameIdx).cdata;
    
    %% Strip increments one line at a time.
    %
    % Calculate number of strips that we will align in one frame.
    lineIncrement = 1;
    nStrips = imagePara.H - (sysPara.stripSize-lineIncrement);
    
    %% Genereate ROI from reference image according to the sysPara.ROIx,sysPara.ROIy.
    % First create an expanded image according to sysPara.ROIx,sysPara.ROIy
    % parameters, then put reference image in the center.
    padValue = 255;
    roiImage = padValue*(ones(2*sysPara.ROIy+imagePara.H,2*sysPara.ROIx+imagePara.W));
    roiImage = uint8(roiImage);
    roiImage(sysPara.ROIy:(sysPara.ROIy+imagePara.H-1),...
        sysPara.ROIx:(sysPara.ROIx+imagePara.W-1))...
        = refImage;
    
    %% Get all of the strips out of the current frame.
    % In a real time algorithm we would do this one strip at a time.
    for i = 1:nStrips
        stripStart = i;
        stripData(:,:,i) = curImage(stripStart:(stripStart+sysPara.stripSize-1),:);
    end
    
    %% Register each strip to the padded reference image
    for stripIdx = 1:nStrips
        if (p.Results.verbose)
            printN = 20;
            if (rem(stripIdx,printN) == 0)
                fprintf('\tStarting registration for strip %d of %d\n',stripIdx,nStrips);
            end
        end
        
        % Get current strip, as computed above
        curStrip = stripData(:,:,stripIdx);
        
        searchStripUpLeftx = stripIdx+sysPara.ROIx;
        searchStripUpLefty = 1+sysPara.ROIy;
        bestSimilarity = -Inf;
        
        % Here we loop over all possible regions of the reference image and
        % compute the similarity between that and the current strip for each.
        % We retain the dx,dy shift that leads to the best similarity.
        for dx = -sysPara.ROIx : sysPara.ROIx
            for dy = -sysPara.ROIy : sysPara.ROIy
                % Pull out a reference strip from the padded reference
                searchStripStartx = dx+searchStripUpLeftx;
                searchStripStarty = dy+searchStripUpLefty;
                searchStrip = roiImage(searchStripStartx:...
                    (searchStripStartx+sysPara.stripSize-1),...
                    searchStripStarty:...
                    (searchStripStarty+imagePara.W-1));
                
                % calculate the similarity for this offset
                theSimilarity = aoRegMatch(searchStrip,curStrip, ...
                    'SimilarityMethod',p.Results.SimilarityMethod);
                
                % Compare the results to what we've seen so far, always keeping
                % the best similarity match.
                if (theSimilarity>bestSimilarity)
                    stripInfo(frameIdx,stripIdx).bestSimilarity = theSimilarity;
                    stripInfo(frameIdx,stripIdx).result = bestSimilarity;
                    stripInfo(frameIdx,stripIdx).dx = dx;
                    stripInfo(frameIdx,stripIdx).dy = dy;
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
    registeredImage = uint8((zeros(2*sysPara.ROIy+imagePara.H,2*sysPara.ROIx+imagePara.W)));
    for stripIdx = 1:nStrips
        
        % Calculate the up left point of the strip
        searchStripUpLeftx = stripIdx+sysPara.ROIx;
        searchStripUpLefty = 1+sysPara.ROIy;
        regStripStartx = stripInfo(frameIdx,stripIdx).dx+searchStripUpLeftx;
        regStripStarty = stripInfo(frameIdx,stripIdx).dy+searchStripUpLefty;
        
        % Fill the regImage
        registeredImage(regStripStartx:(regStripStartx+sysPara.stripSize-1),...
            regStripStarty:(regStripStarty+imagePara.W-1)) = stripData(:,:,stripIdx);
        
    end
    
end

%% Report status.
%
% For now, always OK.
status = 1;