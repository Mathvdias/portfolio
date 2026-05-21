const WIDTH: usize = 800;
const HEIGHT: usize = 600;
const BUFFER_SIZE: usize = WIDTH * HEIGHT * 4;

static mut IMAGE_BUFFER: [u8; BUFFER_SIZE] = [0; BUFFER_SIZE];

#[no_mangle]
pub extern "C" fn get_buffer_pointer() -> *const u8 {
    unsafe { IMAGE_BUFFER.as_ptr() }
}

#[no_mangle]
pub extern "C" fn get_buffer_size() -> usize {
    BUFFER_SIZE
}

#[no_mangle]
pub extern "C" fn generate_fractal(
    render_width: usize,
    render_height: usize,
    zoom: f64,
    offset_x: f64,
    offset_y: f64,
    max_iterations: u32,
    is_julia: bool,
    cx_julia: f64,
    cy_julia: f64,
    time: f64,
) {
    let width = if render_width > WIDTH { WIDTH } else { render_width };
    let height = if render_height > HEIGHT { HEIGHT } else { render_height };

    unsafe {
        for y in 0..height {
            for x in 0..width {
                // Map pixel to complex plane
                let aspect = width as f64 / height as f64;
                let mut zx = (x as f64 - width as f64 / 2.0) * 4.0 * aspect / (width as f64 * zoom) + offset_x;
                let mut zy = (y as f64 - height as f64 / 2.0) * 4.0 / (height as f64 * zoom) + offset_y;

                let cx: f64;
                let cy: f64;

                if is_julia {
                    cx = cx_julia;
                    cy = cy_julia;
                } else {
                    cx = zx;
                    cy = zy;
                    zx = 0.0;
                    zy = 0.0;
                }

                let mut iteration = 0.0;
                let mut zx2 = zx * zx;
                let mut zy2 = zy * zy;

                while zx2 + zy2 <= 100.0 && (iteration as u32) < max_iterations {
                    zy = 2.0 * zx * zy + cy;
                    zx = zx2 - zy2 + cx;
                    zx2 = zx * zx;
                    zy2 = zy * zy;
                    iteration += 1.0;
                }

                let idx = (y * width + x) * 4;
                if iteration as u32 == max_iterations {
                    IMAGE_BUFFER[idx] = 0;
                    IMAGE_BUFFER[idx + 1] = 0;
                    IMAGE_BUFFER[idx + 2] = 0;
                    IMAGE_BUFFER[idx + 3] = 255;
                } else {
                    // Smooth coloring
                    let log_zn = (zx2 + zy2).ln() / 2.0;
                    let nu = (log_zn / 2.0f64.ln()).ln() / 2.0f64.ln();
                    let smooth_iter = iteration + 1.0 - nu;
                    
                    // Dynamic coloring using time
                    let hue = (smooth_iter * 0.05 + time * 0.1) % 1.0;
                    let (r, g, b) = hsv_to_rgb(hue, 0.7, 0.9);

                    IMAGE_BUFFER[idx] = r;
                    IMAGE_BUFFER[idx + 1] = g;
                    IMAGE_BUFFER[idx + 2] = b;
                    IMAGE_BUFFER[idx + 3] = 255;
                }
            }
        }
    }
}

fn hsv_to_rgb(h: f64, s: f64, v: f64) -> (u8, u8, u8) {
    let h6 = h * 6.0;
    let i = h6.floor() as i32;
    let f = h6 - i as f64;
    let p = v * (1.0 - s);
    let q = v * (1.0 - f * s);
    let t = v * (1.0 - (1.0 - f) * s);

    let (r, g, b) = match i % 6 {
        0 => (v, t, p),
        1 => (q, v, p),
        2 => (p, v, t),
        3 => (p, q, v),
        4 => (t, p, v),
        _ => (v, p, q),
    };

    ((r * 255.0) as u8, (g * 255.0) as u8, (b * 255.0) as u8)
}
