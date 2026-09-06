#[cfg(target_os = "macos")]
pub mod macos_screen {
    use objc2::msg_send;
    use objc2_foundation::{NSPoint, NSRect};

    #[derive(Clone, Copy, Debug)]
    pub struct ScreenGeometry {
        pub x: f64,
        pub y: f64,
        pub width: f64,
        pub height: f64,
    }

    pub unsafe fn get_cursor_screen_geometry() -> Option<ScreenGeometry> {
        let mouse_loc: NSPoint = msg_send![objc2::class!(NSEvent), mouseLocation];
        let screens: *mut objc2::runtime::AnyObject = msg_send![objc2::class!(NSScreen), screens];
        if screens.is_null() {
            return None;
        }

        let count: usize = msg_send![screens, count];
        for i in 0..count {
            let screen: *mut objc2::runtime::AnyObject = msg_send![screens, objectAtIndex: i];
            let frame: NSRect = msg_send![screen, frame];

            let inside_x = mouse_loc.x >= frame.origin.x && mouse_loc.x <= (frame.origin.x + frame.size.width);
            let inside_y = mouse_loc.y >= frame.origin.y && mouse_loc.y <= (frame.origin.y + frame.size.height);

            if inside_x && inside_y {
                return Some(ScreenGeometry {
                    x: frame.origin.x,
                    y: frame.origin.y,
                    width: frame.size.width,
                    height: frame.size.height,
                });
            }
        }

        if count > 0 {
            let screen: *mut objc2::runtime::AnyObject = msg_send![screens, objectAtIndex: 0usize];
            let frame: NSRect = msg_send![screen, frame];
            return Some(ScreenGeometry {
                x: frame.origin.x,
                y: frame.origin.y,
                width: frame.size.width,
                height: frame.size.height,
            });
        }

        None
    }
}

#[cfg(not(target_os = "macos"))]
pub mod macos_screen {
    #[derive(Clone, Copy, Debug)]
    pub struct ScreenGeometry {
        pub x: f64,
        pub y: f64,
        pub width: f64,
        pub height: f64,
    }

    pub unsafe fn get_cursor_screen_geometry() -> Option<ScreenGeometry> {
        None
    }
}
