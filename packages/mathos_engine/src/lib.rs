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
pub extern "C" fn generate_mandelbrot(
    render_width: usize,
    render_height: usize,
    zoom: f64,
    offset_x: f64,
    offset_y: f64,
    max_iterations: u32,
) {
    let width = if render_width > WIDTH { WIDTH } else { render_width };
    let height = if render_height > HEIGHT { HEIGHT } else { render_height };

    unsafe {
        for y in 0..height {
            for x in 0..width {
                let cx = (x as f64 - width as f64 / 2.0) * 4.0 / (width as f64 * zoom) + offset_x;
                let cy = (y as f64 - height as f64 / 2.0) * 4.0 / (height as f64 * zoom) + offset_y;

                let mut zx = 0.0;
                let mut zy = 0.0;
                let mut iteration = 0;

                while zx * zx + zy * zy <= 4.0 && iteration < max_iterations {
                    let tmp = zx * zx - zy * zy + cx;
                    zy = 2.0 * zx * zy + cy;
                    zx = tmp;
                    iteration += 1;
                }

                let idx = (y * width + x) * 4;
                if iteration == max_iterations {
                    IMAGE_BUFFER[idx] = 0;
                    IMAGE_BUFFER[idx + 1] = 0;
                    IMAGE_BUFFER[idx + 2] = 0;
                    IMAGE_BUFFER[idx + 3] = 255;
                } else {
                    let t = iteration as f64 / max_iterations as f64;
                    IMAGE_BUFFER[idx] = (9.0 * (1.0 - t) * t * t * t * 255.0) as u8;
                    IMAGE_BUFFER[idx + 1] = (15.0 * (1.0 - t) * (1.0 - t) * t * t * 255.0) as u8;
                    IMAGE_BUFFER[idx + 2] = (8.5 * (1.0 - t) * (1.0 - t) * (1.0 - t) * t * 255.0) as u8;
                    IMAGE_BUFFER[idx + 3] = 255;
                }
            }
        }
    }
}
