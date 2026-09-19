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
    if width == 0 || height == 0 {
        return;
    }

    // Everything that does not depend on the pixel is hoisted out of the loops.
    let w = width as f64;
    let h = height as f64;
    let aspect = w / h;
    let step_x = 4.0 * aspect / (w * zoom);
    let step_y = 4.0 / (h * zoom);
    let half_w = w / 2.0;
    let half_h = h / 2.0;
    let inv_ln2 = 1.0 / 2.0f64.ln();
    let hue_shift = time * 0.1;

    unsafe {
        let buffer = &mut *core::ptr::addr_of_mut!(IMAGE_BUFFER);
        for y in 0..height {
            let py = (y as f64 - half_h) * step_y + offset_y;
            let row = y * width * 4;
            for x in 0..width {
                let px = (x as f64 - half_w) * step_x + offset_x;
                let idx = row + x * 4;

                let (mut zx, mut zy, cx, cy) = if is_julia {
                    (px, py, cx_julia, cy_julia)
                } else {
                    (0.0, 0.0, px, py)
                };

                // Points inside the main cardioid or the period-2 bulb never escape: they are the
                // most expensive pixels of the set (max_iterations each) and need no iteration at all.
                let mut inside = false;
                if !is_julia {
                    let xq = cx - 0.25;
                    let q = xq * xq + cy * cy;
                    inside = q * (q + xq) <= 0.25 * cy * cy
                        || (cx + 1.0) * (cx + 1.0) + cy * cy <= 0.0625;
                }

                let mut iteration: u32 = 0;
                let mut zx2 = zx * zx;
                let mut zy2 = zy * zy;

                if !inside {
                    // Periodicity check (Brent): an orbit that returns exactly to a saved point is
                    // trapped in a cycle, so it is inside. An escaping orbit can never do that, which
                    // keeps the image identical while cutting the cost of interior pixels at deep zoom.
                    let (mut ox, mut oy) = (zx, zy);
                    let mut lap: u32 = 0;
                    let mut lap_len: u32 = 8;
                    while zx2 + zy2 <= 100.0 && iteration < max_iterations {
                        zy = 2.0 * zx * zy + cy;
                        zx = zx2 - zy2 + cx;
                        zx2 = zx * zx;
                        zy2 = zy * zy;
                        iteration += 1;
                        if zx == ox && zy == oy {
                            iteration = max_iterations;
                            break;
                        }
                        lap += 1;
                        if lap == lap_len {
                            ox = zx;
                            oy = zy;
                            lap = 0;
                            lap_len += lap_len;
                        }
                    }
                }

                if inside || iteration == max_iterations {
                    buffer[idx] = 0;
                    buffer[idx + 1] = 0;
                    buffer[idx + 2] = 0;
                    buffer[idx + 3] = 255;
                } else {
                    // Smooth coloring
                    let log_zn = (zx2 + zy2).ln() / 2.0;
                    let nu = (log_zn * inv_ln2).ln() * inv_ln2;
                    let smooth_iter = iteration as f64 + 1.0 - nu;

                    // Dynamic coloring using time
                    let hue = (smooth_iter * 0.05 + hue_shift) % 1.0;
                    let (r, g, b) = hsv_to_rgb(hue, 0.7, 0.9);

                    buffer[idx] = r;
                    buffer[idx + 1] = g;
                    buffer[idx + 2] = b;
                    buffer[idx + 3] = 255;
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
