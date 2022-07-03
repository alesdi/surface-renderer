figure;
wave_engine = @(x, y) sin(x)+cos(y);
render_surface(wave_engine, [0, 10], [0, 20], 5, 'render-surface-cache.mat', 'verbose', true); 