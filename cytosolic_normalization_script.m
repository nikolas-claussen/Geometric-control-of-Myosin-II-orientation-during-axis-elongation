%% Cytosolic normalization script
% 08/20/2021. Normalize by using a tophat filter.


%% define a dict of background values (outside of embryo in 3d volume), the IDs to process, and the directory

root_path = "/data/";
save_path = strcat(root_path, 'cytosolic/');
embryos = [202207051440, 202207052000, 202207061620];
min_vals = containers.Map({202207051440, 202207052000, 202207061620}, {250, 250, 160}); % arbitrary atm


cell_size = 8;
fill_holes = false; % use this to fill nuclei/fold induced holes in background before dividing by it
smooth_background = false; % smooth background slightly (probably no matter)

%% load images

for embryo = embryos
    disp(num2str(embryo))
	% get file name
    Name = strcat(root_path, num2str(embryo), '/', dir(strcat(root_path, num2str(embryo), '/*.tif')).name);
    % to overwrite, delete previous results
    ResultName = strcat(root_path, num2str(embryo), '/', num2str(embryo), '_cytosolic', '.tif');
    if exist(ResultName) == 2
        delete(ResultName);
    end
    
    StackSize = length(imfinfo(Name));
    Size = size(imread(Name, 1));
    for k = 1 :  StackSize 
        image = double(imread(Name,k));
        image = double(image-min_vals(embryo));
        image = max(image, 0);
        % background is a (smoothed) top-hat transform of the original
        background = imdilate(imerode(image,strel('disk',cell_size)), strel('disk',cell_size));
        if smooth_background
            background = imgaussfilt(background, cell_size/2); 
        end
        if fill_holes
            background_filled = imfill(background);
            normalized = (image-background)./background_filled;
        else
            normalized = (image-background)./background;
        end
        % save
        normalized = uint16(1000 * normalized);
        imwrite(normalized, ResultName, 'tiff', 'Compression', 'none', 'WriteMode', 'append');
    end
end 











