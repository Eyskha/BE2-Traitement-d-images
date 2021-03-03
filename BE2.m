clear
close all

%% 3.1 Digital image tranformation
% Conversion jpg to bmp
I = imread('Images\1.jpg');
imwrite(I,'Images\1.bmp') ;

% Get RGB image
I = imread('Images\1.bmp');
figure, subplot(3, 4, 1), imshow(I,[0,255]), title("I");

% Gray level image
G = rgb2gray(I);
subplot(3, 4, 2), imshow(G), title("G");

Gtranspose = 255 - G;
subplot(3, 4, 3), imshow(Gtranspose), title("Gtranspose");


%% 3.2 Enhancement of text region patterns
% Gray level to binary
threshold1 = 0.25;
Binary1 = im2bw(G,threshold1);
subplot(3, 4, 4), imshow(Binary1), title("Binary1 th = "+threshold1);

threshold2 = 0.5;
Binary2 = im2bw(G,threshold2);
subplot(3, 4, 5), imshow(Binary2), title("Binary2 th = "+threshold2);

threshold3 = 0.7;
Binary3 = im2bw(G,threshold3);
subplot(3, 4, 6), imshow(Binary3), title("Binary3 th = "+threshold3);

threshold4 = 0.75;
Binary4 = im2bw(G,threshold4);
subplot(3, 4, 7), imshow(Binary4), title("Binary4 th = "+threshold3);

Binary = Binary3;

% Multi-resolution method : nearest neighbour method
M = 0.125;
J = imresize(Binary,M);
subplot(3, 4, 8), imshow(J), title("J with th =" + threshold3);


%% 3.3 Potential text regions localization
ITextRegionControl = zeros(size(J));
ITextRegion = J;
while isequal(ITextRegion,ITextRegionControl)==false
    ITextRegionControl = ITextRegion;
    ITextRegion = firstmask(ITextRegion);
    ITextRegion = secondmask(ITextRegion);
    %ITextRegion = thirdmask(ITextRegion);
end
subplot(3, 4, 9), imshow(ITextRegion), title("ITextRegion");


%% 3.4 Selection of effective text regions
% Background pixels separation : back to G (gray levels image)

    % Contruction intervalle [u,L]
Hist = imhist(G);
subplot(3, 4, 10), plot(Hist), xlim([0 255]), title("G histogram");

thresholdSeparation = 0.02;

nbPixels = Hist(255); u = 255; L = 255;
[m,n] = size(G);
nbTotPixels = m*n;

while nbPixels <= thresholdSeparation*nbTotPixels
    u = u - 1;
    nbPixels = nbPixels + Hist(u);
end


    % Equation 2 transformation
G = double(G); %sinon pb avec multiplication matrice car int
G2 = uint8((G<=u).*G + (G>u)*L);
subplot(3, 4, 11), imshow(G2), title("G separation eq2");

    
G3 = uint8((G<=u)*u + (G>u)*L);
subplot(3, 4, 12), imshow(G3), title("G separation eq3");


% Effective text region filtering
% - Calcul distance entre maxs : si sup à un seuil (15po) alors calssifié comme region de texte

    % Get regions limits for low resolution
regionsLimitsRaw = regionprops(ITextRegion);
regionsLimitsLowRes = zeros(length(regionsLimitsRaw),4);
for i=1:length(regionsLimitsRaw)
    regionsLimitsLowRes(i,:) = floor(regionsLimitsRaw(i).BoundingBox);
end

    % Get regions limits for initial resolution
regionsLimitsHighRes = (regionsLimitsLowRes + [0 0 1 1])/M;
%rectangle('Position',regionsLimitsHighRes(1,:));

effectiveTextRegion = [];
thresholdTextRegion = 0.15;

figure();
for i=1:height(regionsLimitsHighRes)
    topleftx = regionsLimitsHighRes(i,1);
    toplefty = regionsLimitsHighRes(i,2);
    widthRect = regionsLimitsHighRes(i,3);
    heightRect = regionsLimitsHighRes(i,4);
    % Histogram for each region
    H = imhist(G2(toplefty:toplefty+heightRect,topleftx:topleftx+widthRect));
    subplot(3,3,i), plot(H), xlim([0 255]), title("Hist region "+i);
    
    % Get 2 highest local maxima
    H(257) = 0; % To get pick at 255
    [peaks, locs] = findpeaks(H,'SortStr','descend','NPeaks',2);
    findpeaks(H,'SortStr','descend','NPeaks',2);
    distMaxima = abs(locs(1) - locs(2));
    
    % Filter effective text regions
    if distMaxima > thresholdTextRegion
        effectiveTextRegion = [ effectiveTextRegion ; regionsLimitsHighRes(i,:)];
    end
end

    % Display of the text regions identified
figure(); imshow(I,[0,255]);
for i=1:height(effectiveTextRegion)
    rectangle('Position',effectiveTextRegion(i,:),'EdgeColor','r','LineWidth',1);
end
























%% Functions

% 3.3: 1st mask : Set all pixels to 1 when the border pixels on the left and on the right are valued by 1.
function J = firstmask(I)
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
function J = secondmask(I)
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
           if I(i,n-j+1)==1 && topright == 0 && j~=1
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
function J = thirdmask(I)
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
