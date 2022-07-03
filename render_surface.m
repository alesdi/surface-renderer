function render_surface(engine, xlim, ylim, iterations, varargin)
%RENDER_SURFACE Dynamically render a surface given any builder function
%engine(x, y), iteratively increasing resolution within a given range and
%updating the plot at every new computed point. Stop and resume rendering
%at any time with auto-save and get real-time progress percentage and
%estimated time to completion in the console.
% 
%RENDER_SURFACE(@engine, xlim, ylim, iterations) renders a surface given a
%generic z = engine(x, y) builder function, two xlim = [x0, x1] and ylim = [y0, y1] limit arrays for the x and y axes
%and the number of iterations to perform (resolution increases proportionally with iterations).
%
%Customize behavior and access advanced features with the following
%parameters:
%
%- cache_file ('' by default): a file name to use for caching progress and leverage
%autosave. Leave empty to disable autosave. For example:
%RENDER_SURFACE(@engine, xlim, ylim, iterations, 'cache_file',
%'autosave.mat') stores autosave data in an autosave.mat file in the
%current folder.
% 
%- verbose (false by default): prints verbose log to console, including real-time rendering
%progress and estimated time to completion.
%
%- invalidate_cache (false by default): ignore any existing autosave file and starts a new
%rendering (cached, if the cache_file parameter is provided)
%
%- clear_cache_on_end (true by default): clear any autosave cache when the
%rendering is completed

    % Parse parameters
    p = inputParser;
    addOptional(p, 'cache_file', '', @(x) isstring(x)||ischar(x));
    addOptional(p, 'verbose', false, @(x) islogical(x));
    addOptional(p, 'invalidate_cache', false, @(x) islogical(x));
    addOptional(p, 'clear_cache_on_end', true, @(x) islogical(x));
    parse(p, varargin{:});
    
    verbose = p.Results.verbose;
    cache_file = p.Results.cache_file;
    auto_save = ~strcmp(cache_file, '');
    invalidate_cache = p.Results.invalidate_cache;
    clear_cache_on_end = p.Results.clear_cache_on_end;
    end_index = 2^iterations;

    % Prepare surface
    surface = nan(2^iterations, 2^iterations);
    x_vec = interp1([1, end_index], xlim, 1:end_index);
    y_vec = interp1([1, end_index], ylim, 1:end_index);
    
    h = surf(x_vec, y_vec, surface);
    
    % Attempt to recover from cache
    ii_start = 1;
    x_index_start = 1;
    y_index_start = 1;
    done_start = 0;
    
    if invalidate_cache && exist(cache_file, 'file')
        delete(cache_file)
        verbose_print(sprintf('Cache invaidated (%s deleted).\n\n', cache_file));
    end
    
    if auto_save && exist(cache_file, 'file')
        verbose_print(sprintf('Cache file found. Resuming rendering.\n\n'));
        loaded = load(cache_file);
        
        if (isfield(loaded, 'surface')...
            && isfield(loaded, 'ii')...
            && isfield(loaded, 'x_index')...
            && isfield(loaded, 'y_index')...
            && isfield(loaded, 'done')...
            && isfield(loaded, 'rendered_surface')...
            && isfield(loaded, 'xlim')...
            && isfield(loaded, 'ylim')...
            && isfield(loaded, 'iterations'))
        
            if all(loaded.xlim == xlim)...
                && all(loaded.ylim == ylim)...
                && loaded.iterations <= iterations
            
                surface = loaded.surface;
                ii_start = loaded.ii;
                x_index_start = loaded.x_index;
                y_index_start = loaded.y_index;
                done_start = loaded.done;
                h.ZData = loaded.rendered_surface;
            else
                warning('Cache file is invalid. Rendering parameters might have changed. Ignoring.');
            end
        else
            warning('Cache file is invalid. Ignoring.');
        end
    else
        verbose_print(sprintf('Starting new rendering.\n\n'));
    end
    
    % Start rendering iterations
    last_console_length = 0;
    tic;
    done = done_start;
    for ii = ii_start:iterations
        % Cycle trough iterations
        index_division = 2^(iterations-ii);
        
        if ii == ii_start
            x_indices = x_index_start:index_division:end_index;
        else
            x_indices = 1:index_division:end_index;
        end
        
        for x_index = x_indices
            % Cycle over x for the current iteration
            if ii == ii_start && x_index == x_index_start
                y_indices = y_index_start:index_division:end_index;
            else
                y_indices = 1:index_division:end_index;
            end
            
            for y_index = y_indices
                % Cycle over y for the current iteration
                if ~isnan(surface(x_index, y_index))
                    continue;
                end
                
                % Compute z
                x = x_vec(x_index);
                y = y_vec(y_index);
                
                z = engine(x, y);

                surface(x_index, y_index) = z;
                
                % Update rendering
                x_render_int = x_index:min(end_index, x_index+index_division-1);
                y_render_int = y_index:min(end_index, y_index+index_division-1);
                
                h.ZData(x_render_int, y_render_int) = z;
                rendered_surface = h.ZData;
                drawnow;
                
                % Show progress
                elapsed = toc();
                done = done+1;
                total = 4^iterations;
                
                verbose_print(repmat('\b', 1, last_console_length));
                last_console_length = 0;
                
                last_console_length = last_console_length+...
                    verbose_print(...
                        sprintf(...
                            'Completion: %d/%d (%.1f%%)\n',...
                            done,...
                            total,...
                            done/total*100 ...
                        )...
                    );

                last_console_length = last_console_length+...
                    verbose_print(...
                        sprintf(...
                            'Estimated time left: %s (%s elapsed)\n',...
                            duration(...
                                seconds((total-done)/(done-done_start)*elapsed),...
                                'Format', 'hh:mm:ss'...
                            ),...
                            duration(seconds(elapsed), 'Format', 'hh:mm:ss')...
                        )...
                    );
            
                if auto_save
                    save(...
                        cache_file,...
                        'surface',...
                        'ii',...
                        'x_index',...
                        'y_index',...
                        'done',...
                        'rendered_surface',...
                        'xlim',...
                        'ylim',...
                        'iterations'...
                    );
                end
            end
        end
    end
    
    if clear_cache_on_end
        verbose_print('Cache cleared.\n');
        delete(cache_file);
    end
    
    function [length]=verbose_print(text)
        length = 0;
        if verbose
            length = fprintf(strrep(text, '%', '%%' ));
        end
    end
end

