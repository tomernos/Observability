{
  "title": "${dashboard_title}",
  "uid": "${dashboard_uid}",
  "tags": ${jsonencode(tags)},
  "refresh": "${refresh}",
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "panels": [
%{ for panel_idx, panel in panels ~}
    {
      "id": ${panel_idx + 1},
      "title": "${panel.title}",
      "type": "${panel.type}",
      "gridPos": ${panel.type == "stat" ? jsonencode({x = (panel_idx % 4) * 6, y = floor(panel_idx / 4) * 6, w = 6, h = 6}) : jsonencode({x = panel_idx % 2 == 0 ? 0 : 12, y = floor(panel_idx / 2) * 8, w = 12, h = 8})},
      "targets": [
%{ for query_idx, query in panel.queries ~}
        {
          "expr": ${jsonencode(query.expr)},
          "legendFormat": "${query.legend}",
          "refId": "${substr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", query_idx, 1)}",
          "datasource": {
            "type": "prometheus",
            "uid": "${prometheus_uid}"
          }
        }${query_idx < length(panel.queries) - 1 ? "," : ""}
%{ endfor ~}
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "${try(panel.unit == "percent" ? "percent" : panel.unit == "seconds" ? "s" : panel.unit, "short")}"${try(panel.unit == "percent", false) ? ",\"min\":0,\"max\":100" : ""}${panel.type == "timeseries" || panel.type == "graph" ? ",\"custom\":{\"drawStyle\":\"line\",\"lineWidth\":2,\"fillOpacity\":10,\"showPoints\":\"never\",\"lineInterpolation\":\"linear\"}" : ""}${try(length(panel.alert_thresholds) > 0, false) ? ",\"thresholds\":{\"mode\":\"absolute\",\"steps\":[{\"color\":\"green\",\"value\":null}${join("", [for t in panel.alert_thresholds : ",{\"color\":\"${t.level == "warning" ? "yellow" : "red"}\",\"value\":${t.value}}"])}]}" : ""}
        }
      }${panel.type == "timeseries" || panel.type == "graph" ? ",\"options\":{\"legend\":{\"displayMode\":\"table\",\"placement\":\"bottom\",\"calcs\":[\"mean\",\"lastNotNull\",\"max\"]},\"tooltip\":{\"mode\":\"multi\",\"sort\":\"none\"}}" : ""}${panel.type == "gauge" ? ",\"options\":{\"orientation\":\"auto\",\"reduceOptions\":{\"values\":false,\"calcs\":[\"lastNotNull\"],\"fields\":\"\"},\"showThresholdLabels\":false,\"showThresholdMarkers\":true}" : ""}${panel.type == "stat" ? ",\"options\":{\"colorMode\":\"background\",\"graphMode\":\"none\",\"textMode\":\"value_and_name\",\"orientation\":\"auto\",\"reduceOptions\":{\"values\":false,\"calcs\":[\"lastNotNull\"],\"fields\":\"\"}}" : ""}
    }${panel_idx < length(panels) - 1 ? "," : ""}
%{ endfor ~}
  ]
}