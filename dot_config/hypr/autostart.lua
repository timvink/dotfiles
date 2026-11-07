-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Relaunch the Omarchy shell when it wedges after resume (NVIDIA EGL bug,
-- omacom/omarchy#10108). See ~/.local/bin/omarchy-shell-watchdog.
o.launch_on_start("omarchy-shell-watchdog")
