#!bin/bash
# test slack integration from the terminal
curl -X POST --data-urlencode "payload={\"channel\": \"${SLACK_CHANNEL}\", \"username\": \"webhookbot\", \"text\": \"This is posted to ${SLACK_CHANNEL} and comes from a bot named webhookbot.\", \"icon_emoji\": \":ghost:\"}" ${SLACK_WEBHOOK_URL}
