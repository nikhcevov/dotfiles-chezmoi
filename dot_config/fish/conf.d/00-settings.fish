# Settings that used to live in fish_variables (universal variables).
# Universal variables are per-machine state and are NOT synced anymore,
# so anything that must be identical across machines lives here.
# The 00- prefix guarantees this loads before other conf.d files.

# nvm.fish: default node version (must be set before conf.d/nvm.fish runs)
set -g nvm_default_version v24

# done.fish: notify only about commands longer than 10s
set -g __done_min_cmd_duration 10000
set -g __done_notification_urgency_level low
