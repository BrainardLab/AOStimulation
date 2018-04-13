

for ii = 1:nLines
    theLine = inputImage(ii,:)';
    outputLine = (vertical_fringes_matrix*theLine)';
    outputImage(ii,:) = outputLine;
end