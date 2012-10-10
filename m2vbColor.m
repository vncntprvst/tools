%% Convert Matlab color to a VBA color (Microsoft decimal RGB format: 0xRRGGBB)
function color = m2vbColor(color)
    try
        % Convert color names to RBG triple (0-1) if not already in that format
        if ischar(color)
            switch lower(color)
                case {'y','yellow'}, color = [1,1,0];
                case {'m','magenta'}, color = [1,0,1];
                case {'c','cyan'}, color = [0,1,1];
                case {'r','red'}, color = [1,0,0];
                case {'g','green'}, color = [0,1,0];
                case {'b','blue'}, color = [0,0,1];
                case {'w','white',''}, color = [1,1,1]; % empty '' also sets white color
                case {'k','black'}, color = [0,0,0];
                otherwise, error(['Invalid color specified: ' color]);
            end
        elseif ~isnumeric(color) | length(color)~=3 %#ok ML6
            error(['Invalid color specified: ' color]);
        end

        % Convert to Microsoft decimal RGB format
        color = sum(floor(color*255) .* (256.^[0,1,2])); %or sum(floor(color*255) .* (256.^[2,1,0])); ??
    catch
        error(['Invalid color specified: ' lasterr]);
    end

