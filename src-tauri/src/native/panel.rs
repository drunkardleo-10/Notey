#[cfg(target_os = "macos")]
pub mod macos {
    use objc2::msg_send;
    use objc2_app_kit::{NSColor, NSWindow, NSWindowCollectionBehavior};
    use std::ffi::c_void;

    pub unsafe fn configure_edge_deck_panel(ns_window_ptr: *mut c_void) {
        if ns_window_ptr.is_null() {
            return;
        }

        let window = &*(ns_window_ptr as *const NSWindow);

        let behavior = NSWindowCollectionBehavior::CanJoinAllSpaces
            | NSWindowCollectionBehavior::FullScreenAuxiliary
            | NSWindowCollectionBehavior::Stationary
            | NSWindowCollectionBehavior::IgnoresCycle;

        window.setCollectionBehavior(behavior);

        let status_bar_level: isize = 25;
        let _: () = msg_send![window, setLevel: status_bar_level];

        window.setOpaque(false);
        window.setBackgroundColor(Some(&NSColor::clearColor()));
        window.setHasShadow(false);

        let _: () = msg_send![window, setMovable: false];
        let _: () = msg_send![window, setAcceptsMouseMovedEvents: true];
        let _: () = msg_send![window, setIgnoresMouseEvents: false];
        let _: () = msg_send![window, setHidesOnDeactivate: false];
        let _: () = msg_send![window, orderFrontRegardless];
    }

    pub unsafe fn configure_editor_panel(ns_window_ptr: *mut c_void) {
        if ns_window_ptr.is_null() {
            return;
        }

        let window = &*(ns_window_ptr as *const NSWindow);

        let behavior = NSWindowCollectionBehavior::CanJoinAllSpaces
            | NSWindowCollectionBehavior::FullScreenAuxiliary
            | NSWindowCollectionBehavior::IgnoresCycle;

        window.setCollectionBehavior(behavior);

        let floating_level: isize = 25;
        let _: () = msg_send![window, setLevel: floating_level];

        window.setOpaque(false);
        window.setBackgroundColor(Some(&NSColor::clearColor()));
        window.setHasShadow(true);
        let _: () = msg_send![window, setMovable: true];
        let _: () = msg_send![window, setHidesOnDeactivate: false];
        let _: () = msg_send![window, orderFrontRegardless];
    }

    pub unsafe fn set_window_pinned_level(ns_window_ptr: *mut c_void, pinned: bool) {
        if ns_window_ptr.is_null() {
            return;
        }

        let window = &*(ns_window_ptr as *const NSWindow);
        let level: isize = if pinned { 25 } else { 25 };
        let _: () = msg_send![window, setLevel: level];
        let _: () = msg_send![window, orderFrontRegardless];
    }
}

#[cfg(not(target_os = "macos"))]
pub mod macos {
    use std::ffi::c_void;

    pub unsafe fn configure_edge_deck_panel(_ns_window_ptr: *mut c_void) {}
    pub unsafe fn configure_editor_panel(_ns_window_ptr: *mut c_void) {}
    pub unsafe fn set_window_pinned_level(_ns_window_ptr: *mut c_void, _pinned: bool) {}
}
