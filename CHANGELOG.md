### Changelog

* 2026/04/12: Return a 1x1 transparent pixel instead of a 404/403 error when activity maps are not found or have expired - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
* 2026/04/11: Port per-channel settings from slack-strava — add `Channel` model, `set activities` command to filter activity types per channel, and per-channel maps/units/fields/userlimit - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
* 2026/04/11: Upgrade to Ruby 4.0.2 - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
* 2026/04/07: Fixed `Stripe::StripeObject#method_missing` error by replacing `customer.subscriptions` with `Stripe::Subscription.list` - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
* 2026/03/20: Added `set timezone auto` to detect a team timezone from activity data - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
* 2026/03/20: Upgrade to Ruby 4.0.1 - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
* 2026/03/19: Upgrade to Ruby 3.4.9 - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
* 2026/03/19: Delete activities that become private after being posted - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
* 2026/03/19: Refresh Strava athlete profile during activity syncs so renamed athletes show up on new posts immediately - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
* 2026/03/19: Automatically disconnect users from Strava when Discord reports they have left the server - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
* 2026/03/19: Added `set timezone` - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
* 2026/03/19: Added `set userlimit` and `set channellimit` to limit max activities posted per user/channel per day, plus the supporting MongoDB indexes - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
* 2026/03/19: Group virtual and non-virtual activities in leaderboards - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
* 2025/10/02: Upgrade to Ruby 3.4.6 - [@dblock](https://github.com/dblock).
* 2025/07/13: Fix: missing calories in activities - [@dblock](https://github.com/dblock).
* 2025/05/25: Assign medals based on rank within an activity type - [@JonEHolland](https://github.com/JonEHolland), [@dblock](https://github.com/dblock).
* 2025/03/30: Added `set retention` - [@dblock](https://github.com/dblock).
* 2025/03/30: Added leaderboard ranges - [@dblock](https://github.com/dblock).
* 2025/02/12: Users that installed the bot are now guild owners - [@dblock](https://github.com/dblock).
* 2025/01/17: Guild owners can disconnect users - [@dblock](https://github.com/dblock).
* 2024/11/30: Display primary activity photo - [@dblock](https://github.com/dblock).
* 2024/11/17: Added `/strada leaderboard` and display medals - [@dblock](https://github.com/dblock).
* 2024/10/09: Fixed [#27](https://github.com/dblock/discord-strava/issues/27), incorrect local time - [@dblock](https://github.com/dblock).
* 2024/07/28: Fixed syncing activities that are created out of order - [@dblock](https://github.com/dblock).
* 2024/07/21: Added `resubscribe` - [@dblock](https://github.com/dblock).
* 2024/07/14: Fixed error handling during updates for multiple identical users across teams - [@dblock](https://github.com/dblock).
* 2024/07/13: Fixed duplicate activities from concurrent updates - [@dblock](https://github.com/dblock).
* 2024/01/02: Add Title, Description, Url, User, Athlete and Date field options - [@dblock](https://github.com/dblock).
* 2023/08/08: Fixed empty maps - [@dblock](https://github.com/dblock).
* 2023/08/07: Display all information on past due subscriptions - [@dblock](https://github.com/dblock).
* 2023/08/07: Fixed undefined `backtrace` in Strava error handling - [@dblock](https://github.com/dblock).
* 2023/07/30: Initial public release - [@dblock](https://github.com/dblock).
