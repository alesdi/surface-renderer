# SurfaceRenderer

A MATLAB Toolbox for advanced surface rendering.


https://user-images.githubusercontent.com/54476193/177038970-36e9f923-72a3-45d1-996b-db82e801e9b8.mp4


Use the `render_surface` function to dynamically render a surface given any
builder function `engine(x, y)`, iteratively increasing resolution within a
given range and updating the plot at every new computed point. Stop and resume
rendering at any time with auto-save and get real-time progress percentage and
estimated time to completion in the console.

The `render_surface` function is fully compatible with the GNU Octave.

## Example

```octave
figure;
wave_engine = @(x, y) sin(x)+cos(y);
render_surface(wave_engine, [0, 10], [0, 20], 5, 'render-surface-cache.mat', 'verbose', true); 
```
