mimirtool rules load --address=https://mimir.ninjacart.in --id="_trader_dev" --key="$mimir_password" --user observe $(pwd)/*.yaml $(pwd)/../common/*.yaml

*Link:* {{ grafanaExploreURL "https://nc-grafana.ninjacart.in" "mimir_ds_local" "now-1h" "now" "Sorry query is not configured. Waiting for this PR get merge: https://github.com/grafana/mimir/pull/4301"  }}