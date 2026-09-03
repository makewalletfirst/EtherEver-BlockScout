#!/bin/bash

# 무한 루프 시작
while true; do
    echo "--- Sync Started: $(date) ---"

    # 1. 메인 DB에서 오늘 발생한 트랜잭션 총합 가져오기
    TX_COUNT=$(docker exec -i db psql -U blockscout -d blockscout -t -c "SELECT count(*) FROM transactions WHERE inserted_at >= CURRENT_DATE;" | xargs)

    # 2. 숫자가 정상적으로 조회되었는지 확인 후 Stats DB 업데이트
    if [[ "$TX_COUNT" =~ ^[0-9]+$ ]]; then
        docker exec -i stats-db psql -U stats -d stats -c "INSERT INTO chart_data (chart_id, date, value) VALUES (123, CURRENT_DATE, '$TX_COUNT') ON CONFLICT (chart_id, date) DO UPDATE SET value = '$TX_COUNT';"
        echo "Successfully updated Stats DB. Current TX Count: $TX_COUNT"
    else
        echo "Error: Failed to fetch valid transaction count. Skipping this turn."
    fi

    echo "Waiting for 30 minutes before next sync..."
    echo "--- Sync Finished: $(date) ---"

    # 3분대기
    sleep 180
done
