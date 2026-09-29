"""CP1 — Structured logging.

`print("user abc hỏi gì đó")` là log cho người đọc. Cloud (Railway, Render,
Cloud Run, Datadog...) đọc log bằng máy: một dòng = một JSON object thì mới
lọc/đếm/cảnh báo được. Đây là khác biệt lớn giữa localhost và production.
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone


def utc_now_iso() -> str:
    """CHO SẴN — thời điểm hiện tại theo ISO-8601, múi giờ UTC."""
    return datetime.now(timezone.utc).isoformat()


def log_event(event: str, level: str = "info", **fields) -> str:
    """Ghi một dòng log JSON ra stdout.

    Tạo dict gồm tối thiểu 3 khóa:
        - "event"     : tên sự kiện
        - "level"     : mức log, VIẾT THƯỜNG
        - "timestamp" : utc_now_iso()
    rồi gộp thêm mọi cặp key/value trong ``**fields``.

    In chuỗi JSON đó ra stdout trên MỘT DÒNG DUY NHẤT (không dùng
    ``indent``), dùng ``ensure_ascii=False`` để nội dung tiếng Việt không
    bị biến dạng, và trả về chính chuỗi đó.
    """
    record = {
        "event": event,
        "level": level.lower(),
        "timestamp": utc_now_iso(),
        **fields,
    }
    line = json.dumps(record, ensure_ascii=False)
    sys.stdout.write(line + "\n")
    sys.stdout.flush()
    return line