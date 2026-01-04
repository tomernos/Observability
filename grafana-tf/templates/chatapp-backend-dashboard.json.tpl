{
  "title": "${dashboard_title}",
  "uid": "${dashboard_uid}",
  "tags": ${jsonencode(tags)},
  "refresh": "${refresh_interval}",
  "time": {
    "from": "${time_from}",
    "to": "${time_to}"
  },
  "panels": [
%{ for idx, panel in panels ~}
    {
      "id": ${panel.id},
      "title": "${panel.title}",
      "type": "${panel.type}",
      "gridPos": {
        "x": ${panel.grid_pos.x},
        "y": ${panel.grid_pos.y},
        "w": ${panel.grid_pos.w},
        "h": ${panel.grid_pos.h}
      },
      "targets": [
%{ for target_idx, target in panel.targets ~}
        {
          "expr": "${target.expr}",
          "legendFormat": "${target.legend_format}",
          "refId": "${target.ref_id}",
          "datasource": {
            "type": "prometheus",
            "uid": "${prometheus_uid}"
          }
        }${target_idx < length(panel.targets) - 1 ? "," : ""}
%{ endfor ~}
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "${panel.unit}"
%{ if panel.type == "timeseries" ~}
          ,
          "custom": {
            "drawStyle": "${panel.draw_style}",
            "lineWidth": ${panel.line_width},
            "fillOpacity": ${panel.fill_opacity}
%{ if can(panel.show_points) ~}
            ,
            "showPoints": "${panel.show_points}"
%{ endif ~}
          }
%{ endif ~}
%{ if length(panel.thresholds) > 0 ~}
          ,
          "thresholds": {
            "mode": "absolute",
            "steps": ${jsonencode(panel.thresholds)}
          }
%{ endif ~}
%{ if can(panel.min) ~}
          ,
          "min": ${panel.min},
          "max": ${panel.max}
%{ endif ~}
        }
      }
%{ if panel.type == "timeseries" || panel.type == "graph" ~}
      ,
      "options": {
        "legend": {
          "displayMode": "${panel.legend_display_mode}",
          "placement": "${panel.legend_placement}",
          "calcs": ${jsonencode(panel.legend_calcs)}
        }
      }
%{ endif ~}
%{ if panel.type == "stat" ~}
      ,
      "options": {
        "colorMode": "background",
        "graphMode": "none",
        "textMode": "value_and_name"
      }
%{ endif ~}
    }${idx < length(panels) - 1 ? "," : ""}
%{ endfor ~}
  ]
}