clear
close all

%liste contenant les numeros des différentes images
images = [1:13 26 39 123 129 185 5001 5003 5005 5007 7000 7003 7016:7018 7020 9000:9002 9005 9010 9013:9017 9019 9023 9026:9029 9031 9034 9035 9041 9043 9044 9048 9054 9057 9059 9060 9062 9063 9071 9074:9076 10001];

figure("Name","0.02 ; 0.7 ; 80 ; 0.15 ; 0.75");
place = 1;
for i=[1 2 4 14  15 19 20 30 31 32 33 36 37 38 39 40 43 44 47 55] %les images que l'on souhaite traiter
    I = imread(strcat('Images\',num2str(images(i)),'.bmp')); %on importe l'image
    thresholdSelection = 0.02; %seuil pour la mise en avant du texte
    thresholdBinary = 0.7; %seuil pour le passage en binaire
    resizeFactor = 80/length(I); %seuil de redimensionnement (M) : on passe toutes les images à 80 px
    thresholdTextRegionDistance = 0.15; %seuil pour distinction des zones de texte réelles
    thresholdM4 = 0.75; %seuil pour le masque 4
    subplot(4,5, place); 
    detection_texte(I,'.jpg',false,thresholdSelection,thresholdBinary,resizeFactor,thresholdTextRegionDistance,thresholdM4); %lancement de la méthode
    title(num2str(images(i)));
    place = place + 1;
end

% Paramètres qui fonctionnent pour les images indiquées et images restantes

% "0.02 ; 0.7 ; 80 ; 0.15 ; 0.75" → images en indices : [1 2 4 14  15 19 20 30 31 32 33 36 37 38 39 40 43 44 47 55]
%                               reste : [3 5:13 16:18 21:29 34 35 41 42 45 46 48:54 56:62]
% "0.01 ; 0.7 ; 80 ; 0.15 ; 0.75" → images en indices : [52]
%                               reste : [3 5:13 16:18 21:29 34 35 41 42 45 46 48:51 53 54 56:62]
% "0.25 ; 0.7 ; 80 ; 0.15 ; 0.75" → images en indices : [21]
%                               reste : [3 5:13 16:18 22:29 34 35 41 42 45 46 48:51 53 54 56:62]
% "0.1 ; 0.7 ; 80 ; 0.15 ; 0.75" → images en indices : [34 35 45 48 53 54]
%                               reste : [3 5:13 16:18 22:29 41 42 46 49:51 56:62]
% "0.07 ; 0.7 ; 80 ; 0.15 ; 0.75" → images en indices : [29 46]
%                               reste : [3 5:13 16:18 22:28 41 42 49:51 56:62]
% "0.05 ; 0.7 ; 80 ; 0.15 ; 0.75" → images en indices : [11 59]
%                               reste : [3 5:10 12 13 16:18 22:28 41 42 49:51 56:58 60:62]
% "0.012 ; 0.46 ; 80 ; 0.15 ; 0.75" → images en indices : [3 6 12 41 58]
%                               reste : [5 7:10 13 16:18 22:28 42 49:51 56 57 60:62]
% "0.01 ; 0.2 ; 50 ; 0.15 ; 0.75" → images en indices : [26 27]
%                               reste : [5 7:10 13 16:18 22:25 28 42 49:51 56 57 60:62]


%Explications supplémentaires pour les seuils

% thresholdSelection : si dans les pixels les plus clairs (seuil = % de 
%    pixels) alors mis à 255 dans image en niveaux de gris

% thresholdBinary : si sup au seuil alors 1 sinon 0 pour image binaire

% thresholdTextRegionDistance : si distance des 2 plus hauts pics de 
%    l'histogramme est inférieure au seuil alors supprimée des regions de
%    textes

% thresholdM4 : pourcentage de la taille de l'image, si distance entre 2
%    pixels blancs est supérieure au seuil alors pixels entre 2 mis à 0


%la fonction qui lance la méthode complète
function f=detection_texte(image,type,intermediateDisplay,thresholdSelection,thresholdBinary,resizeFactor,thresholdTextRegionDistance,thresholdM4)
    %% 3.1 Digital image tranformation
    % Conversion jpg to bmp
%     I = imread(strcat('Images\',image,type));
%     imwrite(I,strcat('Images\',image,'.bmp'));

    % Get RGB image
    I = image;
    if intermediateDisplay %si on souhaite afficher les différentes étapes pour chaque image
        figure, subplot(2,5,1), imshow(I,[0,255]), title("Initial Image");
    end

    % Gray level image : conversion en niveaux de gris
    G = rgb2gray(I);
    if intermediateDisplay %plot intermédiaire
        subplot(2,5,2), imshow(G), title("Grayscale image");
    end

    Gtranspose = 255 - G; %traitement pour les images à texte foncé sur fond clair
    if intermediateDisplay %plot intermédiaire
        subplot(2,5,3), imshow(Gtranspose), title("Grayscale transposed");
    end
    
    % Background Pixel Separation : fonction plus bas
    G = bckgrndPixelSeparation(G,intermediateDisplay,thresholdSelection);


    %% 3.2 Enhancement of text region patterns
    % Gray level to binary
    Binary = im2bw(G,thresholdBinary); %passage en binaire
    if intermediateDisplay %plot intermédiaire
        subplot(2,5,4), imshow(Binary), title("Binary Image, threshold = "+thresholdBinary);
    end

    % Multi-resolution method : nearest neighbour method
    J = imresize(Binary,resizeFactor); %redimensionnement de l'image binaire
    if intermediateDisplay %plot intermédiaire
        subplot(2,5,5), imshow(J), title("BW redimensionned, th =" + thresholdBinary);
    end
    

    %% 3.3 Potential text regions localization
    ITextRegionControl = zeros(size(J)); %critère d'arret de la boucle while
    ITextRegion = J;
    
    ITextRegion = M4(ITextRegion,thresholdM4);%on applique le masque 4 à l'image binaire redimensionnée
    ITextRegion = M5(ITextRegion);%puis on applique le masque 5
    if intermediateDisplay %plot intermédiaire
        subplot(2,5,6), imshow(ITextRegion), title("BW redim filtered with M45");
    end
    
    while ~isequal(ITextRegion,ITextRegionControl) %tant que l'image est modifiée par les masques
        ITextRegionControl = ITextRegion; %on modifie le critère d'arrêt en y stockant la dernière image obtenue
        ITextRegion = M1(ITextRegion); %on applique M1
        ITextRegion = M2(ITextRegion); %on applique M2
        %ITextRegion = M3(ITextRegion); 
    end
    if intermediateDisplay %plot intermédiaire
        subplot(2,5,7), imshow(ITextRegion), title("BW with potential text regions");
    end
    
    %% 3.4 Selection of effective text regions
    % Background pixels separation : back to G (gray levels image)
        % function Gsortie = bckgrndPixelSeparation(G)

    % Effective text region filtering
    % - Calcul distance entre maxs : si sup à un seuil (15po) alors calssifié comme region de texte

        % Get regions limits for low resolution
    regionsLimitsRaw = regionprops(ITextRegion); %on récupère les propriétés des différentes régions de l'image (les rectangles)
    regionsLimitsLowRes = zeros(length(regionsLimitsRaw),4);%liste de stockage des rectangles
    for i=1:length(regionsLimitsRaw) %pour chaque rectangle
        regionsLimitsLowRes(i,:) = floor(regionsLimitsRaw(i).BoundingBox); %on stocke : [abscisse du point en haut à gauche, ordonnée, longueur, hauteur]
    end

        % Get regions limits for initial resolution
    regionsLimitsHighRes = floor(regionsLimitsLowRes/resizeFactor); %on convertit les positions des rectangles précédentes pour adapter au format initial de l'image
    
    rBis = []; % Ajust limits to enter image size
    for i=1:height(regionsLimitsHighRes) %pour tous les rectangles
        toplefty = max(regionsLimitsHighRes(i,1),1); %on s'assure que le point en haut à gauche ne sort pas de l'image
        topleftx = max(regionsLimitsHighRes(i,2),1);
        widthRect = min(regionsLimitsHighRes(i,3),width(I)-toplefty); %on s'assure que la droite du rectangle ne sort pas de l'image
        heightRect = min(regionsLimitsHighRes(i,4),height(I)-topleftx); %on s'assure que le bas du rectangle ne sort pas de l'image
        rBis= [rBis ; [toplefty topleftx widthRect heightRect]]; %on stocke les nouvelles limites obtenues
    end
    regionsLimitsHighRes = rBis;
    
    %amélioration : on fait une séparation des pixels de fond pour chaque
    %zone de texte obtenue 
    %fonction plus bas
    regionsLimitsHighRes = improvementLocalization(G,regionsLimitsHighRes,255);

    effectiveTextRegion = [];

    if intermediateDisplay %si plot intermédiaire, nouvelle figure
        figure();
    end
    for i=1:height(regionsLimitsHighRes)
        toplefty = regionsLimitsHighRes(i,1);
        topleftx = regionsLimitsHighRes(i,2);
        widthRect = regionsLimitsHighRes(i,3);  
        heightRect = regionsLimitsHighRes(i,4);
        % Histogram for each region
        H = imhist(G(topleftx:topleftx+heightRect,toplefty:toplefty+widthRect));
        if intermediateDisplay %plot intermédiaire de l'histogramme
            subplot(3,3,i), plot(H), xlim([0 255]);
        end

        % Get 2 highest local maxima
        H(257) = 0; % To get pick at 255
        [peaks, locs] = findpeaks(H,'SortStr','descend','NPeaks',2); %les deux premiers max de H
        if intermediateDisplay %plot intermédiaire
            findpeaks(H,'SortStr','descend','NPeaks',2);
        end
        distMaxima = 0;
        if length(locs)>1 %pour éviter les bugs dus aux zones de couleur unies
            distMaxima = abs(locs(1) - locs(2)); %calcul de la distance entre deux pics
        end

        % Filter effective text regions
        if distMaxima > thresholdTextRegionDistance*255 %si les deux pics sont assez éloignés (seuil)
            effectiveTextRegion = [ effectiveTextRegion ; regionsLimitsHighRes(i,:)]; %la région est considérée comme région de texte
        end
    end
    
        % Display of the text regions identified
    f=imshow(I,[0,255]);
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
               if min == 0 %si c'est le premier 1 de la ligne
                   min = j; %on stocke la colonne
               else %sinon
                   max = j; %on stocke la colonne jusqu'à arriver au dernier 1 de la ligne
               end
           end
        end
        if min ~= 0 && max ~= 0 %si il y a au moins un 1 sur la ligne
            J(i,min:max) = 1; %les px entre le premier et le dernier 1 deviennent 1
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
        subplot(2,5,8), plot(Hist), xlim([0 255]), title("Grayscale image histogram");
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
        subplot(2,5,9), imshow(G2), title("Method 2 pixel separation");
    end

    G3 = uint8((G<=u)*u + (G>u)*L);
    if intermediateDisplay
        subplot(2,5,10), imshow(G3), title("Method 3 pixel separation");
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
        
        newTextRegionsLimits = [newTextRegionsLimits ; [newY newX newL newH]];
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