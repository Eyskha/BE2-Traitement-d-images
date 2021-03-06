clear
close all

images = [1:13 26 39 123 129 185 5001 5003 5005 5007 7000 7003 7016:7018 7020 9000:9002 9005 9010 9013:9017 9019 9023 9026:9029 9031 9034 9035 9041 9043 9044 9048 9054 9057 9059 9060 9062 9063 9071 9074:9076 10001];
for i=21:21
    I = imread(strcat('Images\',num2str(images(i)),'.bmp'));
    resizeFactor = 80/length(I);
    thresholdBinary = 0.7;
    thresholdSelection = 0.05;
    thresholdTextRegionDistance = 0.15;
    thresholdM4 = 0.75;
    detection_texte(I,'.jpg',false,resizeFactor,thresholdBinary,thresholdSelection,thresholdTextRegionDistance,thresholdM4);
end

% thresholdBinary : si sup au seuil alors 1 sinon 0 pour image binaire. 
% thresholdSelection : 
% thresholdTextRegionDistance : si 

function detection_texte(image,type,intermediateDisplay,resizeFactor,thresholdBinary,thresholdSelection,thresholdTextRegionDistance,thresholdM4)
    %% 3.1 Digital image tranformation
    % Conversion jpg to bmp
%     I = imread(strcat('Images\',image,type));
%     imwrite(I,strcat('Images\',image,'.bmp'));

    % Get RGB image
    I = image;
    if intermediateDisplay
        figure, subplot(3, 4, 1), imshow(I,[0,255]), title("I");
    end

    % Gray level image
    G = rgb2gray(I);
    if intermediateDisplay
        subplot(3, 4, 2), imshow(G), title("G");
    end

    Gtranspose = 255 - G;
    if intermediateDisplay
        subplot(3, 4, 3), imshow(Gtranspose), title("Gtranspose");
    end
    
    % Background Pixel Separation
    G = bckgrndPixelSeparation(G,intermediateDisplay,thresholdSelection);


    %% 3.2 Enhancement of text region patterns
    % Gray level to binary
    threshold1 = 0.5;
    Binary1 = im2bw(G,threshold1);
    if intermediateDisplay
        subplot(3, 4, 4), imshow(Binary1), title("Binary1 th = "+threshold1);
    end

    threshold2 = 0.7;
    Binary2 = im2bw(G,threshold2);
    if intermediateDisplay
        subplot(3, 4, 5), imshow(Binary2), title("Binary2 th = "+threshold2);
    end
    
    Binary = im2bw(G,thresholdBinary);
    if intermediateDisplay
        subplot(3, 4, 6), imshow(Binary), title("Binary th = "+thresholdBinary);
    end

    % Multi-resolution method : nearest neighbour method
    J = imresize(Binary,resizeFactor);
    if intermediateDisplay
        subplot(3, 4, 7), imshow(J), title("J with th =" + thresholdBinary);
    end
    

    %% 3.3 Potential text regions localization
    ITextRegionControl = zeros(size(J));
    ITextRegion = J;
    
    ITextRegion = M4(ITextRegion,thresholdM4);
    ITextRegion = M5(ITextRegion);
    if intermediateDisplay
        subplot(3, 4, 8), imshow(ITextRegion), title("ITextRegion M45");
    end
    
    while ~isequal(ITextRegion,ITextRegionControl)
        ITextRegionControl = ITextRegion;
        ITextRegion = M1(ITextRegion);
        ITextRegion = M2(ITextRegion);
        %ITextRegion = M3(ITextRegion);
    end
    if intermediateDisplay
        subplot(3, 4, 9), imshow(ITextRegion), title("ITextRegion");
    end
    
    %% 3.4 Selection of effective text regions
    % Background pixels separation : back to G (gray levels image)
        % function Gsortie = bckgrndPixelSeparation(G)

    % Effective text region filtering
    % - Calcul distance entre maxs : si sup à un seuil (15po) alors calssifié comme region de texte

        % Get regions limits for low resolution
    regionsLimitsRaw = regionprops(ITextRegion);
    regionsLimitsLowRes = zeros(length(regionsLimitsRaw),4);
    for i=1:length(regionsLimitsRaw)
        regionsLimitsLowRes(i,:) = floor(regionsLimitsRaw(i).BoundingBox);
    end

        % Get regions limits for initial resolution
    regionsLimitsHighRes = floor(regionsLimitsLowRes/resizeFactor);
    
    rBis = []; % Ajust limits to enter image size
    for i=1:height(regionsLimitsHighRes)
        toplefty = max(regionsLimitsHighRes(i,1),1);
        topleftx = max(regionsLimitsHighRes(i,2),1);
        widthRect = regionsLimitsHighRes(i,3);        
        if toplefty+widthRect > width(I)
           widthRect = floor(widthRect - mod(width(I),1/resizeFactor) - 1);
        end
        heightRect = regionsLimitsHighRes(i,4);
        if topleftx+heightRect > height(I)
           heightRect = floor(heightRect - mod(height(I),1/resizeFactor));
        end
        rBis= [rBis ; [toplefty topleftx widthRect heightRect]];
    end
    regionsLimitsHighRes = rBis;
    
    regionsLimitsHighRes = improvementLocalization(G,regionsLimitsHighRes,255);

    effectiveTextRegion = [];

    if intermediateDisplay
        figure();
    end
    for i=1:height(regionsLimitsHighRes)
        toplefty = regionsLimitsHighRes(i,1);
        topleftx = regionsLimitsHighRes(i,2);
        widthRect = regionsLimitsHighRes(i,3);  
        heightRect = regionsLimitsHighRes(i,4);
        % Histogram for each region
        H = imhist(G(topleftx:topleftx+heightRect,toplefty:toplefty+widthRect));
        if intermediateDisplay
            subplot(3,3,i), plot(H), xlim([0 255]), title("Hist region "+i);
        end

        % Get 2 highest local maxima
        H(257) = 0; % To get pick at 255
        [peaks, locs] = findpeaks(H,'SortStr','descend','NPeaks',2);
        if intermediateDisplay
            findpeaks(H,'SortStr','descend','NPeaks',2);
        end
        distMaxima = abs(locs(1) - locs(2));

        % Filter effective text regions
        if distMaxima > thresholdTextRegionDistance*255
            effectiveTextRegion = [ effectiveTextRegion ; regionsLimitsHighRes(i,:)];
        end
    end
    
        % Display of the text regions identified
    figure(); imshow(I,[0,255]);
    for i=1:height(effectiveTextRegion)
        rectangle('Position',effectiveTextRegion(i,:),'EdgeColor','r','LineWidth',1);
    end

end

%% Functions
% 3.3: 1st mask : Set all pixels to 1 when the border pixels on the left and on the right are valued by 1.
function J = M1(I)
    J = I;
    [m,n] = size(I);
    for i=1:m 
        min = 0;
        max = 0;
        for j=1:n
           if I(i,j)==1
               if min == 0
                   min = j;
               else
                   max = j;
               end
           end
        end
        if min ~= 0 && max ~= 0
            J(i,min:max) = 1;
        end
    end
end

% 3.3: 2nd mask : leads to a diagonal closure when two border pixels on the diagonal are valued by 1
function J = M2(I)
    J = I;
    [m,n] = size(I);
    % Top left and bottom right corners
    for i=1:m-1
        topleft = 0;
        topright = 0;
        bottomleft = 0;
        bottomright = 0;
        for j=1:n
           % Get top left corner
           if I(i,j)==1 && topleft == 0 && j~=n
               topleft = j;
           end
           % Get top right corner
           if I(i,n-j+1)==1 && topright == 0 && j~=n
               topright = n-j+1;
           end
           % Get bottom right corner
           if topleft ~= 0 && I(i+1,j)==1
               bottomright = j;
           end
           % Get bottom left corner
           if topright ~= 0 && I(i+1,n-j+1)==1
               bottomleft = n-j+1;
           end
        end
        if topleft ~= 0 && bottomright ~= 0
            J(i:i+1,topleft:bottomright) = 1;
        end
        if topright ~= 0 && bottomleft ~= 0
            J(i:i+1,bottomleft:topright) = 1;
        end
    end
end

% 3.3: 3rd mask : similar to the previous one. It aims at a diagonal closure as well
function J = M3(I)
    J = I;
    [m,n] = size(I);
    % Top left and bottom right corners
    for i=1:m-1
        for j=1:n
            if (I(i,j) == 1 && I(i+1,j+1) == 1) || (I(i+1,j) == 1 && I(i,j+1) == 1)
                I(i:i+1,j:j+1) = 1;
            end
        end
    end
end

% 3.4 : Background pixels separation : back to G (gray levels image)
function Gsortie = bckgrndPixelSeparation(G,intermediateDisplay,thresholdSelection)
    % Contruction intervalle [u,L]
    Hist = imhist(G);
    if intermediateDisplay
        subplot(3, 4, 10), plot(Hist), xlim([0 255]), title("G histogram");
    end
    
    nbPixels = Hist(255); u = 255; L = 255;
    [m,n] = size(G);
    nbTotPixels = m*n;

    while nbPixels <= thresholdSelection*nbTotPixels
        u = u - 1;
        nbPixels = nbPixels + Hist(u);
    end
    
    G = double(G); %sinon pb avec multiplication matrice car int
    G2 = uint8((G<=u).*G + (G>u)*L);
    if intermediateDisplay
        subplot(3, 4, 11), imshow(G2), title("G separation eq2");
    end

    G3 = uint8((G<=u)*u + (G>u)*L);
    if intermediateDisplay
        subplot(3, 4, 12), imshow(G3), title("G separation eq3");
    end
    
    Gsortie = G2;
end

%3.5.1 Improving text region localization
function newTextRegionsLimits = improvementLocalization(G,textRegions,L)
    newTextRegionsLimits = [];
    % For each text region
    for r=1:height(textRegions)        
        % Parameters
        x = textRegions(r,2);
        y = textRegions(r,1);
        l = textRegions(r,3);
        h = textRegions(r,4);
        newX = 0; newY = 0; newL = 0; newH = 0;
        
        % Selection of a representative line
        max = 0;
        maxCurrentLine = 0;
        indexReference = x;
        for i=x:x+h
            for j=y:y+l
                if G(i,j)==L
                    maxCurrentLine = maxCurrentLine + 1;
                end
            end
            if max < maxCurrentLine
                max = maxCurrentLine;
                indexReference = i;
            end
        end
        
        % Comparison with precedent line to get newX
        newX = comparisonPrecedentLine(indexReference,y,l,G,L);
        
        % Comparison with next line to get newH
        newH = comparisonNextLine(indexReference,y,l,G,L)-newX;
        
        % No vertical changes for now
        newY = y;
        newL = l;
        for i=newX:newX+newH
            leftTest = 1; rightTest = 1;
            while rightTest && newY + newL < length(G)
                if G(i,newY + newL + 1)==L
                    newL = newL + 1;
                else
                    rightTest = 0;
                end
            end
            while leftTest && newY > 1
                if G(i,newY-1)==L
                    newY = newY - 1;
                    newL = newL + 1;
                else
                    leftTest = 0;
                end
            end
        end
        
        if newH ~= 0 && newL~=0
            newTextRegionsLimits = [newTextRegionsLimits ; [newY newX newL newH]];
        end
    end 
end

function x=comparisonPrecedentLine(indexLine,y,l,G,L)
    if indexLine == 1
        x = 1;
    else
        posR = []; posPrecR = [];
        for j=y:y+l
            if G(indexLine,j)==L
                posR = [posR j];
            end
            if G(indexLine-1,j)==L
                posPrecR = [posPrecR j];
            end
        end

        if length(intersect(posR,posPrecR))>0
            x = comparisonPrecedentLine(indexLine-1,y,l,G,L);
        else
            x = indexLine;
        end
    end
end

function h=comparisonNextLine(indexLine,y,l,G,L)
    if indexLine == height(G)
        h = height(G);
    else
        posR = []; posNextR = [];
        for j=y:y+l
            if G(indexLine,j)==L
                posR = [posR j];
            end
            if G(indexLine+1,j)==L
                posNextR = [posNextR j];
            end
        end

        if length(intersect(posR,posNextR))>0
            h = comparisonNextLine(indexLine+1,y,l,G,L);
        else
            h = indexLine;
        end
    end
end

%3.5.2 Negative form elimination
function J = M4(I,thresholdM4)
    J = I;
    [m,n] = size(I);
    for i=1:m
        left = 0;
        right = 0;
        j = 1;
        while (~left || ~right) && j <= n
           % Get left
           if left == 0 && I(i,j)==1
               left = j;
           end
           % Get right
           if right == 0 && I(i,n-j+1)==1
               right = n-j+1;
           end
           j = j+1;
        end
        if right-left > thresholdM4*n
            J(i,left+1:right-1) = 0;
        end
    end
end

function J = M5(I)
    J = I;
    [m,n] = size(I);
    for i=2:m-1
        for j=2:n-1
            if I(i,j)==1 && isequal(I(i-1,j-1:j+1),[0 0 0]) && isequal(I(i+1,j-1:j+1),[0 0 0]) && I(i,j-1)==0 && I(i,j+1)==0
                J(i,j) = 0;
            end
        end
    end
end













