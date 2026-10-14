/* @ds-bundle: {"format":4,"namespace":"ConvoyDesignSystem_cacf45","components":[{"name":"Button","sourcePath":"components/actions/Button.jsx"},{"name":"IconButton","sourcePath":"components/actions/IconButton.jsx"},{"name":"Icon","sourcePath":"components/core/Icon.jsx"},{"name":"Card","sourcePath":"components/data/Card.jsx"},{"name":"DataTable","sourcePath":"components/data/DataTable.jsx"},{"name":"KeyValueList","sourcePath":"components/data/KeyValueList.jsx"},{"name":"LogList","sourcePath":"components/data/LogList.jsx"},{"name":"Sparkline","sourcePath":"components/data/Sparkline.jsx"},{"name":"SpeedLegend","sourcePath":"components/data/SpeedLegend.jsx"},{"name":"StatCard","sourcePath":"components/data/StatCard.jsx"},{"name":"Timeline","sourcePath":"components/data/Timeline.jsx"},{"name":"Avatar","sourcePath":"components/feedback/Avatar.jsx"},{"name":"Chip","sourcePath":"components/feedback/Chip.jsx"},{"name":"CountChip","sourcePath":"components/feedback/CountChip.jsx"},{"name":"FilterChip","sourcePath":"components/feedback/FilterChip.jsx"},{"name":"MetaPill","sourcePath":"components/feedback/MetaPill.jsx"},{"name":"StatusBadge","sourcePath":"components/feedback/StatusBadge.jsx"},{"name":"StatusSegments","sourcePath":"components/feedback/StatusSegments.jsx"},{"name":"Tooltip","sourcePath":"components/feedback/Tooltip.jsx"},{"name":"MapOverlayCard","sourcePath":"components/fleet/MapOverlayCard.jsx"},{"name":"SchedulerBlock","sourcePath":"components/fleet/SchedulerBlock.jsx"},{"name":"TripListCard","sourcePath":"components/fleet/TripListCard.jsx"},{"name":"VehicleRow","sourcePath":"components/fleet/VehicleRow.jsx"},{"name":"Checkbox","sourcePath":"components/forms/Checkbox.jsx"},{"name":"ColorField","sourcePath":"components/forms/ColorField.jsx"},{"name":"DateField","sourcePath":"components/forms/DateField.jsx"},{"name":"FieldLabel","sourcePath":"components/forms/FieldLabel.jsx"},{"name":"FileDrop","sourcePath":"components/forms/FileDrop.jsx"},{"name":"Input","sourcePath":"components/forms/Input.jsx"},{"name":"PhoneField","sourcePath":"components/forms/PhoneField.jsx"},{"name":"Radio","sourcePath":"components/forms/Radio.jsx"},{"name":"SearchInput","sourcePath":"components/forms/SearchInput.jsx"},{"name":"SegmentedControl","sourcePath":"components/forms/SegmentedControl.jsx"},{"name":"Select","sourcePath":"components/forms/Select.jsx"},{"name":"Switch","sourcePath":"components/forms/Switch.jsx"},{"name":"TagInput","sourcePath":"components/forms/TagInput.jsx"},{"name":"Textarea","sourcePath":"components/forms/Textarea.jsx"},{"name":"TogglePill","sourcePath":"components/forms/TogglePill.jsx"},{"name":"YesNoToggle","sourcePath":"components/forms/YesNoToggle.jsx"},{"name":"Breadcrumb","sourcePath":"components/navigation/Breadcrumb.jsx"},{"name":"NavFlyout","sourcePath":"components/navigation/NavFlyout.jsx"},{"name":"NavRail","sourcePath":"components/navigation/NavRail.jsx"},{"name":"Stepper","sourcePath":"components/navigation/Stepper.jsx"},{"name":"Tabs","sourcePath":"components/navigation/Tabs.jsx"},{"name":"TopBar","sourcePath":"components/navigation/TopBar.jsx"},{"name":"ViewToggle","sourcePath":"components/navigation/ViewToggle.jsx"}],"sourceHashes":{"components/actions/Button.jsx":"5a19b4fe6690","components/actions/IconButton.jsx":"eb8c985edf92","components/core/Icon.jsx":"d00dad97ea63","components/data/Card.jsx":"3e0bfeae9e55","components/data/DataTable.jsx":"8bdfe7efcfa6","components/data/KeyValueList.jsx":"207a4c967643","components/data/LogList.jsx":"ce35ed87699a","components/data/Sparkline.jsx":"32e9659ee29f","components/data/SpeedLegend.jsx":"8f6123f18106","components/data/StatCard.jsx":"d39e9ff25b13","components/data/Timeline.jsx":"520f16c3667e","components/feedback/Avatar.jsx":"2b8cd11d82cb","components/feedback/Chip.jsx":"11032b597391","components/feedback/CountChip.jsx":"af223005e89c","components/feedback/FilterChip.jsx":"45762ce15d71","components/feedback/MetaPill.jsx":"4638a2f6ba7c","components/feedback/StatusBadge.jsx":"2aa4eb8858c1","components/feedback/StatusSegments.jsx":"545776a76df1","components/feedback/Tooltip.jsx":"dcd2c238877b","components/fleet/MapOverlayCard.jsx":"c0e74baae137","components/fleet/SchedulerBlock.jsx":"217f98eb5a31","components/fleet/TripListCard.jsx":"4eb672b62884","components/fleet/VehicleRow.jsx":"3c862f11c77a","components/forms/Checkbox.jsx":"8ec161ad4db9","components/forms/ColorField.jsx":"837255d868a8","components/forms/DateField.jsx":"e956f4fa9318","components/forms/FieldLabel.jsx":"2abac5da1f13","components/forms/FileDrop.jsx":"3c202876983f","components/forms/Input.jsx":"e5963299b80e","components/forms/PhoneField.jsx":"cb6a4c52a2ca","components/forms/Radio.jsx":"3ff375c53074","components/forms/SearchInput.jsx":"923805859780","components/forms/SegmentedControl.jsx":"773a4f00306d","components/forms/Select.jsx":"87cfd079d40d","components/forms/Switch.jsx":"a7d605f6eb54","components/forms/TagInput.jsx":"b93e5eb3941c","components/forms/Textarea.jsx":"5a29498b4ea6","components/forms/TogglePill.jsx":"9b1710fe7d14","components/forms/YesNoToggle.jsx":"de628b189094","components/navigation/Breadcrumb.jsx":"7aab92f6ca88","components/navigation/NavFlyout.jsx":"0a4cdc3d49dd","components/navigation/NavRail.jsx":"30252e8febb9","components/navigation/Stepper.jsx":"d7c3544e67b6","components/navigation/Tabs.jsx":"9e4fc487be42","components/navigation/TopBar.jsx":"69e14b694492","components/navigation/ViewToggle.jsx":"1553e655fcb2","ui_kits/fleet_console/AppShell.jsx":"26c0eaf057d6","ui_kits/fleet_console/CreateTrip.jsx":"2d339cef29a2","ui_kits/fleet_console/LiveView.jsx":"bf1f0291f045","ui_kits/fleet_console/Reports.jsx":"84383ad5d32f","ui_kits/fleet_console/Scheduler.jsx":"1d8caa8cf17e","ui_kits/fleet_console/TripHistory.jsx":"238aaf3c3347","ui_kits/fleet_console/data.js":"be0b823b1794"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.ConvoyDesignSystem_cacf45 = window.ConvoyDesignSystem_cacf45 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Icon.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Material Symbols Rounded glyph. Requires styles.css (which loads the font). */
function Icon({
  name,
  size = 20,
  fill = true,
  weight = 400,
  color,
  style,
  className = '',
  ...rest
}) {
  return /*#__PURE__*/React.createElement("span", _extends({
    className: 'cv-icon ' + className,
    "aria-hidden": "true",
    style: {
      fontFamily: 'var(--font-icon)',
      fontSize: size,
      lineHeight: 1,
      color: color || 'inherit',
      display: 'inline-flex',
      flex: '0 0 auto',
      userSelect: 'none',
      fontVariationSettings: '"FILL" ' + (fill ? 1 : 0) + ', "wght" ' + weight + ', "GRAD" 0, "opsz" 24',
      ...style
    }
  }, rest), name);
}
Object.assign(__ds_scope, { Icon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Icon.jsx", error: String((e && e.message) || e) }); }

// components/actions/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const cvBtnBase = {
  display: 'inline-flex',
  alignItems: 'center',
  justifyContent: 'center',
  gap: 8,
  fontFamily: 'var(--font-sans)',
  fontWeight: 700,
  borderRadius: 'var(--radius-lg)',
  cursor: 'pointer',
  whiteSpace: 'nowrap',
  transition: 'var(--transition-control)',
  textDecoration: 'none',
  boxSizing: 'border-box'
};
const cvBtnSizes = {
  sm: {
    height: 36,
    padding: '0 14px',
    fontSize: 'var(--fs-body-sm)'
  },
  md: {
    height: 44,
    padding: '0 22px',
    fontSize: 'var(--fs-body)'
  }
};
const cvBtnVariants = {
  primary: {
    background: 'var(--teal-800)',
    color: 'var(--white)',
    border: 'none'
  },
  secondary: {
    background: 'var(--white)',
    color: 'var(--teal-800)',
    border: '2px solid var(--teal-800)'
  },
  tertiary: {
    background: 'var(--white)',
    color: 'var(--ink-800)',
    border: '1px solid var(--ink-100)'
  },
  danger: {
    background: 'var(--red-500)',
    color: 'var(--white)',
    border: 'none'
  },
  ghost: {
    background: 'transparent',
    color: 'var(--teal-800)',
    border: 'none'
  }
};
const cvBtnHover = {
  primary: {
    background: 'var(--teal-700)'
  },
  secondary: {
    background: 'var(--teal-100)'
  },
  tertiary: {
    background: 'var(--ink-025)'
  },
  danger: {
    background: 'var(--red-400)'
  },
  ghost: {
    background: 'var(--ink-025)'
  }
};

/** Convoy button. Primary = filled teal, secondary = 2px teal outline, tertiary = hairline. */
function Button({
  children,
  variant = 'primary',
  size = 'md',
  icon,
  iconPosition = 'right',
  disabled = false,
  fullWidth = false,
  as = 'button',
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const [active, setActive] = React.useState(false);
  const Tag = as;
  const glyph = icon ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: size === 'sm' ? 16 : 18
  }) : null;
  return /*#__PURE__*/React.createElement(Tag, _extends({
    disabled: Tag === 'button' ? disabled : undefined,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => {
      setHover(false);
      setActive(false);
    },
    onMouseDown: () => setActive(true),
    onMouseUp: () => setActive(false),
    style: {
      ...cvBtnBase,
      ...cvBtnSizes[size],
      ...cvBtnVariants[variant],
      ...(hover && !disabled ? cvBtnHover[variant] : null),
      ...(active && !disabled && variant === 'primary' ? {
        background: 'var(--teal-900)'
      } : null),
      ...(fullWidth ? {
        width: '100%'
      } : null),
      ...(disabled ? {
        background: 'var(--ink-025)',
        color: 'var(--ink-250)',
        border: 'none',
        cursor: 'not-allowed'
      } : null),
      ...style
    }
  }, rest), icon && iconPosition === 'left' ? glyph : null, children, icon && iconPosition === 'right' ? glyph : null);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/actions/Button.jsx", error: String((e && e.message) || e) }); }

// components/actions/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Square icon-only control: row actions, map controls, toolbar toggles. */
function IconButton({
  icon,
  size = 36,
  iconSize,
  variant = 'plain',
  color,
  label,
  active = false,
  disabled = false,
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const variants = {
    plain: {
      background: 'transparent',
      border: 'none'
    },
    outline: {
      background: 'var(--white)',
      border: '1px solid var(--ink-100)'
    },
    filled: {
      background: 'var(--teal-800)',
      border: 'none',
      color: 'var(--white)'
    }
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    "aria-label": label,
    disabled: disabled,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => setHover(false),
    style: {
      width: size,
      height: size,
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: 'var(--radius-lg)',
      cursor: disabled ? 'not-allowed' : 'pointer',
      padding: 0,
      color: color || (active ? 'var(--teal-800)' : 'var(--ink-800)'),
      transition: 'var(--transition-control)',
      ...variants[variant],
      ...(active && variant === 'outline' ? {
        border: '2px solid var(--teal-800)',
        background: 'var(--teal-100)'
      } : null),
      ...(hover && !disabled && variant !== 'filled' ? {
        background: 'var(--ink-025)'
      } : null),
      ...(hover && !disabled && variant === 'filled' ? {
        background: 'var(--teal-700)'
      } : null),
      ...(disabled ? {
        color: 'var(--ink-250)'
      } : null),
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: iconSize || Math.round(size * 0.56)
  }));
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/actions/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/data/Card.jsx
try { (() => {
/** White surface, 8px radius, hairline-divided title row. The container for everything. */
function Card({
  title,
  actions,
  children,
  padding = 20,
  bodyStyle,
  style
}) {
  return /*#__PURE__*/React.createElement("section", {
    style: {
      background: 'var(--surface-card)',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      border: '1px solid var(--ink-075)',
      overflow: 'hidden',
      ...style
    }
  }, title || actions ? /*#__PURE__*/React.createElement("header", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: 16,
      padding: '16px 20px',
      borderBottom: '1px solid var(--divider)'
    }
  }, /*#__PURE__*/React.createElement("h3", {
    style: {
      margin: 0,
      fontSize: 'var(--fs-body-lg)',
      fontWeight: 700,
      color: 'var(--text-heading)'
    }
  }, title), actions) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      padding,
      ...bodyStyle
    }
  }, children));
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data/Card.jsx", error: String((e && e.message) || e) }); }

// components/data/DataTable.jsx
try { (() => {
/** Hairline table with a grey header row. Row-group labels may span the left column. */
function DataTable({
  columns = [],
  rows = [],
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      overflowX: 'auto',
      ...style
    }
  }, /*#__PURE__*/React.createElement("table", {
    style: {
      width: '100%',
      borderCollapse: 'collapse',
      fontSize: 'var(--fs-body-sm)'
    }
  }, /*#__PURE__*/React.createElement("thead", null, /*#__PURE__*/React.createElement("tr", null, columns.map(c => {
    const col = typeof c === 'string' ? {
      key: c,
      label: c
    } : c;
    return /*#__PURE__*/React.createElement("th", {
      key: col.key,
      style: {
        textAlign: col.align || 'left',
        padding: '14px 16px',
        fontWeight: 700,
        background: col.label ? 'var(--ink-025)' : 'transparent',
        color: 'var(--text-body)',
        borderBottom: '1px solid var(--divider)',
        whiteSpace: 'nowrap'
      }
    }, col.label);
  }))), /*#__PURE__*/React.createElement("tbody", null, rows.map((r, ri) => /*#__PURE__*/React.createElement("tr", {
    key: ri
  }, columns.map((c, ci) => {
    const col = typeof c === 'string' ? {
      key: c,
      label: c
    } : c;
    const cell = r[col.key];
    if (cell && cell.hidden) return null;
    const content = cell && typeof cell === 'object' && 'value' in cell ? cell.value : cell;
    return /*#__PURE__*/React.createElement("td", {
      key: col.key,
      rowSpan: cell && cell.rowSpan,
      style: {
        padding: '14px 16px',
        textAlign: col.align || 'left',
        borderBottom: '1px solid var(--divider)',
        borderRight: ci === 0 ? '1px solid var(--divider)' : 'none',
        fontWeight: cell && cell.bold ? 700 : 400,
        verticalAlign: 'middle',
        color: 'var(--text-body)'
      }
    }, content);
  }))))));
}
Object.assign(__ds_scope, { DataTable });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data/DataTable.jsx", error: String((e && e.message) || e) }); }

// components/data/KeyValueList.jsx
try { (() => {
/** Label-over-value grid (Trip Information) or tight label|value rows (map popover). */
function KeyValueList({
  items = [],
  columns = 2,
  variant = 'stacked',
  style
}) {
  if (variant === 'rows') {
    return /*#__PURE__*/React.createElement("div", {
      style: style
    }, items.map(it => /*#__PURE__*/React.createElement("div", {
      key: it.label,
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 16,
        padding: '7px 0',
        borderBottom: '1px solid var(--divider)'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        flex: '0 0 140px',
        fontSize: 'var(--fs-body-sm)',
        color: 'var(--text-body)'
      }
    }, it.label), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1,
        fontSize: 'var(--fs-body-sm)',
        fontWeight: it.strong === false ? 400 : 700,
        color: it.color || 'var(--text-body)'
      }
    }, it.value))));
  }
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'repeat(' + columns + ', minmax(0, 1fr))',
      gap: '20px 32px',
      ...style
    }
  }, items.map(it => /*#__PURE__*/React.createElement("div", {
    key: it.label,
    style: {
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 6,
      fontSize: 'var(--fs-label)',
      fontWeight: 700,
      color: 'var(--text-muted)',
      marginBottom: 4
    }
  }, it.label, it.badge), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-body)',
      color: it.color || 'var(--text-body)'
    }
  }, it.value))));
}
Object.assign(__ds_scope, { KeyValueList });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data/KeyValueList.jsx", error: String((e && e.message) || e) }); }

// components/data/LogList.jsx
try { (() => {
/** Event log: sentence on the left, timestamp right, hairline between rows. */
function LogList({
  entries = [],
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: style
  }, entries.map((e, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      display: 'flex',
      alignItems: 'baseline',
      justifyContent: 'space-between',
      gap: 24,
      padding: '14px 0',
      borderBottom: i === entries.length - 1 ? 'none' : '1px solid var(--divider)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body-sm)',
      color: 'var(--text-body)'
    }
  }, e.message), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-caption)',
      color: 'var(--text-muted)',
      whiteSpace: 'nowrap',
      flex: '0 0 auto'
    }
  }, e.timestamp))));
}
Object.assign(__ds_scope, { LogList });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data/LogList.jsx", error: String((e && e.message) || e) }); }

// components/data/Sparkline.jsx
try { (() => {
/** Tiny inline line chart. No axes, no grid — Convoy sparklines are bare strokes. */
function Sparkline({
  values = [],
  width = 260,
  height = 60,
  color = 'var(--teal-600)',
  strokeWidth = 2,
  style
}) {
  if (!values.length) return null;
  const min = Math.min(...values);
  const max = Math.max(...values);
  const span = max - min || 1;
  const pts = values.map((v, i) => {
    const x = i / (values.length - 1 || 1) * (width - strokeWidth * 2) + strokeWidth;
    const y = height - strokeWidth - (v - min) / span * (height - strokeWidth * 2);
    return x.toFixed(1) + ',' + y.toFixed(1);
  }).join(' ');
  return /*#__PURE__*/React.createElement("svg", {
    width: width,
    height: height,
    viewBox: '0 0 ' + width + ' ' + height,
    style: {
      display: 'block',
      ...style
    }
  }, /*#__PURE__*/React.createElement("polyline", {
    points: pts,
    fill: "none",
    stroke: color,
    strokeWidth: strokeWidth,
    strokeLinejoin: "round",
    strokeLinecap: "round"
  }));
}
Object.assign(__ds_scope, { Sparkline });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data/Sparkline.jsx", error: String((e && e.message) || e) }); }

// components/data/SpeedLegend.jsx
try { (() => {
/** The white capsule legend for speed-coloured routes. Floats on map tiles. */
function SpeedLegend({
  stops = [0, 20, 40, 60, 80, 100, 120],
  unit = 'km/h',
  style
}) {
  const colors = ['var(--speed-0)', 'var(--speed-20)', 'var(--speed-40)', 'var(--speed-60)', 'var(--speed-80)', 'var(--speed-100)'];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 14,
      background: 'var(--white)',
      maxWidth: '100%',
      borderRadius: 'var(--radius-xl)',
      boxShadow: 'var(--shadow-map-overlay)',
      padding: '10px 18px',
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body-sm)',
      fontWeight: 700,
      flex: '0 0 auto'
    }
  }, "Speed"), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      flex: 1,
      minWidth: 150
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      height: 11,
      borderRadius: 2,
      overflow: 'hidden'
    }
  }, colors.map(c => /*#__PURE__*/React.createElement("span", {
    key: c,
    style: {
      flex: 1,
      background: c
    }
  }))), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      marginTop: 3,
      position: 'relative',
      height: 16
    }
  }, stops.map((s, i) => /*#__PURE__*/React.createElement("span", {
    key: s,
    style: {
      position: 'absolute',
      left: i / (stops.length - 1) * 100 + '%',
      transform: 'translateX(-50%)',
      fontSize: 'var(--fs-caption)',
      color: 'var(--text-body)'
    }
  }, s)))), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body-sm)',
      marginLeft: 10,
      flex: '0 0 auto'
    }
  }, unit));
}
Object.assign(__ds_scope, { SpeedLegend });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data/SpeedLegend.jsx", error: String((e && e.message) || e) }); }

// components/data/StatCard.jsx
try { (() => {
/** KPI tile: label, big number, optional sparkline or a second label/value pair. */
function StatCard({
  label,
  value,
  secondaryLabel,
  secondaryValue,
  trend,
  trendColor,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'var(--surface-card)',
      border: '1px solid var(--ink-075)',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: '18px 20px',
      display: 'flex',
      flexDirection: 'column',
      gap: 4,
      minWidth: 0,
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body-sm)',
      color: 'var(--text-body)'
    }
  }, label), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-h1)',
      fontWeight: 700,
      lineHeight: 1.15,
      color: 'var(--text-heading)'
    }
  }, value), secondaryLabel ? /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body-sm)',
      color: 'var(--text-body)',
      marginTop: 10
    }
  }, secondaryLabel) : null, secondaryValue ? /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-h1)',
      fontWeight: 700,
      lineHeight: 1.15
    }
  }, secondaryValue) : null, trend ? /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 10
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Sparkline, {
    values: trend,
    width: 280,
    height: 64,
    color: trendColor || 'var(--teal-600)'
  })) : null);
}
Object.assign(__ds_scope, { StatCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data/StatCard.jsx", error: String((e && e.message) || e) }); }

// components/data/Timeline.jsx
try { (() => {
/** Trip Schedule Record: numbered stop markers on a teal spine, with per-stop detail. */
function Timeline({
  stops = [],
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: style
  }, stops.map((s, i) => {
    const last = i === stops.length - 1;
    const isStart = s.kind === 'start';
    return /*#__PURE__*/React.createElement("div", {
      key: i,
      style: {
        display: 'flex',
        gap: 14,
        position: 'relative'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        flex: '0 0 auto',
        width: 60
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 6
      }
    }, s.direction ? /*#__PURE__*/React.createElement("span", {
      style: {
        width: 24,
        height: 24,
        borderRadius: '50%',
        border: '1px solid var(--ink-100)',
        background: 'var(--white)',
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center'
      }
    }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: s.direction === 'down' ? 'arrow_downward' : 'arrow_upward',
      size: 15,
      color: s.direction === 'down' ? 'var(--green-600)' : 'var(--orange-500)',
      weight: 700
    })) : /*#__PURE__*/React.createElement("span", {
      style: {
        width: 24
      }
    }), isStart ? /*#__PURE__*/React.createElement("span", {
      style: {
        width: 28,
        height: 28,
        borderRadius: '50%',
        background: 'var(--orange-500)',
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center'
      }
    }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: "play_arrow",
      size: 18,
      color: "var(--white)"
    })) : /*#__PURE__*/React.createElement("span", {
      style: {
        width: 28,
        height: 28,
        borderRadius: '50%',
        background: 'var(--white)',
        border: '2px solid var(--teal-600)',
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: 'var(--fs-label)',
        fontWeight: 700,
        color: 'var(--teal-800)'
      }
    }, s.index)), last ? null : /*#__PURE__*/React.createElement("span", {
      style: {
        width: 2,
        flex: 1,
        minHeight: 22,
        background: 'var(--teal-600)',
        marginLeft: 15
      }
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        minWidth: 0,
        paddingBottom: last ? 0 : 22
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        flexWrap: 'wrap'
      }
    }, s.time ? /*#__PURE__*/React.createElement("span", {
      style: {
        background: 'var(--surface-field)',
        borderRadius: 'var(--radius-lg)',
        padding: '4px 12px',
        fontSize: 'var(--fs-body-sm)'
      }
    }, s.time) : null, /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--fs-body)',
        fontWeight: 700
      }
    }, s.title), s.coords ? /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--fs-body-sm)',
        color: 'var(--text-body)'
      }
    }, "(", s.coords, ")") : null), s.lines && s.lines.length ? /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 6,
        fontSize: 'var(--fs-body-sm)',
        lineHeight: 1.7,
        color: 'var(--text-body)'
      }
    }, s.lines.map((l, li) => /*#__PURE__*/React.createElement("div", {
      key: li
    }, typeof l === 'string' ? l : /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("span", null, l.label, ": "), /*#__PURE__*/React.createElement("b", null, l.value))))) : null));
  }));
}
Object.assign(__ds_scope, { Timeline });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data/Timeline.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Avatar.jsx
try { (() => {
/** Circular photo, or a single-initial teal-tint circle when no photo exists. */
function Avatar({
  src,
  name = '',
  size = 40,
  style
}) {
  const initial = name.trim().charAt(0).toUpperCase();
  return src ? /*#__PURE__*/React.createElement("img", {
    src: src,
    alt: name,
    style: {
      width: size,
      height: size,
      borderRadius: '50%',
      objectFit: 'cover',
      flex: '0 0 auto',
      background: 'var(--ink-050)',
      ...style
    }
  }) : /*#__PURE__*/React.createElement("span", {
    style: {
      width: size,
      height: size,
      borderRadius: '50%',
      flex: '0 0 auto',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'var(--teal-050)',
      color: 'var(--teal-800)',
      fontSize: Math.round(size * 0.42),
      fontWeight: 700,
      ...style
    }
  }, initial);
}
Object.assign(__ds_scope, { Avatar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Avatar.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Chip.jsx
try { (() => {
/** Removable white pill — the tag shape. */
function Chip({
  children,
  onRemove,
  tone = 'default',
  style
}) {
  const tones = {
    default: {
      background: 'var(--white)',
      border: '1px solid var(--ink-075)',
      color: 'var(--text-body)'
    },
    brand: {
      background: 'var(--teal-100)',
      border: '1px solid var(--teal-200)',
      color: 'var(--teal-800)'
    }
  };
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 8,
      height: 30,
      padding: onRemove ? '0 6px 0 12px' : '0 12px',
      borderRadius: 'var(--radius-pill)',
      fontSize: 'var(--fs-body-sm)',
      ...tones[tone],
      ...style
    }
  }, children, onRemove ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "close",
    size: 16,
    color: "var(--ink-500)",
    onClick: onRemove,
    style: {
      cursor: 'pointer'
    }
  }) : null);
}
Object.assign(__ds_scope, { Chip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Chip.jsx", error: String((e && e.message) || e) }); }

// components/feedback/CountChip.jsx
try { (() => {
/** Small numeric chip that rides inside filters and counters. */
function CountChip({
  children,
  tone = 'brand',
  style
}) {
  const tones = {
    brand: {
      background: 'var(--teal-800)',
      color: 'var(--white)'
    },
    danger: {
      background: 'var(--red-500)',
      color: 'var(--white)'
    },
    neutral: {
      background: 'var(--ink-050)',
      color: 'var(--ink-500)'
    }
  };
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      minWidth: 22,
      height: 22,
      padding: '0 6px',
      borderRadius: 'var(--radius-sm)',
      fontSize: 'var(--fs-caption)',
      fontWeight: 700,
      ...tones[tone],
      ...style
    }
  }, children);
}
Object.assign(__ds_scope, { CountChip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/CountChip.jsx", error: String((e && e.message) || e) }); }

// components/feedback/FilterChip.jsx
try { (() => {
/** Toolbar filter button. Active = 2px teal border + teal bold label + count chip. */
function FilterChip({
  children,
  icon,
  count,
  active = false,
  onClick,
  style
}) {
  return /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: onClick,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 10,
      height: 44,
      padding: '0 14px',
      cursor: 'pointer',
      background: 'var(--white)',
      borderRadius: 'var(--radius-lg)',
      fontFamily: 'var(--font-sans)',
      fontSize: 'var(--fs-body)',
      transition: 'var(--transition-control)',
      border: active ? '2px solid var(--teal-800)' : '1px solid var(--ink-100)',
      color: active ? 'var(--teal-800)' : 'var(--ink-300)',
      fontWeight: active ? 700 : 400,
      ...style
    }
  }, icon ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 20,
    color: active ? 'var(--teal-800)' : 'var(--ink-800)'
  }) : null, children, count != null ? /*#__PURE__*/React.createElement(__ds_scope.CountChip, null, count) : null);
}
Object.assign(__ds_scope, { FilterChip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/FilterChip.jsx", error: String((e && e.message) || e) }); }

// components/feedback/MetaPill.jsx
try { (() => {
/** Grey label + bold value strip, as in the Reports header block. */
function MetaPill({
  label,
  value,
  style
}) {
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 14,
      background: 'var(--surface-field)',
      borderRadius: 'var(--radius-lg)',
      padding: '7px 14px',
      fontSize: 'var(--fs-body-sm)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-body)'
    }
  }, label), /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 700,
      color: 'var(--text-body)'
    }
  }, value));
}
Object.assign(__ds_scope, { MetaPill });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/MetaPill.jsx", error: String((e && e.message) || e) }); }

// components/feedback/StatusBadge.jsx
try { (() => {
const cvBadgeTones = {
  success: {
    bg: 'var(--green-050)',
    fg: 'var(--green-600)'
  },
  warning: {
    bg: 'var(--orange-050)',
    fg: 'var(--orange-500)'
  },
  danger: {
    bg: 'var(--red-050)',
    fg: 'var(--red-500)'
  },
  info: {
    bg: 'var(--teal-050)',
    fg: 'var(--teal-600)'
  },
  neutral: {
    bg: 'var(--ink-050)',
    fg: 'var(--ink-400)'
  }
};
const cvBadgeSolid = {
  success: {
    bg: 'var(--green-600)',
    fg: 'var(--white)'
  },
  warning: {
    bg: 'var(--orange-400)',
    fg: 'var(--white)'
  },
  danger: {
    bg: 'var(--red-500)',
    fg: 'var(--white)'
  },
  info: {
    bg: 'var(--teal-600)',
    fg: 'var(--white)'
  },
  neutral: {
    bg: 'var(--ink-400)',
    fg: 'var(--white)'
  }
};

/** Trip / vehicle state chip. Tinted in lists, solid on maps and dark panels. */
function StatusBadge({
  children,
  tone = 'neutral',
  solid = false,
  icon,
  size = 'md',
  style
}) {
  const c = (solid ? cvBadgeSolid : cvBadgeTones)[tone] || cvBadgeTones.neutral;
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 6,
      borderRadius: 'var(--radius-sm)',
      padding: size === 'sm' ? '3px 8px' : '5px 10px',
      fontSize: size === 'sm' ? 'var(--fs-caption)' : 'var(--fs-label)',
      fontWeight: 700,
      background: c.bg,
      color: c.fg,
      whiteSpace: 'nowrap',
      ...style
    }
  }, icon ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: size === 'sm' ? 14 : 16
  }) : null, children);
}
Object.assign(__ds_scope, { StatusBadge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/StatusBadge.jsx", error: String((e && e.message) || e) }); }

// components/feedback/StatusSegments.jsx
try { (() => {
/** The three-up fleet counter from Live View: big number over a caption, one tile per state. */
function StatusSegments({
  segments = [],
  activeId,
  onSelect,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 2,
      ...style
    }
  }, segments.map(s => {
    const dim = activeId && activeId !== s.id;
    return /*#__PURE__*/React.createElement("button", {
      key: s.id,
      type: "button",
      onClick: () => onSelect && onSelect(s.id),
      style: {
        flex: 1,
        border: 'none',
        cursor: 'pointer',
        padding: '10px 12px 12px',
        textAlign: 'left',
        borderRadius: 'var(--radius-lg)',
        background: s.color,
        color: 'var(--white)',
        opacity: dim ? 0.55 : 1,
        transition: 'opacity var(--dur-fast) var(--ease-standard)'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        display: 'block',
        fontSize: 'var(--fs-label)',
        fontWeight: 700
      }
    }, s.label), /*#__PURE__*/React.createElement("span", {
      style: {
        display: 'block',
        fontSize: 26,
        fontWeight: 700,
        lineHeight: 1.15
      }
    }, s.count));
  }));
}
Object.assign(__ds_scope, { StatusSegments });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/StatusSegments.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Tooltip.jsx
try { (() => {
/** White bubble with a caret. One short sentence, no full stop. */
function Tooltip({
  children,
  content,
  placement = 'top',
  style
}) {
  const [open, setOpen] = React.useState(false);
  const vertical = placement === 'top' ? {
    bottom: 'calc(100% + 10px)'
  } : {
    top: 'calc(100% + 10px)'
  };
  return /*#__PURE__*/React.createElement("span", {
    onMouseEnter: () => setOpen(true),
    onMouseLeave: () => setOpen(false),
    style: {
      position: 'relative',
      display: 'inline-flex',
      ...style
    }
  }, children, open ? /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      left: '50%',
      transform: 'translateX(-50%)',
      ...vertical,
      background: 'var(--surface-popover)',
      color: 'var(--text-body)',
      fontSize: 'var(--fs-body)',
      padding: '10px 14px',
      borderRadius: 'var(--radius-xl)',
      boxShadow: 'var(--shadow-popover)',
      whiteSpace: 'nowrap',
      zIndex: 40,
      pointerEvents: 'none'
    }
  }, content, /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      left: '50%',
      marginLeft: -6,
      ...(placement === 'top' ? {
        top: '100%'
      } : {
        bottom: '100%'
      }),
      width: 0,
      height: 0,
      borderLeft: '6px solid transparent',
      borderRight: '6px solid transparent',
      ...(placement === 'top' ? {
        borderTop: '7px solid var(--white)'
      } : {
        borderBottom: '7px solid var(--white)'
      })
    }
  })) : null);
}
Object.assign(__ds_scope, { Tooltip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Tooltip.jsx", error: String((e && e.message) || e) }); }

// components/fleet/MapOverlayCard.jsx
try { (() => {
/** White capsule that floats on map tiles — Convoy's alternative to scrim gradients. */
function MapOverlayCard({
  children,
  header,
  radius = 'var(--radius-xl)',
  padding = 0,
  width,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'var(--white)',
      borderRadius: radius,
      boxShadow: 'var(--shadow-map-overlay)',
      overflow: 'hidden',
      width,
      padding,
      ...style
    }
  }, header ? /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      padding: '10px 14px',
      borderBottom: '1px solid var(--divider)'
    }
  }, header) : null, children);
}
Object.assign(__ds_scope, { MapOverlayCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/fleet/MapOverlayCard.jsx", error: String((e && e.message) || e) }); }

// components/fleet/SchedulerBlock.jsx
try { (() => {
const cvBlockTones = {
  confirmed: {
    bg: 'var(--block-confirmed)',
    bar: 'var(--green-600)'
  },
  scheduled: {
    bg: 'var(--block-scheduled)',
    bar: 'var(--teal-600)'
  },
  conflict: {
    bg: 'var(--block-conflict)',
    bar: 'var(--red-500)'
  },
  unassigned: {
    bg: 'var(--block-unassigned)',
    bar: 'var(--ink-100)'
  },
  pending: {
    bg: 'var(--orange-050)',
    bar: 'var(--orange-500)'
  }
};

/** One trip on the scheduler grid. 8px radius, tinted fill, 4px state bar on the left. */
function SchedulerBlock({
  client,
  site,
  service,
  driver,
  seats,
  vehicleType,
  window: timeWindow,
  route,
  tone = 'scheduled',
  cancelled = false,
  onClick,
  style
}) {
  const t = cvBlockTones[tone] || cvBlockTones.scheduled;
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    style: {
      position: 'relative',
      overflow: 'hidden',
      cursor: 'pointer',
      boxSizing: 'border-box',
      background: t.bg,
      borderRadius: 'var(--radius-lg)',
      border: '1px solid var(--ink-100)',
      padding: '7px 10px 8px 12px',
      fontSize: 'var(--fs-caption)',
      lineHeight: 1.5,
      color: 'var(--text-body)',
      minWidth: 0,
      ...(cancelled ? {
        backgroundImage: 'repeating-linear-gradient(135deg, rgba(22,22,22,.06) 0 6px, transparent 6px 12px)'
      } : null),
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      left: 0,
      top: 0,
      bottom: 0,
      width: 4,
      background: t.bar
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, client, site ? /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--ink-150)'
    }
  }, " | ") : null, site, service ? /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--ink-150)'
    }
  }, " | ") : null, service), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 6,
      whiteSpace: 'nowrap',
      overflow: 'hidden'
    }
  }, seats != null ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("span", null, seats), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "accessible",
    size: 13,
    color: "var(--ink-600)"
  })) : null, driver ? /*#__PURE__*/React.createElement("span", {
    style: {
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, driver) : null), route ? /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 5
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "repeat",
    size: 13,
    color: "var(--teal-600)"
  }), route) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      whiteSpace: 'nowrap'
    }
  }, vehicleType ? /*#__PURE__*/React.createElement("span", null, vehicleType) : null, timeWindow ? /*#__PURE__*/React.createElement("span", null, timeWindow) : null));
}
Object.assign(__ds_scope, { SchedulerBlock });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/fleet/SchedulerBlock.jsx", error: String((e && e.message) || e) }); }

// components/fleet/TripListCard.jsx
try { (() => {
/** One trip in the Trip History list: id + status, client, site, a 2×2 meta grid, vehicle row. */
function TripListCard({
  tripId,
  status,
  statusTone = 'success',
  client,
  site,
  date,
  time,
  vehicle,
  onTime,
  vehicleName,
  vehicleId,
  vehicleThumb,
  selected = false,
  onClick,
  style
}) {
  const meta = (icon, text) => /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 10,
      fontSize: 'var(--fs-body)'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 20,
    color: "var(--teal-600)"
  }), text);
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    style: {
      padding: '18px 20px',
      cursor: 'pointer',
      borderBottom: '1px solid var(--divider)',
      background: selected ? 'var(--teal-050)' : 'var(--white)',
      borderLeft: selected ? '4px solid var(--teal-800)' : '4px solid transparent',
      transition: 'var(--transition-control)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-start',
      justifyContent: 'space-between',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body-lg)',
      fontWeight: 700
    }
  }, tripId), status ? /*#__PURE__*/React.createElement(__ds_scope.StatusBadge, {
    tone: statusTone
  }, status) : null), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-body)',
      marginTop: 8
    }
  }, client), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-body)'
    }
  }, site), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: '10px 16px',
      marginTop: 14
    }
  }, meta('calendar_month', date), meta('schedule', time), meta('directions_bus', vehicle), meta('brightness_2', onTime)), vehicleName ? /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      marginTop: 14
    }
  }, vehicleThumb ? /*#__PURE__*/React.createElement("img", {
    src: vehicleThumb,
    alt: "",
    style: {
      width: 42,
      height: 42,
      borderRadius: '50%',
      objectFit: 'cover',
      background: 'var(--ink-025)'
    }
  }) : /*#__PURE__*/React.createElement("span", {
    style: {
      width: 42,
      height: 42,
      borderRadius: '50%',
      background: 'var(--ink-025)'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body-sm)',
      lineHeight: 1.4
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block'
    }
  }, vehicleName), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block'
    }
  }, vehicleId))) : null);
}
Object.assign(__ds_scope, { TripListCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/fleet/TripListCard.jsx", error: String((e && e.message) || e) }); }

// components/fleet/VehicleRow.jsx
try { (() => {
/** Scheduler left-column row: vehicle thumb + plate, driver, seat count tile. */
function VehicleRow({
  plate,
  driver,
  driverAvatar,
  vehicleThumb,
  seats,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 14,
      padding: '12px 16px',
      minWidth: 0,
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0,
      display: 'flex',
      flexDirection: 'column',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      minWidth: 0
    }
  }, vehicleThumb ? /*#__PURE__*/React.createElement("img", {
    src: vehicleThumb,
    alt: "",
    style: {
      width: 44,
      height: 34,
      objectFit: 'contain',
      flex: '0 0 auto'
    }
  }) : /*#__PURE__*/React.createElement("span", {
    style: {
      width: 44,
      height: 34,
      background: 'var(--ink-025)',
      borderRadius: 'var(--radius-sm)',
      flex: '0 0 auto'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body-lg)',
      fontWeight: 700,
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    }
  }, plate)), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Avatar, {
    src: driverAvatar,
    name: driver,
    size: 34
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body)',
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    }
  }, driver))), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: '0 0 auto',
      width: 52,
      textAlign: 'center',
      background: 'var(--surface-field)',
      borderRadius: 'var(--radius-lg)',
      padding: '6px 0 7px'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontSize: 'var(--fs-h4)',
      fontWeight: 700,
      lineHeight: 1.2
    }
  }, seats), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontSize: 'var(--fs-micro)',
      color: 'var(--text-muted)'
    }
  }, "Seat")));
}
Object.assign(__ds_scope, { VehicleRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/fleet/VehicleRow.jsx", error: String((e && e.message) || e) }); }

// components/forms/Checkbox.jsx
try { (() => {
/** 22px square, 3px radius, teal when checked. */
function Checkbox({
  label,
  checked = false,
  onChange,
  disabled = false,
  style
}) {
  return /*#__PURE__*/React.createElement("label", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 12,
      cursor: disabled ? 'not-allowed' : 'pointer',
      fontSize: 'var(--fs-body)',
      color: disabled ? 'var(--text-disabled)' : 'var(--text-body)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 22,
      height: 22,
      borderRadius: 'var(--radius-xs)',
      flex: '0 0 auto',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      border: checked ? '2px solid var(--teal-800)' : '2px solid var(--ink-150)',
      background: checked ? 'var(--teal-800)' : 'var(--white)',
      transition: 'var(--transition-control)'
    }
  }, checked ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "check",
    size: 16,
    color: "var(--white)",
    weight: 700
  }) : null), /*#__PURE__*/React.createElement("input", {
    type: "checkbox",
    checked: checked,
    onChange: onChange,
    disabled: disabled,
    style: {
      position: 'absolute',
      opacity: 0,
      width: 0,
      height: 0
    }
  }), label);
}
Object.assign(__ds_scope, { Checkbox });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Checkbox.jsx", error: String((e && e.message) || e) }); }

// components/forms/FieldLabel.jsx
try { (() => {
/** Label row above a field: bold label, optional ⓘ hint, right-aligned "Optional". */
function FieldLabel({
  children,
  hint,
  optional = false,
  htmlFor,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      marginBottom: 6,
      ...style
    }
  }, /*#__PURE__*/React.createElement("label", {
    htmlFor: htmlFor,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 6,
      fontSize: 'var(--fs-label)',
      fontWeight: 700,
      color: 'var(--text-body)'
    }
  }, children, hint ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "info",
    size: 16,
    fill: false,
    color: "var(--teal-600)",
    title: hint
  }) : null), optional ? /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-label)',
      color: 'var(--text-muted)'
    }
  }, "Optional") : null);
}
Object.assign(__ds_scope, { FieldLabel });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/FieldLabel.jsx", error: String((e && e.message) || e) }); }

// components/forms/ColorField.jsx
try { (() => {
/** Hex text + a solid swatch block on the right of the field. Used for route colour. */
function ColorField({
  label = 'Route Color',
  hint,
  optional,
  value = '#E22629',
  onChange,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      ...style
    }
  }, label ? /*#__PURE__*/React.createElement(__ds_scope.FieldLabel, {
    hint: hint,
    optional: optional
  }, label) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      height: 'var(--field-height)',
      background: 'var(--surface-field)',
      borderRadius: 'var(--radius-lg)',
      overflow: 'hidden',
      boxSizing: 'border-box'
    }
  }, /*#__PURE__*/React.createElement("input", {
    value: value,
    onChange: onChange,
    style: {
      flex: 1,
      minWidth: 0,
      border: 'none',
      background: 'transparent',
      outline: 'none',
      font: 'inherit',
      fontSize: 'var(--fs-body)',
      padding: '0 16px'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 44,
      alignSelf: 'stretch',
      background: value,
      flex: '0 0 auto'
    }
  })));
}
Object.assign(__ds_scope, { ColorField });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/ColorField.jsx", error: String((e && e.message) || e) }); }

// components/forms/DateField.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const cvFieldBox = {
  display: 'flex',
  alignItems: 'center',
  gap: 10,
  width: '100%',
  boxSizing: 'border-box',
  height: 'var(--field-height)',
  padding: '0 16px',
  background: 'var(--surface-field)',
  border: 'none',
  borderRadius: 'var(--radius-lg)',
  fontFamily: 'var(--font-sans)',
  fontSize: 'var(--fs-body)',
  color: 'var(--text-body)',
  outline: 'none'
};

/** Date field: filled shell, DD/MM/YYYY text, trailing calendar glyph. */
function DateField({
  label,
  hint,
  optional,
  value,
  placeholder = 'DD/MM/YYYY',
  onChange,
  disabled,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      ...style
    }
  }, label ? /*#__PURE__*/React.createElement(__ds_scope.FieldLabel, {
    hint: hint,
    optional: optional
  }, label) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      ...cvFieldBox,
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement("input", _extends({
    value: value,
    placeholder: placeholder,
    onChange: onChange,
    disabled: disabled,
    style: {
      flex: 1,
      minWidth: 0,
      border: 'none',
      background: 'transparent',
      outline: 'none',
      font: 'inherit',
      color: 'inherit',
      padding: 0
    }
  }, rest)), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "calendar_month",
    size: 20,
    fill: false,
    color: "var(--ink-600)"
  })));
}
Object.assign(__ds_scope, { DateField });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/DateField.jsx", error: String((e && e.message) || e) }); }

// components/forms/FileDrop.jsx
try { (() => {
/** Dashed drop zone with a teal "Browse" affordance, plus an attached-file row. */
function FileDrop({
  label = 'Drag and drop to upload or',
  hintText,
  files = [],
  onRemove,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 6,
      minHeight: 84,
      padding: '14px 16px',
      border: '1px dashed var(--ink-150)',
      borderRadius: 'var(--radius-lg)',
      background: 'var(--white)',
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body)',
      color: 'var(--text-body)'
    }
  }, label), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 6,
      fontSize: 'var(--fs-body)',
      fontWeight: 700,
      color: 'var(--teal-800)',
      cursor: 'pointer'
    }
  }, "Browse ", /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "upload_file",
    size: 18
  }))), hintText ? /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-caption)',
      color: 'var(--text-muted)',
      marginTop: 6
    }
  }, hintText) : null, files.map(name => /*#__PURE__*/React.createElement("div", {
    key: name,
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: 10,
      marginTop: 8,
      height: 36,
      padding: '0 12px',
      background: 'var(--surface-field)',
      borderRadius: 'var(--radius-lg)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body-sm)',
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    }
  }, name), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "delete",
    size: 18,
    color: "var(--red-500)",
    onClick: () => onRemove && onRemove(name),
    style: {
      cursor: 'pointer'
    }
  }))));
}
Object.assign(__ds_scope, { FileDrop });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/FileDrop.jsx", error: String((e && e.message) || e) }); }

// components/forms/Input.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const cvFieldBox = {
  display: 'flex',
  alignItems: 'center',
  gap: 10,
  width: '100%',
  boxSizing: 'border-box',
  height: 'var(--field-height)',
  padding: '0 16px',
  background: 'var(--surface-field)',
  border: 'none',
  borderRadius: 'var(--radius-lg)',
  fontFamily: 'var(--font-sans)',
  fontSize: 'var(--fs-body)',
  color: 'var(--text-body)',
  outline: 'none'
};

/** Filled text field — grey #F4F4F4 fill, no border at rest, optional unit suffix. */
function Input({
  label,
  hint,
  optional,
  suffix,
  icon,
  value,
  placeholder,
  invalid = false,
  disabled = false,
  readOnly = false,
  onChange,
  style,
  inputStyle,
  ...rest
}) {
  const [focus, setFocus] = React.useState(false);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      ...style
    }
  }, label ? /*#__PURE__*/React.createElement(__ds_scope.FieldLabel, {
    hint: hint,
    optional: optional
  }, label) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      ...cvFieldBox,
      ...(focus ? {
        boxShadow: 'var(--shadow-focus)'
      } : null),
      ...(invalid ? {
        boxShadow: 'inset 0 0 0 2px var(--red-500)'
      } : null),
      ...(disabled ? {
        color: 'var(--text-disabled)'
      } : null)
    }
  }, icon ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 18,
    color: "var(--ink-300)"
  }) : null, /*#__PURE__*/React.createElement("input", _extends({
    value: value,
    placeholder: placeholder,
    disabled: disabled,
    readOnly: readOnly,
    onChange: onChange,
    onFocus: () => setFocus(true),
    onBlur: () => setFocus(false),
    style: {
      flex: 1,
      minWidth: 0,
      border: 'none',
      background: 'transparent',
      outline: 'none',
      font: 'inherit',
      color: 'inherit',
      padding: 0,
      ...inputStyle
    }
  }, rest)), suffix ? /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-body)',
      fontSize: 'var(--fs-body)',
      flex: '0 0 auto'
    }
  }, suffix) : null));
}
Object.assign(__ds_scope, { Input });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Input.jsx", error: String((e && e.message) || e) }); }

// components/forms/PhoneField.jsx
try { (() => {
/** Country-code + number field. Convoy operates in SG, so +65 is the default. */
function PhoneField({
  label = 'Mobile Number',
  hint,
  optional,
  dialCode = '+65',
  value,
  placeholder = 'Number',
  onChange,
  flagSrc,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      ...style
    }
  }, label ? /*#__PURE__*/React.createElement(__ds_scope.FieldLabel, {
    hint: hint,
    optional: optional
  }, label) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      height: 'var(--field-height)',
      padding: '0 16px',
      background: 'var(--surface-field)',
      borderRadius: 'var(--radius-lg)',
      boxSizing: 'border-box'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 4,
      flex: '0 0 auto',
      cursor: 'pointer'
    }
  }, flagSrc ? /*#__PURE__*/React.createElement("img", {
    src: flagSrc,
    alt: "",
    style: {
      width: 26,
      height: 18,
      objectFit: 'cover',
      borderRadius: 2
    }
  }) : /*#__PURE__*/React.createElement("span", {
    style: {
      width: 26,
      height: 18,
      borderRadius: 2,
      background: 'var(--ink-100)'
    }
  }), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "arrow_drop_down",
    size: 18,
    color: "var(--ink-500)"
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body)',
      color: 'var(--text-body)',
      flex: '0 0 auto'
    }
  }, dialCode), /*#__PURE__*/React.createElement("input", {
    value: value,
    placeholder: placeholder,
    onChange: onChange,
    style: {
      flex: 1,
      minWidth: 0,
      border: 'none',
      background: 'transparent',
      outline: 'none',
      font: 'inherit',
      fontSize: 'var(--fs-body)'
    }
  })));
}
Object.assign(__ds_scope, { PhoneField });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/PhoneField.jsx", error: String((e && e.message) || e) }); }

// components/forms/Radio.jsx
try { (() => {
/** 22px circle with a teal ring + dot when selected. */
function Radio({
  label,
  checked = false,
  onChange,
  name,
  disabled = false,
  style
}) {
  return /*#__PURE__*/React.createElement("label", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 12,
      cursor: disabled ? 'not-allowed' : 'pointer',
      fontSize: 'var(--fs-body)',
      color: disabled ? 'var(--text-disabled)' : 'var(--text-body)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 22,
      height: 22,
      borderRadius: '50%',
      flex: '0 0 auto',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      border: checked ? '2px solid var(--teal-800)' : '2px solid var(--ink-150)',
      background: 'var(--white)',
      transition: 'var(--transition-control)'
    }
  }, checked ? /*#__PURE__*/React.createElement("span", {
    style: {
      width: 10,
      height: 10,
      borderRadius: '50%',
      background: 'var(--teal-800)'
    }
  }) : null), /*#__PURE__*/React.createElement("input", {
    type: "radio",
    name: name,
    checked: checked,
    onChange: onChange,
    disabled: disabled,
    style: {
      position: 'absolute',
      opacity: 0,
      width: 0,
      height: 0
    }
  }), label);
}
Object.assign(__ds_scope, { Radio });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Radio.jsx", error: String((e && e.message) || e) }); }

// components/forms/SearchInput.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Toolbar search. White fill + hairline (over page grey) or grey fill inside a card. */
function SearchInput({
  placeholder = 'Search',
  value,
  onChange,
  variant = 'outline',
  width = 240,
  style,
  ...rest
}) {
  const shell = variant === 'outline' ? {
    background: 'var(--white)',
    border: '1px solid var(--ink-100)'
  } : {
    background: 'var(--surface-field)',
    border: 'none'
  };
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      width,
      height: 'var(--field-height)',
      padding: '0 14px',
      borderRadius: 'var(--radius-lg)',
      boxSizing: 'border-box',
      ...shell,
      ...style
    }
  }, /*#__PURE__*/React.createElement("input", _extends({
    value: value,
    onChange: onChange,
    placeholder: placeholder,
    style: {
      flex: 1,
      minWidth: 0,
      border: 'none',
      background: 'transparent',
      outline: 'none',
      font: 'inherit',
      fontSize: 'var(--fs-body)',
      color: 'var(--text-body)',
      padding: 0
    }
  }, rest)), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "search",
    size: 20,
    color: "var(--ink-800)"
  }));
}
Object.assign(__ds_scope, { SearchInput });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/SearchInput.jsx", error: String((e && e.message) || e) }); }

// components/forms/SegmentedControl.jsx
try { (() => {
/** Compact 2-4 option switch (Day / Week). Active segment = filled teal. */
function SegmentedControl({
  options = [],
  value,
  onChange,
  size = 'md',
  style
}) {
  const h = size === 'sm' ? 36 : 44;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'inline-flex',
      background: 'var(--white)',
      border: '1px solid var(--ink-100)',
      borderRadius: 'var(--radius-lg)',
      padding: 3,
      gap: 3,
      ...style
    }
  }, options.map(o => {
    const opt = typeof o === 'string' ? {
      value: o,
      label: o
    } : o;
    const on = opt.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: opt.value,
      type: "button",
      onClick: () => onChange && onChange(opt.value),
      style: {
        height: h - 8,
        minWidth: 74,
        padding: '0 18px',
        border: 'none',
        cursor: 'pointer',
        borderRadius: 'var(--radius-md)',
        fontFamily: 'var(--font-sans)',
        fontSize: 'var(--fs-body)',
        fontWeight: 700,
        transition: 'var(--transition-control)',
        background: on ? 'var(--teal-800)' : 'transparent',
        color: on ? 'var(--white)' : 'var(--ink-300)'
      }
    }, opt.label);
  }));
}
Object.assign(__ds_scope, { SegmentedControl });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/SegmentedControl.jsx", error: String((e && e.message) || e) }); }

// components/forms/Select.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const cvFieldBox = {
  display: 'flex',
  alignItems: 'center',
  gap: 10,
  width: '100%',
  boxSizing: 'border-box',
  height: 'var(--field-height)',
  padding: '0 16px',
  background: 'var(--surface-field)',
  border: 'none',
  borderRadius: 'var(--radius-lg)',
  fontFamily: 'var(--font-sans)',
  fontSize: 'var(--fs-body)',
  color: 'var(--text-body)',
  outline: 'none'
};

/** Filled select. Same shell as Input with a trailing chevron. */
function Select({
  label,
  hint,
  optional,
  value,
  onChange,
  options = [],
  placeholder,
  disabled = false,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      ...style
    }
  }, label ? /*#__PURE__*/React.createElement(__ds_scope.FieldLabel, {
    hint: hint,
    optional: optional
  }, label) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      ...cvFieldBox,
      position: 'relative',
      paddingRight: 12,
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement("select", _extends({
    value: value,
    onChange: onChange,
    disabled: disabled,
    style: {
      flex: 1,
      minWidth: 0,
      appearance: 'none',
      WebkitAppearance: 'none',
      border: 'none',
      background: 'transparent',
      outline: 'none',
      font: 'inherit',
      padding: 0,
      cursor: 'pointer',
      color: value === '' || value === undefined ? 'var(--text-placeholder)' : 'var(--text-body)'
    }
  }, rest), placeholder ? /*#__PURE__*/React.createElement("option", {
    value: ""
  }, placeholder) : null, options.map(o => {
    const opt = typeof o === 'string' ? {
      value: o,
      label: o
    } : o;
    return /*#__PURE__*/React.createElement("option", {
      key: opt.value,
      value: opt.value
    }, opt.label);
  })), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "expand_more",
    size: 20,
    color: "var(--ink-500)"
  })));
}
Object.assign(__ds_scope, { Select });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Select.jsx", error: String((e && e.message) || e) }); }

// components/forms/Switch.jsx
try { (() => {
/** Track switch — the dark teal capsule used on the Live View trace toggle. */
function Switch({
  checked = false,
  onChange,
  label,
  disabled = false,
  style
}) {
  return /*#__PURE__*/React.createElement("label", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 10,
      cursor: disabled ? 'not-allowed' : 'pointer',
      fontSize: 'var(--fs-body-sm)',
      color: 'var(--text-body)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    onClick: () => !disabled && onChange && onChange(!checked),
    style: {
      width: 40,
      height: 22,
      borderRadius: 'var(--radius-pill)',
      flex: '0 0 auto',
      position: 'relative',
      background: checked ? 'var(--teal-800)' : 'var(--ink-150)',
      transition: 'var(--transition-control)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: 3,
      left: checked ? 21 : 3,
      width: 16,
      height: 16,
      borderRadius: '50%',
      background: 'var(--white)',
      transition: 'left var(--dur-fast) var(--ease-standard)'
    }
  })), label);
}
Object.assign(__ds_scope, { Switch });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Switch.jsx", error: String((e && e.message) || e) }); }

// components/forms/TagInput.jsx
try { (() => {
/** Filled field holding removable white pill tags. */
function TagInput({
  label,
  hint,
  optional,
  tags = [],
  onRemove,
  placeholder = 'Add tag',
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      ...style
    }
  }, label ? /*#__PURE__*/React.createElement(__ds_scope.FieldLabel, {
    hint: hint,
    optional: optional
  }, label) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      flexWrap: 'wrap',
      minHeight: 'var(--field-height)',
      padding: '7px 12px',
      background: 'var(--surface-field)',
      borderRadius: 'var(--radius-lg)',
      boxSizing: 'border-box'
    }
  }, tags.map(t => /*#__PURE__*/React.createElement("span", {
    key: t,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 8,
      height: 30,
      padding: '0 6px 0 12px',
      background: 'var(--white)',
      border: '1px solid var(--ink-075)',
      borderRadius: 'var(--radius-pill)',
      fontSize: 'var(--fs-body-sm)',
      color: 'var(--text-body)'
    }
  }, t, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "close",
    size: 16,
    color: "var(--ink-500)",
    onClick: () => onRemove && onRemove(t),
    style: {
      cursor: 'pointer'
    }
  }))), /*#__PURE__*/React.createElement("input", {
    placeholder: tags.length ? '' : placeholder,
    style: {
      flex: 1,
      minWidth: 60,
      border: 'none',
      background: 'transparent',
      outline: 'none',
      font: 'inherit',
      fontSize: 'var(--fs-body)'
    }
  })));
}
Object.assign(__ds_scope, { TagInput });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/TagInput.jsx", error: String((e && e.message) || e) }); }

// components/forms/Textarea.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Filled multi-line field. Used for Notes and Internal Notes. */
function Textarea({
  label,
  hint,
  optional,
  rows = 4,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      ...style
    }
  }, label ? /*#__PURE__*/React.createElement(__ds_scope.FieldLabel, {
    hint: hint,
    optional: optional
  }, label) : null, /*#__PURE__*/React.createElement("textarea", _extends({
    rows: rows,
    style: {
      width: '100%',
      boxSizing: 'border-box',
      padding: '12px 16px',
      background: 'var(--surface-field)',
      border: 'none',
      borderRadius: 'var(--radius-lg)',
      fontFamily: 'var(--font-sans)',
      fontSize: 'var(--fs-body)',
      lineHeight: 'var(--lh-normal)',
      color: 'var(--text-body)',
      outline: 'none',
      resize: 'vertical'
    }
  }, rest)));
}
Object.assign(__ds_scope, { Textarea });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Textarea.jsx", error: String((e && e.message) || e) }); }

// components/forms/TogglePill.jsx
try { (() => {
/** Selectable pill — day-of-week picker, and any multi-select chip row. */
function TogglePill({
  children,
  selected = false,
  onClick,
  width,
  disabled = false,
  style
}) {
  return /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: onClick,
    disabled: disabled,
    style: {
      minWidth: width || 52,
      height: 44,
      padding: '0 12px',
      cursor: disabled ? 'not-allowed' : 'pointer',
      borderRadius: 'var(--radius-lg)',
      fontFamily: 'var(--font-sans)',
      fontSize: 'var(--fs-label)',
      fontWeight: 700,
      transition: 'var(--transition-control)',
      background: selected ? 'var(--teal-100)' : 'var(--surface-field)',
      color: selected ? 'var(--teal-800)' : 'var(--ink-300)',
      border: selected ? '2px solid var(--teal-800)' : 'none',
      ...style
    }
  }, children);
}
Object.assign(__ds_scope, { TogglePill });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/TogglePill.jsx", error: String((e && e.message) || e) }); }

// components/forms/YesNoToggle.jsx
try { (() => {
/** The NO / YES pair. Active half = 2px teal border + #E5EDEE fill, bold uppercase. */
function YesNoToggle({
  value = false,
  onChange,
  labels = ['NO', 'YES'],
  disabled = false,
  style
}) {
  const half = (isOn, text, side) => /*#__PURE__*/React.createElement("button", {
    type: "button",
    disabled: disabled,
    onClick: () => onChange && onChange(side === 'right'),
    style: {
      width: 84,
      height: 44,
      fontFamily: 'var(--font-sans)',
      fontSize: 'var(--fs-body)',
      fontWeight: 700,
      cursor: disabled ? 'not-allowed' : 'pointer',
      transition: 'var(--transition-control)',
      background: isOn ? 'var(--teal-100)' : 'var(--surface-field)',
      color: isOn ? 'var(--teal-800)' : 'var(--ink-300)',
      border: isOn ? '2px solid var(--teal-800)' : 'none',
      borderRadius: side === 'left' ? 'var(--radius-lg) 0 0 var(--radius-lg)' : '0 var(--radius-lg) var(--radius-lg) 0'
    }
  }, text);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'inline-flex',
      borderRadius: 'var(--radius-lg)',
      ...style
    }
  }, half(!value, labels[0], 'left'), half(value, labels[1], 'right'));
}
Object.assign(__ds_scope, { YesNoToggle });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/YesNoToggle.jsx", error: String((e && e.message) || e) }); }

// components/navigation/Breadcrumb.jsx
try { (() => {
/** Uppercase breadcrumb trail; the current page is teal. */
function Breadcrumb({
  items = [],
  style
}) {
  return /*#__PURE__*/React.createElement("nav", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      ...style
    }
  }, items.map((it, idx) => {
    const last = idx === items.length - 1;
    return /*#__PURE__*/React.createElement(React.Fragment, {
      key: it.label
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--fs-label)',
        fontWeight: 700,
        letterSpacing: 'var(--ls-wide)',
        textTransform: 'uppercase',
        cursor: last ? 'default' : 'pointer',
        color: last ? 'var(--teal-600)' : 'var(--text-body)'
      }
    }, it.label), last ? null : /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: "chevron_right",
      size: 18,
      color: "var(--ink-200)"
    }));
  }));
}
Object.assign(__ds_scope, { Breadcrumb });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/Breadcrumb.jsx", error: String((e && e.message) || e) }); }

// components/navigation/NavFlyout.jsx
try { (() => {
/** 216px white section panel beside a light NavRail: section title + item list. */
function NavFlyout({
  title,
  items = [],
  activeId,
  onSelect,
  wordmark,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: 'var(--flyout-width)',
      flex: '0 0 auto',
      background: 'var(--white)',
      borderRight: '1px solid var(--divider)',
      display: 'flex',
      flexDirection: 'column',
      ...style
    }
  }, wordmark ? /*#__PURE__*/React.createElement("div", {
    style: {
      height: 'var(--topbar-height)',
      display: 'flex',
      alignItems: 'center',
      padding: '0 20px',
      borderBottom: '1px solid var(--divider)',
      flex: '0 0 auto'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 800,
      letterSpacing: '-.01em',
      fontSize: 26,
      color: 'var(--teal-800)'
    }
  }, wordmark)) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '20px 12px'
    }
  }, title ? /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '0 12px 12px',
      fontSize: 'var(--fs-body-lg)',
      fontWeight: 700,
      color: 'var(--teal-800)'
    }
  }, title) : null, items.map(it => {
    const on = it.id === activeId;
    return /*#__PURE__*/React.createElement("button", {
      key: it.id,
      type: "button",
      onClick: () => onSelect && onSelect(it.id),
      style: {
        display: 'block',
        width: '100%',
        textAlign: 'left',
        border: 'none',
        cursor: 'pointer',
        padding: '11px 12px',
        borderRadius: 'var(--radius-md)',
        marginBottom: 2,
        fontFamily: 'var(--font-sans)',
        fontSize: 'var(--fs-body)',
        background: on ? 'var(--surface-selected)' : 'transparent',
        color: on ? 'var(--teal-800)' : 'var(--text-body)',
        transition: 'var(--transition-control)'
      }
    }, it.label);
  })));
}
Object.assign(__ds_scope, { NavFlyout });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/NavFlyout.jsx", error: String((e && e.message) || e) }); }

// components/navigation/NavRail.jsx
try { (() => {
/**
 * The fixed left icon rail. 88px dark teal (default), or 44px white when a
 * section flyout is open. A 4px teal bar marks the active item in compact mode;
 * in wide mode the active item is a white rounded tile.
 */
function NavRail({
  items = [],
  activeId,
  onSelect,
  variant = 'dark',
  wordmark = 'CV',
  showLogo = true,
  footerItems = [],
  style
}) {
  const dark = variant === 'dark';
  const width = dark ? 'var(--rail-width)' : 'var(--rail-width-compact)';
  const renderItem = it => {
    const on = it.id === activeId;
    return /*#__PURE__*/React.createElement("button", {
      key: it.id,
      type: "button",
      title: it.label,
      onClick: () => onSelect && onSelect(it.id),
      style: {
        position: 'relative',
        width: '100%',
        height: dark ? 60 : 56,
        border: 'none',
        background: 'transparent',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer',
        padding: 0
      }
    }, dark ? /*#__PURE__*/React.createElement("span", {
      style: {
        width: 40,
        height: 40,
        borderRadius: 'var(--radius-lg)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: on ? 'var(--white)' : 'transparent',
        transition: 'var(--transition-control)'
      }
    }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: it.icon,
      size: 24,
      color: on ? 'var(--teal-800)' : 'rgba(255,255,255,.72)'
    })) : /*#__PURE__*/React.createElement(React.Fragment, null, on ? /*#__PURE__*/React.createElement("span", {
      style: {
        position: 'absolute',
        left: 0,
        top: 8,
        bottom: 8,
        width: 4,
        background: 'var(--teal-800)'
      }
    }) : null, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: it.icon,
      size: 24,
      color: on ? 'var(--teal-800)' : 'var(--ink-200)'
    })));
  };
  return /*#__PURE__*/React.createElement("nav", {
    style: {
      width,
      flex: '0 0 auto',
      minHeight: '100%',
      display: 'flex',
      flexDirection: 'column',
      background: dark ? 'var(--surface-rail)' : 'var(--surface-rail-compact)',
      borderRight: dark ? 'none' : '1px solid var(--divider)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: 'var(--topbar-height)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      flex: '0 0 auto',
      borderBottom: dark ? 'none' : '1px solid var(--divider)'
    }
  }, !showLogo ? null : /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 800,
      letterSpacing: '-.02em',
      fontSize: dark ? 24 : 18,
      color: dark ? 'var(--white)' : 'var(--teal-800)'
    }
  }, wordmark)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      paddingTop: 8,
      flex: 1,
      overflow: 'hidden'
    }
  }, items.map(renderItem)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      paddingBottom: 10
    }
  }, footerItems.map(renderItem)));
}
Object.assign(__ds_scope, { NavRail });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/NavRail.jsx", error: String((e && e.message) || e) }); }

// components/navigation/Stepper.jsx
try { (() => {
/** Numbered horizontal wizard steps joined by a hairline. */
function Stepper({
  steps = [],
  current = 0,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center'
    }
  }, steps.map((s, i) => {
    const done = i <= current;
    return /*#__PURE__*/React.createElement(React.Fragment, {
      key: s
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 36,
        height: 36,
        flex: '0 0 auto',
        borderRadius: '50%',
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: 'var(--fs-body-sm)',
        fontWeight: 700,
        background: 'var(--white)',
        border: done ? '2px solid var(--teal-800)' : '1px solid var(--teal-200)',
        color: done ? 'var(--teal-800)' : 'var(--teal-300)'
      }
    }, i + 1), i < steps.length - 1 ? /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1,
        height: 1,
        background: 'var(--teal-200)'
      }
    }) : null);
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      marginTop: 14
    }
  }, steps.map((s, i) => /*#__PURE__*/React.createElement("span", {
    key: s,
    style: {
      flex: i === 0 || i === steps.length - 1 ? '1 1 0' : '2 1 0',
      textAlign: i === 0 ? 'left' : i === steps.length - 1 ? 'right' : 'center',
      fontSize: 'var(--fs-label)',
      fontWeight: 700,
      letterSpacing: 'var(--ls-wide)',
      textTransform: 'uppercase',
      color: i === current ? 'var(--teal-600)' : 'var(--text-body)'
    }
  }, s))));
}
Object.assign(__ds_scope, { Stepper });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/Stepper.jsx", error: String((e && e.message) || e) }); }

// components/navigation/Tabs.jsx
try { (() => {
/** Underline tabs sitting on a hairline. */
function Tabs({
  tabs = [],
  value,
  onChange,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 32,
      borderBottom: '1px solid var(--divider)',
      ...style
    }
  }, tabs.map(t => {
    const tab = typeof t === 'string' ? {
      value: t,
      label: t
    } : t;
    const on = tab.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: tab.value,
      type: "button",
      onClick: () => onChange && onChange(tab.value),
      style: {
        border: 'none',
        background: 'transparent',
        cursor: 'pointer',
        padding: '0 0 12px',
        fontFamily: 'var(--font-sans)',
        fontSize: 'var(--fs-body)',
        fontWeight: on ? 700 : 400,
        color: 'var(--text-body)',
        borderBottom: on ? '2px solid var(--teal-800)' : '2px solid transparent',
        marginBottom: -1,
        transition: 'var(--transition-control)'
      }
    }, tab.label);
  }));
}
Object.assign(__ds_scope, { Tabs });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/Tabs.jsx", error: String((e && e.message) || e) }); }

// components/navigation/TopBar.jsx
try { (() => {
/** 65px white top bar: tenant lockup left, notifications + user block right. */
function TopBar({
  tenantName,
  tenantLogo,
  notificationCount = 0,
  userName,
  userEmail,
  userAvatar,
  right,
  style
}) {
  return /*#__PURE__*/React.createElement("header", {
    style: {
      height: 'var(--topbar-height)',
      flex: '0 0 auto',
      display: 'flex',
      alignItems: 'center',
      background: 'var(--surface-topbar)',
      borderBottom: '1px solid var(--divider)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 14,
      padding: '0 24px',
      flex: 1,
      minWidth: 0
    }
  }, tenantLogo ? /*#__PURE__*/React.createElement("img", {
    src: tenantLogo,
    alt: "",
    style: {
      width: 36,
      height: 36,
      borderRadius: 'var(--radius-md)',
      objectFit: 'cover'
    }
  }) : /*#__PURE__*/React.createElement("span", {
    style: {
      width: 36,
      height: 36,
      borderRadius: 'var(--radius-md)',
      background: 'var(--ink-900)',
      display: 'inline-block'
    }
  }), tenantName ? /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body)',
      fontWeight: 700,
      letterSpacing: 'var(--ls-wide)'
    }
  }, tenantName) : null), right, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      alignSelf: 'stretch',
      borderLeft: '1px solid var(--divider)',
      padding: '0 20px'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'relative',
      display: 'inline-flex',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "notifications",
    size: 24,
    color: "var(--ink-800)"
  }), notificationCount > 0 ? /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: -6,
      right: -8,
      minWidth: 18,
      height: 18,
      padding: '0 4px',
      borderRadius: 'var(--radius-pill)',
      background: 'var(--red-500)',
      color: 'var(--white)',
      fontSize: 11,
      fontWeight: 700,
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, notificationCount) : null)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      alignSelf: 'stretch',
      borderLeft: '1px solid var(--divider)',
      padding: '0 24px',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Avatar, {
    src: userAvatar,
    name: userName,
    size: 34
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      lineHeight: 1.25
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontSize: 'var(--fs-body-sm)',
      fontWeight: 700
    }
  }, userName), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontSize: 'var(--fs-caption)',
      color: 'var(--text-muted)'
    }
  }, userEmail))));
}
Object.assign(__ds_scope, { TopBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/TopBar.jsx", error: String((e && e.message) || e) }); }

// components/navigation/ViewToggle.jsx
try { (() => {
/** Two joined icon buttons switching list density/layout. */
function ViewToggle({
  options = [],
  value,
  onChange,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'inline-flex',
      background: 'var(--white)',
      border: '1px solid var(--ink-100)',
      borderRadius: 'var(--radius-lg)',
      overflow: 'hidden',
      ...style
    }
  }, options.map((o, i) => {
    const on = o.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: o.value,
      type: "button",
      title: o.label,
      onClick: () => onChange && onChange(o.value),
      style: {
        width: 44,
        height: 44,
        border: 'none',
        cursor: 'pointer',
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'var(--white)',
        borderLeft: i === 0 ? 'none' : '1px solid var(--ink-100)'
      }
    }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: o.icon,
      size: 22,
      color: on ? 'var(--teal-800)' : 'var(--ink-200)'
    }));
  }));
}
Object.assign(__ds_scope, { ViewToggle });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/ViewToggle.jsx", error: String((e && e.message) || e) }); }

// ui_kits/fleet_console/AppShell.jsx
try { (() => {
const {
  NavRail,
  NavFlyout,
  TopBar
} = window.ConvoyDesignSystem_cacf45;
const CV_SECTIONS = {
  monitoring: {
    title: 'Monitoring',
    items: [{
      id: 'live',
      label: 'Live View'
    }, {
      id: 'history',
      label: 'Trip History'
    }, {
      id: 'replay',
      label: 'Location Replay'
    }]
  },
  trips: {
    title: 'Trips & Bookings',
    items: [{
      id: 'onetime',
      label: 'One-time Trips'
    }, {
      id: 'recurring',
      label: 'Recurring Trips'
    }, {
      id: 'plans',
      label: 'Recurring Plans'
    }, {
      id: 'routes',
      label: 'Routes'
    }, {
      id: 'assignment',
      label: 'Trip Assignment List'
    }, {
      id: 'scheduler',
      label: 'Scheduler'
    }, {
      id: 'points',
      label: 'Saved Points'
    }, {
      id: 'notices',
      label: 'Notices'
    }]
  }
};
function AppShell() {
  const d = window.CVData;
  const [page, setPage] = React.useState('live');
  const section = page === 'history' || page === 'live' || page === 'replay' ? 'monitoring' : page === 'create' || page === 'scheduler' ? 'trips' : page === 'reports' ? 'reports' : 'monitoring';
  const flyout = page === 'history' || page === 'create' ? CV_SECTIONS[section] : null;
  const railActive = section === 'reports' ? 'reports' : section;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      height: '100%',
      minHeight: 0,
      background: 'var(--surface-page)'
    }
  }, /*#__PURE__*/React.createElement(NavRail, {
    variant: "dark",
    items: d.rail,
    footerItems: d.railFooter,
    activeId: railActive,
    showLogo: !flyout,
    wordmark: "CV",
    onSelect: id => setPage(id === 'monitoring' ? 'live' : id === 'trips' ? 'scheduler' : id === 'reports' ? 'reports' : page)
  }), flyout ? /*#__PURE__*/React.createElement(NavFlyout, {
    wordmark: "CONVOY",
    title: flyout.title,
    activeId: page === 'history' ? 'history' : 'routes',
    items: flyout.items,
    onSelect: id => setPage(id === 'history' ? 'history' : id === 'live' ? 'live' : id === 'scheduler' ? 'scheduler' : 'create')
  }) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0,
      display: 'flex',
      flexDirection: 'column'
    }
  }, /*#__PURE__*/React.createElement(TopBar, {
    tenantName: d.tenant,
    notificationCount: 12,
    userName: d.user.name,
    userEmail: d.user.email
  }), page === 'live' ? /*#__PURE__*/React.createElement(LiveView, null) : null, page === 'scheduler' ? /*#__PURE__*/React.createElement(Scheduler, null) : null, page === 'history' ? /*#__PURE__*/React.createElement(TripHistory, null) : null, page === 'reports' ? /*#__PURE__*/React.createElement(Reports, null) : null, page === 'create' ? /*#__PURE__*/React.createElement(CreateTrip, null) : null, ['live', 'scheduler', 'history', 'reports', 'create'].indexOf(page) === -1 ? /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      color: 'var(--text-muted)',
      fontSize: 'var(--fs-body)'
    }
  }, "This section was not part of the source material.") : null, /*#__PURE__*/React.createElement("nav", {
    style: {
      flex: '0 0 auto',
      display: 'flex',
      gap: 8,
      padding: '10px 24px',
      background: 'var(--white)',
      borderTop: '1px solid var(--divider)'
    }
  }, [['live', 'Live View'], ['scheduler', 'Scheduler'], ['history', 'Trip History'], ['reports', 'Reports'], ['create', 'Create Shuttle Trip']].map(([id, label]) => /*#__PURE__*/React.createElement("button", {
    key: id,
    onClick: () => setPage(id),
    style: {
      border: page === id ? '2px solid var(--teal-800)' : '1px solid var(--ink-100)',
      background: page === id ? 'var(--teal-100)' : 'var(--white)',
      color: page === id ? 'var(--teal-800)' : 'var(--ink-400)',
      fontWeight: page === id ? 700 : 400,
      fontFamily: 'var(--font-sans)',
      fontSize: 'var(--fs-label)',
      borderRadius: 'var(--radius-lg)',
      padding: '7px 14px',
      cursor: 'pointer',
      whiteSpace: 'nowrap'
    }
  }, label)), /*#__PURE__*/React.createElement("span", {
    style: {
      marginLeft: 'auto',
      alignSelf: 'center',
      fontSize: 'var(--fs-caption)',
      color: 'var(--ink-300)'
    }
  }, "UI kit screen switcher \u2014 not part of the product"))));
}
Object.assign(window, {
  AppShell
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/fleet_console/AppShell.jsx", error: String((e && e.message) || e) }); }

// ui_kits/fleet_console/CreateTrip.jsx
try { (() => {
const {
  Breadcrumb,
  Stepper,
  Button,
  IconButton,
  Card,
  Input,
  Select,
  Textarea,
  DateField,
  ColorField,
  PhoneField,
  TagInput,
  FieldLabel,
  YesNoToggle,
  TogglePill,
  Radio,
  Checkbox,
  FileDrop,
  Icon,
  Tooltip
} = window.ConvoyDesignSystem_cacf45;
function CvPointBlock({
  index
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      paddingTop: index === 1 ? 0 : 28,
      borderTop: index === 1 ? 'none' : '1px solid var(--divider)',
      marginTop: index === 1 ? 0 : 28
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      marginBottom: 16
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body-lg)',
      fontWeight: 700
    }
  }, "Point ", index), /*#__PURE__*/React.createElement("span", {
    style: {
      marginLeft: 'auto',
      display: 'inline-flex',
      gap: 4
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    icon: "remove_circle",
    color: "var(--red-500)",
    label: "Remove point"
  }), /*#__PURE__*/React.createElement(IconButton, {
    icon: "bookmark",
    color: "var(--green-600)",
    label: "Save point"
  }), /*#__PURE__*/React.createElement(IconButton, {
    icon: "unfold_more",
    color: "var(--teal-600)",
    label: "Reorder point"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'minmax(0,1fr) minmax(0,1fr)',
      gap: 24
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement(Input, {
    label: "Name of Point",
    defaultValue: index === 1 ? 'Boon Lay Ave' : 'Jurong West Central'
  }), /*#__PURE__*/React.createElement(Input, {
    label: "Lat Long",
    defaultValue: index === 1 ? '1.4958495, 1.12323434' : '1.4958499, 1.12323439'
  }), /*#__PURE__*/React.createElement(Input, {
    label: "Street View Link",
    optional: true,
    placeholder: "Street View Link"
  }), /*#__PURE__*/React.createElement(Input, {
    label: "Geofence Radius",
    defaultValue: "5",
    suffix: "m"
  }), /*#__PURE__*/React.createElement(Input, {
    label: "Location Comments",
    optional: true,
    placeholder: "Location Comments"
  }), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(FieldLabel, null, "Location Photo"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: "../../assets/map-point-detail.png",
    alt: "",
    style: {
      width: 78,
      height: 78,
      objectFit: 'cover',
      borderRadius: 'var(--radius-lg)',
      flex: '0 0 auto'
    }
  }), /*#__PURE__*/React.createElement(FileDrop, {
    hintText: "Maximum 300 x 300px, jpg and png supported"
  })))), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-label)',
      marginBottom: 6
    }
  }, /*#__PURE__*/React.createElement("b", null, "Map location"), " ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--ink-500)'
    }
  }, "(move the marker to adjust the exact position)")), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      height: 372,
      borderRadius: 'var(--radius-lg)',
      overflow: 'hidden',
      background: 'url(../../assets/map-point-detail.png) center / cover'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 12,
      right: 12,
      top: 12
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      height: 44,
      padding: '0 14px',
      background: 'var(--white)',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-map-overlay)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      fontSize: 'var(--fs-body)'
    }
  }, index === 1 ? 'Boon Lay Shopping Centre' : '445A Jurong West Central'), /*#__PURE__*/React.createElement(Icon, {
    name: "search",
    size: 20,
    color: "var(--ink-800)"
  })))))));
}
function CreateTrip() {
  const [step, setStep] = React.useState(0);
  const [days, setDays] = React.useState(['Mon', 'Wed', 'Fri']);
  const [flags, setFlags] = React.useState({
    seat: false,
    rider: false,
    count: true,
    recurring: true,
    contractor: false
  });
  const [end, setEnd] = React.useState('after');
  const [holiday, setHoliday] = React.useState(false);
  const [tags, setTags] = React.useState(['Google', 'WEN', 'Shuttle']);
  const set = (k, v) => setFlags({
    ...flags,
    [k]: v
  });
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minHeight: 0,
      display: 'flex',
      flexDirection: 'column'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minHeight: 0,
      overflow: 'auto',
      padding: 'var(--page-gutter)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement(Breadcrumb, {
    items: [{
      label: 'Routes'
    }, {
      label: 'Create New Shuttle Trip'
    }]
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      marginLeft: 'auto'
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    size: "sm",
    icon: "auto_awesome"
  }, "Create Route with Convoy AI"))), /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: 1080,
      margin: '32px auto 0'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: 720,
      margin: '0 auto 28px'
    }
  }, /*#__PURE__*/React.createElement(Stepper, {
    steps: ['Route Information', 'Shuttle Schedule', 'Review'],
    current: step
  })), /*#__PURE__*/React.createElement(Card, {
    title: "Trip Information",
    style: {
      marginBottom: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'minmax(0,1fr) minmax(0,1fr)',
      gap: '16px 24px'
    }
  }, /*#__PURE__*/React.createElement(Input, {
    label: "Trip Name",
    hint: "Name of this trip",
    defaultValue: "WEN Regular Shuttle"
  }), /*#__PURE__*/React.createElement(Select, {
    label: "Client",
    options: ['Google Pte Ltd', 'Grab Singapore']
  }), /*#__PURE__*/React.createElement(DateField, {
    label: "Start Date",
    defaultValue: "22/02/2023"
  }), /*#__PURE__*/React.createElement(Input, {
    label: "Capacity Required",
    defaultValue: "13",
    suffix: "Passengers"
  }), /*#__PURE__*/React.createElement(Select, {
    label: "Site",
    placeholder: "Site",
    options: ['WEN', 'Lakeside']
  }), /*#__PURE__*/React.createElement(Select, {
    label: "Contractor",
    placeholder: "Alex Hwang \xB7 alex.h@gmail.com \xB7 +65 67891011",
    options: ['Alex Hwang · alex.h@gmail.com']
  }), /*#__PURE__*/React.createElement(Input, {
    label: "Route Label",
    hint: "Label to display on the vehicle",
    optional: true,
    placeholder: "Route Label"
  }), /*#__PURE__*/React.createElement(Textarea, {
    label: "Notes",
    optional: true,
    placeholder: "Any other notes about this entire trip",
    rows: 2
  }), /*#__PURE__*/React.createElement(ColorField, {
    label: "Route Color",
    value: "#E22629"
  }), /*#__PURE__*/React.createElement("div", null), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(FieldLabel, null, "Seat reservation required"), /*#__PURE__*/React.createElement(YesNoToggle, {
    value: flags.seat,
    onChange: v => set('seat', v)
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(FieldLabel, null, "Approved rider required"), /*#__PURE__*/React.createElement(YesNoToggle, {
    value: flags.rider,
    onChange: v => set('rider', v)
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(FieldLabel, null, "Passenger Count"), /*#__PURE__*/React.createElement(YesNoToggle, {
    value: flags.count,
    onChange: v => set('count', v)
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(FieldLabel, null, "Recurring"), /*#__PURE__*/React.createElement(YesNoToggle, {
    value: flags.recurring,
    onChange: v => set('recurring', v)
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(FieldLabel, {
    hint: "Require the driver to use the main contractor app"
  }, "Main Contractor App"), /*#__PURE__*/React.createElement(YesNoToggle, {
    value: flags.contractor,
    onChange: v => set('contractor', v)
  })), /*#__PURE__*/React.createElement("div", null)), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 20
    }
  }, /*#__PURE__*/React.createElement(TagInput, {
    label: "Tag",
    optional: true,
    tags: tags,
    onRemove: t => setTags(tags.filter(x => x !== t))
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: '1px solid var(--divider)',
      margin: '24px 0'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'minmax(0,1fr) minmax(0,1.4fr)',
      gap: 24
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 20
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 16,
      alignItems: 'flex-end'
    }
  }, /*#__PURE__*/React.createElement(Input, {
    label: "Repeat every",
    defaultValue: "2",
    style: {
      maxWidth: 180
    }
  }), /*#__PURE__*/React.createElement(Select, {
    options: ['Day(s)', 'Week(s)', 'Month(s)'],
    value: "Week(s)",
    style: {
      maxWidth: 180
    }
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(FieldLabel, null, "End"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 14
    }
  }, /*#__PURE__*/React.createElement(Radio, {
    name: "end",
    label: "Never",
    checked: end === 'never',
    onChange: () => setEnd('never')
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement(Radio, {
    name: "end",
    label: "On",
    checked: end === 'on',
    onChange: () => setEnd('on')
  }), /*#__PURE__*/React.createElement(DateField, {
    placeholder: "Dec 12, 2023",
    style: {
      maxWidth: 220
    }
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement(Radio, {
    name: "end",
    label: "After",
    checked: end === 'after',
    onChange: () => setEnd('after')
  }), /*#__PURE__*/React.createElement(Input, {
    defaultValue: "10",
    suffix: "Occurences",
    style: {
      maxWidth: 220
    }
  })))), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(FieldLabel, null, "Public Holiday"), /*#__PURE__*/React.createElement(Checkbox, {
    label: "Exclude Singapore Public Holiday 2024",
    checked: holiday,
    onChange: () => setHoliday(!holiday)
  }))), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(FieldLabel, null, "Repeat on"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 10,
      flexWrap: 'wrap'
    }
  }, ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map(day => /*#__PURE__*/React.createElement(TogglePill, {
    key: day,
    selected: days.includes(day),
    onClick: () => setDays(days.includes(day) ? days.filter(x => x !== day) : [...days, day])
  }, day))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 28
    }
  }, /*#__PURE__*/React.createElement(FieldLabel, {
    optional: true
  }, "Attachments"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-caption)',
      color: 'var(--text-muted)',
      marginBottom: 8
    }
  }, "pdf and jpg supported, maximum file size 5 Mb"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement(FileDrop, {
    files: ['WEN Student List.pdf']
  }), /*#__PURE__*/React.createElement(FileDrop, {
    files: ['BUS Student List.pdf']
  })))))), /*#__PURE__*/React.createElement(Card, {
    title: "Point of Contact",
    style: {
      marginBottom: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 6,
      fontSize: 'var(--fs-label)',
      fontWeight: 700,
      marginBottom: 14
    }
  }, "Requestor ", /*#__PURE__*/React.createElement(Tooltip, {
    content: "Who asked for this trip"
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "info",
    size: 16,
    fill: false,
    color: "var(--ink-300)"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'minmax(0,1fr) minmax(0,1fr) minmax(0,1fr) 40px',
      gap: 16,
      alignItems: 'end'
    }
  }, /*#__PURE__*/React.createElement(Input, {
    label: "Name",
    defaultValue: "Alex"
  }), /*#__PURE__*/React.createElement(Input, {
    label: "Email",
    placeholder: "Email"
  }), /*#__PURE__*/React.createElement(PhoneField, null), /*#__PURE__*/React.createElement(IconButton, {
    icon: "drag_handle",
    label: "Reorder contact"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-label)',
      fontWeight: 700,
      margin: '24px 0 14px'
    }
  }, "Guest"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'minmax(0,1fr) minmax(0,1fr) minmax(0,1fr) 40px',
      gap: 16,
      alignItems: 'end'
    }
  }, /*#__PURE__*/React.createElement(Input, {
    label: "Name",
    defaultValue: "Benji Tran"
  }), /*#__PURE__*/React.createElement(Input, {
    label: "Email",
    defaultValue: "benji.t@gmail.com"
  }), /*#__PURE__*/React.createElement(PhoneField, {
    value: "67891011"
  }), /*#__PURE__*/React.createElement(IconButton, {
    icon: "remove_circle",
    color: "var(--red-500)",
    label: "Remove contact"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 20
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    size: "sm",
    icon: "person_add"
  }, "Add Second Guest"))), /*#__PURE__*/React.createElement(Card, {
    title: "Direction 1",
    style: {
      marginBottom: 16
    },
    actions: /*#__PURE__*/React.createElement(Input, {
      placeholder: "Direction Name",
      defaultValue: "Morning",
      style: {
        width: 280
      }
    })
  }, /*#__PURE__*/React.createElement(CvPointBlock, {
    index: 1
  }), /*#__PURE__*/React.createElement(CvPointBlock, {
    index: 2
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 24
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    size: "sm",
    icon: "add_location"
  }, "Add Point"))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'flex-start'
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    size: "sm",
    icon: "alt_route"
  }, "Add Direction 2")))), /*#__PURE__*/React.createElement("footer", {
    style: {
      flex: '0 0 auto',
      background: 'var(--white)',
      borderTop: '1px solid var(--divider)',
      padding: '14px 24px',
      display: 'flex',
      alignItems: 'center',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "ghost",
    icon: "chevron_left",
    iconPosition: "left",
    onClick: () => setStep(Math.max(0, step - 1)),
    style: {
      color: 'var(--ink-800)'
    }
  }, "Back"), /*#__PURE__*/React.createElement("span", {
    style: {
      marginLeft: 'auto',
      display: 'inline-flex',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "tertiary"
  }, "Cancel"), /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    icon: "save"
  }, "Save Draft"), /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    icon: "chevron_right",
    onClick: () => setStep(Math.min(2, step + 1))
  }, "Continue"))));
}
Object.assign(window, {
  CreateTrip
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/fleet_console/CreateTrip.jsx", error: String((e && e.message) || e) }); }

// ui_kits/fleet_console/LiveView.jsx
try { (() => {
const {
  StatusSegments,
  StatusBadge,
  MapOverlayCard,
  KeyValueList,
  Switch,
  Icon,
  IconButton
} = window.ConvoyDesignSystem_cacf45;
function LivePanelRow({
  v
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '12px 14px',
      borderBottom: '1px solid rgba(255,255,255,.08)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 26,
      height: 26,
      borderRadius: 'var(--radius-sm)',
      background: 'var(--teal-600)',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      flex: '0 0 auto'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "directions_bus",
    size: 16,
    color: "var(--white)"
  })), /*#__PURE__*/React.createElement(StatusBadge, {
    tone: v.tone,
    solid: true,
    size: "sm"
  }, v.badge), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-caption)',
      color: 'rgba(255,255,255,.8)'
    }
  }, v.at), /*#__PURE__*/React.createElement("span", {
    style: {
      marginLeft: 'auto',
      fontSize: 'var(--fs-caption)',
      color: 'rgba(255,255,255,.65)'
    }
  }, v.time)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-end',
      gap: 10,
      marginTop: 8
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontSize: 'var(--fs-body)',
      fontWeight: 700,
      color: 'var(--white)'
    }
  }, v.plate), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontSize: 'var(--fs-body-sm)',
      color: 'rgba(255,255,255,.55)'
    }
  }, v.driver)), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: '0 0 auto',
      width: 42,
      textAlign: 'center',
      background: 'var(--white)',
      borderRadius: 'var(--radius-sm)',
      padding: '3px 0 4px'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontSize: 'var(--fs-body)',
      fontWeight: 700,
      lineHeight: 1.2
    }
  }, v.seats), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontSize: 9,
      color: 'var(--ink-400)'
    }
  }, "Seat"))));
}
function LiveView() {
  const [filter, setFilter] = React.useState('ontrip');
  const [trace, setTrace] = React.useState(true);
  const [popover, setPopover] = React.useState(true);
  const rows = window.CVData.liveVehicles;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      flex: 1,
      minHeight: 0,
      display: 'flex'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      flex: 1,
      minWidth: 0,
      background: 'url(../../assets/map-live-fleet.png) top left / cover no-repeat'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 30,
      top: 18,
      display: 'flex',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 42,
      height: 42,
      borderRadius: 'var(--radius-lg) var(--radius-lg) 0 var(--radius-lg)',
      background: 'var(--green-600)',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      boxShadow: 'var(--shadow-map-overlay)'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "location_on",
    size: 24,
    color: "var(--white)"
  }))), popover ? /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 570,
      top: 0
    }
  }, /*#__PURE__*/React.createElement(MapOverlayCard, {
    width: 334,
    radius: "var(--radius-md)",
    header: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 24,
        height: 24,
        borderRadius: 'var(--radius-sm)',
        background: 'var(--teal-600)',
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "directions_bus",
      size: 15,
      color: "var(--white)"
    })), /*#__PURE__*/React.createElement(StatusBadge, {
      tone: "warning",
      size: "sm"
    }, "On the way"), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--fs-body-sm)'
      }
    }, "to Point 1"), /*#__PURE__*/React.createElement("span", {
      style: {
        marginLeft: 'auto',
        fontSize: 'var(--fs-body-sm)',
        color: 'var(--ink-500)'
      }
    }, "08:30"))
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '2px 14px 12px'
    }
  }, /*#__PURE__*/React.createElement(KeyValueList, {
    variant: "rows",
    items: [{
      label: 'Vehicle',
      value: 'SLK0004A',
      strong: false
    }, {
      label: 'Current Driver',
      value: 'Benjamin Loo',
      strong: false
    }, {
      label: 'Speed',
      value: '45km/h',
      strong: false
    }, {
      label: 'Current Trip',
      value: /*#__PURE__*/React.createElement("a", {
        href: "#trip"
      }, "Google Shuttle | WEN | Google"),
      strong: false
    }, {
      label: 'Timestamp',
      value: '22/01/2024 10:50:32',
      strong: false
    }, {
      label: 'Device',
      value: 'Google Pixel 7',
      strong: false
    }, {
      label: 'GPS Signal',
      value: /*#__PURE__*/React.createElement("span", {
        style: {
          color: 'var(--teal-500)'
        }
      }, "Fair"),
      strong: false
    }, {
      label: 'Battery Level',
      value: '87%',
      strong: false
    }]
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      marginTop: 12
    }
  }, /*#__PURE__*/React.createElement(Switch, {
    checked: trace,
    onChange: setTrace,
    label: 'Trace SLK0004A'
  }), /*#__PURE__*/React.createElement(IconButton, {
    icon: "close",
    size: 28,
    label: "Close",
    onClick: () => setPopover(false),
    style: {
      marginLeft: 'auto'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      marginTop: 10,
      fontSize: 'var(--fs-body-sm)'
    }
  }, /*#__PURE__*/React.createElement("a", {
    href: "#share"
  }, "Check Location Sharing Status"), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 4,
      color: 'var(--ink-500)'
    }
  }, "Enabled ", /*#__PURE__*/React.createElement(Icon, {
    name: "location_on",
    size: 16,
    color: "var(--green-600)"
  })))))) : null), /*#__PURE__*/React.createElement("aside", {
    style: {
      width: 264,
      flex: '0 0 auto',
      background: 'var(--surface-panel-dark)',
      display: 'flex',
      flexDirection: 'column',
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      padding: '10px 14px'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-label)',
      fontWeight: 700,
      letterSpacing: 'var(--ls-wide)',
      color: 'var(--white)'
    }
  }, "MAP"), /*#__PURE__*/React.createElement("span", {
    style: {
      marginLeft: 'auto',
      display: 'inline-flex',
      alignItems: 'center',
      gap: 4,
      fontSize: 'var(--fs-body-sm)',
      color: 'var(--white)',
      cursor: 'pointer'
    }
  }, "Filter ", /*#__PURE__*/React.createElement(Icon, {
    name: "layers",
    size: 18,
    color: "var(--white)"
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 26,
      height: 26,
      borderRadius: 'var(--radius-sm)',
      border: '1px solid rgba(255,255,255,.3)',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "expand_less",
    size: 18,
    color: "var(--white)"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '0 8px 10px'
    }
  }, /*#__PURE__*/React.createElement(StatusSegments, {
    activeId: filter,
    onSelect: setFilter,
    segments: [{
      id: 'ontrip',
      label: 'On Trip',
      count: 6,
      color: 'var(--orange-500)'
    }, {
      id: 'available',
      label: 'Available',
      count: 1,
      color: 'var(--teal-600)'
    }, {
      id: 'offline',
      label: 'Offline',
      count: 1,
      color: 'var(--ink-400)'
    }]
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto'
    }
  }, rows.map((v, i) => /*#__PURE__*/React.createElement(LivePanelRow, {
    key: i,
    v: v
  })))));
}
Object.assign(window, {
  LiveView
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/fleet_console/LiveView.jsx", error: String((e && e.message) || e) }); }

// ui_kits/fleet_console/Reports.jsx
try { (() => {
const {
  Select,
  Button,
  IconButton,
  Card,
  StatCard,
  Tabs,
  DataTable,
  MetaPill,
  Icon
} = window.ConvoyDesignSystem_cacf45;
function CvRiderChart({
  series,
  width = 1000,
  height = 200
}) {
  const padL = 20,
    padR = 20,
    padT = 44,
    padB = 30;
  const w = width - padL - padR,
    h = height - padT - padB;
  const max = Math.max(...series.map(s => s[1])),
    min = Math.min(...series.map(s => s[1]));
  const span = max - min || 1;
  const pts = series.map((s, i) => [padL + i / (series.length - 1) * w, padT + h - (s[1] - min) / span * h]);
  return /*#__PURE__*/React.createElement("svg", {
    viewBox: '0 0 ' + width + ' ' + height,
    preserveAspectRatio: "none",
    style: {
      display: 'block',
      width: '100%',
      height: height
    }
  }, /*#__PURE__*/React.createElement("polyline", {
    points: pts.map(p => p[0].toFixed(1) + ',' + p[1].toFixed(1)).join(' '),
    fill: "none",
    stroke: "var(--teal-600)",
    strokeWidth: "2"
  }), pts.map((p, i) => {
    const last = i === series.length - 1;
    return /*#__PURE__*/React.createElement("g", {
      key: i
    }, /*#__PURE__*/React.createElement("circle", {
      cx: p[0],
      cy: p[1],
      r: "4.5",
      fill: last ? 'var(--teal-800)' : 'var(--white)',
      stroke: "var(--teal-600)",
      strokeWidth: "2"
    }), /*#__PURE__*/React.createElement("rect", {
      x: p[0] - 21,
      y: p[1] - 34,
      width: "42",
      height: "24",
      rx: "5",
      fill: last ? 'var(--teal-600)' : 'var(--white)',
      stroke: last ? 'var(--teal-600)' : 'var(--ink-100)'
    }), /*#__PURE__*/React.createElement("text", {
      x: p[0],
      y: p[1] - 17,
      textAnchor: "middle",
      fontSize: "12",
      fontWeight: "700",
      fontFamily: "var(--font-sans)",
      fill: last ? 'var(--white)' : 'var(--ink-800)'
    }, series[i][1]), /*#__PURE__*/React.createElement("text", {
      x: p[0],
      y: height - 10,
      textAnchor: "middle",
      fontSize: "11",
      fontFamily: "var(--font-sans)",
      fill: "var(--ink-500)"
    }, series[i][0]));
  }));
}
function Reports() {
  const d = window.CVData;
  const [tab, setTab] = React.useState('summary');
  const [applied, setApplied] = React.useState(true);
  const tripRows = [{
    g: {
      value: 'Most Utilised',
      bold: true,
      rowSpan: 2
    },
    t: {
      value: 'Shuttle Trip for direction “To WEN”',
      bold: true
    },
    time: '08:05',
    u: '61.21%',
    r: '147',
    a: '8.65',
    m: '11'
  }, {
    g: {
      hidden: true
    },
    t: {
      value: 'Shuttle Trip for direction “To Lakeside”',
      bold: true
    },
    time: '17:35',
    u: '51.84%',
    r: '118',
    a: '6.94',
    m: '12'
  }, {
    g: {
      value: 'Least Utilised',
      bold: true,
      rowSpan: 2
    },
    t: {
      value: 'Shuttle Trip for direction “To WEN”',
      bold: true
    },
    time: '09:05',
    u: '3.34%',
    r: '7',
    a: '0.41',
    m: '2'
  }, {
    g: {
      hidden: true
    },
    t: {
      value: 'Shuttle Trip for direction “To Lakeside”',
      bold: true
    },
    time: '16:30',
    u: '10.03%',
    r: '21',
    a: '1.24',
    m: '4'
  }];
  const pointRows = [{
    g: {
      value: 'Most Popular',
      bold: true,
      rowSpan: 2
    },
    t: {
      value: 'Shuttle Point for “To WEN”',
      bold: true
    },
    p: 'Point 3: Jurong West Ave',
    u: '60.23%',
    r: '53',
    a: '10.60',
    m: '45'
  }, {
    g: {
      hidden: true
    },
    t: {
      value: 'Shuttle Point for “To Lakeside”',
      bold: true
    },
    p: 'Point 2: Jurong West Central',
    u: '52.55%',
    r: '72',
    a: '14.40',
    m: '50'
  }, {
    g: {
      value: 'Least Popular',
      bold: true,
      rowSpan: 2
    },
    t: {
      value: 'Shuttle Point for “To WEN”',
      bold: true
    },
    p: 'Point 1: Boon Lay Ave',
    u: '13.64%',
    r: '12',
    a: '2.40',
    m: '4'
  }, {
    g: {
      hidden: true
    },
    t: {
      value: 'Shuttle Point for “To Lakeside”',
      bold: true
    },
    p: 'Point 1: Boon Lay Ave',
    u: '8.76%',
    r: '12',
    a: '2.40',
    m: '4'
  }];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minHeight: 0,
      overflow: 'auto',
      padding: 'var(--page-gutter)'
    }
  }, /*#__PURE__*/React.createElement("h1", {
    style: {
      margin: '0 0 16px',
      fontSize: 'var(--fs-h3)',
      fontWeight: 700,
      letterSpacing: 'var(--ls-wide)'
    }
  }, "REPORTS"), /*#__PURE__*/React.createElement(Card, {
    padding: 20,
    style: {
      marginBottom: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-end',
      gap: 20,
      flexWrap: 'wrap'
    }
  }, /*#__PURE__*/React.createElement(Select, {
    label: "Client",
    options: ['Google Asia Pte Ltd', 'Grab Singapore'],
    style: {
      flex: 1
    }
  }), /*#__PURE__*/React.createElement(Select, {
    label: "Project",
    options: ['Google Shuttle', 'Google Limo'],
    style: {
      flex: 1
    }
  }), /*#__PURE__*/React.createElement(Select, {
    label: "Route Name",
    options: ['TID260921 Google Shuttle WEN'],
    style: {
      flex: 1
    }
  }), /*#__PURE__*/React.createElement(Select, {
    label: "Period",
    options: ['March, 2023', 'April, 2023'],
    style: {
      flex: 1
    }
  }), /*#__PURE__*/React.createElement(IconButton, {
    icon: "autorenew",
    variant: "outline",
    size: 44,
    color: "var(--teal-800)",
    label: "Refresh",
    style: {
      border: '2px solid var(--teal-800)'
    }
  }), /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    onClick: () => setApplied(!applied)
  }, "Apply"))), /*#__PURE__*/React.createElement(Card, {
    padding: 20
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'minmax(0,320px) minmax(0,1fr)',
      gap: 28
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-start',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("h2", {
    style: {
      margin: 0,
      fontSize: 'var(--fs-h2)',
      fontWeight: 700
    }
  }, "Google Shuttle WEN"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-body)',
      color: 'var(--ink-500)',
      marginTop: 4
    }
  }, "TID260921")), /*#__PURE__*/React.createElement(Button, {
    variant: "tertiary",
    size: "sm",
    icon: "download"
  }, "Export")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 8,
      marginTop: 22,
      alignItems: 'flex-start'
    }
  }, /*#__PURE__*/React.createElement(MetaPill, {
    label: "Period",
    value: "01/03/2023 - 31/03/2023"
  }), /*#__PURE__*/React.createElement(MetaPill, {
    label: "Organisation",
    value: "Google Asia Pte Ltd"
  }), /*#__PURE__*/React.createElement(MetaPill, {
    label: "Project",
    value: "Google Shuttle"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 16,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'repeat(3, minmax(0,1fr))',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement(StatCard, {
    label: "Seats",
    value: "13",
    secondaryLabel: "Number of days in Period",
    secondaryValue: "23"
  }), /*#__PURE__*/React.createElement(StatCard, {
    label: "Overall Utilisation in Period",
    value: "21.49%",
    trend: [21, 38, 26, 30, 24, 41, 55, 30, 22, 22]
  }), /*#__PURE__*/React.createElement(StatCard, {
    label: "Average On Time Performance",
    value: "98.30%",
    trend: [62, 44, 30, 26, 30, 28, 30, 66, 40, 48]
  })), /*#__PURE__*/React.createElement(Card, {
    title: null,
    padding: 16,
    style: {
      boxShadow: 'none'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-body)',
      marginBottom: 4
    }
  }, "Average Daily Rider"), /*#__PURE__*/React.createElement(CvRiderChart, {
    series: d.dailyRider,
    width: 760,
    height: 210
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 24
    }
  }, /*#__PURE__*/React.createElement(Tabs, {
    value: tab,
    onChange: setTab,
    tabs: [{
      value: 'summary',
      label: 'Overall Route Report Summary'
    }, {
      value: 'ridership',
      label: 'Route Ridership and Utilisation Report Details'
    }, {
      value: 'ontime',
      label: 'On Time Report Details'
    }]
  }), tab === 'summary' ? /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 32,
      marginTop: 24
    }
  }, /*#__PURE__*/React.createElement(DataTable, {
    columns: [{
      key: 'g',
      label: ''
    }, {
      key: 't',
      label: 'Shuttle Trip'
    }, {
      key: 'time',
      label: ''
    }, {
      key: 'u',
      label: 'Utilisation'
    }, {
      key: 'r',
      label: 'Total Riders'
    }, {
      key: 'a',
      label: 'Average'
    }, {
      key: 'm',
      label: 'Max'
    }],
    rows: tripRows
  }), /*#__PURE__*/React.createElement(DataTable, {
    columns: [{
      key: 'g',
      label: ''
    }, {
      key: 't',
      label: 'Shuttle Point'
    }, {
      key: 'p',
      label: 'Popularity'
    }, {
      key: 'u',
      label: ''
    }, {
      key: 'r',
      label: 'Total Riders'
    }, {
      key: 'a',
      label: 'Average'
    }, {
      key: 'm',
      label: 'Max'
    }],
    rows: pointRows
  })) : /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '48px 0',
      textAlign: 'center',
      color: 'var(--text-muted)',
      fontSize: 'var(--fs-body)'
    }
  }, "No data for this report in the source material."))));
}
Object.assign(window, {
  Reports,
  CvRiderChart
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/fleet_console/Reports.jsx", error: String((e && e.message) || e) }); }

// ui_kits/fleet_console/Scheduler.jsx
try { (() => {
const {
  SegmentedControl,
  SearchInput,
  Button,
  IconButton,
  Checkbox,
  VehicleRow,
  SchedulerBlock,
  Icon
} = window.ConvoyDesignSystem_cacf45;
const CV_HOURS = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
const CV_COL = 106;
const CV_ROW_H = 116;
const cvPos = (start, end) => ({
  left: (start - 7) * CV_COL + 3,
  width: (end - start) * CV_COL - 8
});
function Scheduler() {
  const [mode, setMode] = React.useState('Day');
  const [external, setExternal] = React.useState(false);
  const [openBlock, setOpenBlock] = React.useState(null);
  const d = window.CVData;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minHeight: 0,
      overflow: 'auto',
      padding: 'var(--page-gutter)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'var(--surface-card)',
      border: '1px solid var(--ink-075)',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      borderBottom: '1px solid var(--divider)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 300,
      flex: '0 0 auto',
      padding: '14px 16px',
      borderRight: '1px solid var(--divider)'
    }
  }, /*#__PURE__*/React.createElement(SearchInput, {
    variant: "filled",
    placeholder: "Search Vehicle",
    width: "100%"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 14,
      padding: '14px 16px',
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement(SegmentedControl, {
    options: ['Day', 'Week'],
    value: mode,
    onChange: setMode
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 6
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    icon: "chevron_left",
    label: "Previous day"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body-lg)',
      fontWeight: 700,
      minWidth: 210,
      textAlign: 'center'
    }
  }, "Monday 20/12/2023"), /*#__PURE__*/React.createElement(IconButton, {
    icon: "chevron_right",
    label: "Next day"
  })), /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    size: "sm"
  }, "Today"), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      gap: 4,
      marginLeft: 12,
      paddingLeft: 16,
      borderLeft: '1px solid var(--divider)'
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    icon: "zoom_out",
    label: "Zoom out"
  }), /*#__PURE__*/React.createElement(IconButton, {
    icon: "zoom_in",
    label: "Zoom in"
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      paddingLeft: 16,
      borderLeft: '1px solid var(--divider)'
    }
  }, /*#__PURE__*/React.createElement(Checkbox, {
    label: "Show external vehicles",
    checked: external,
    onChange: () => setExternal(!external)
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      marginLeft: 'auto',
      display: 'inline-flex',
      alignItems: 'center',
      gap: 8,
      paddingLeft: 16,
      borderLeft: '1px solid var(--divider)',
      fontSize: 'var(--fs-body)',
      fontWeight: 700,
      color: 'var(--teal-800)',
      cursor: 'pointer'
    }
  }, "Scheduler Legends ", /*#__PURE__*/React.createElement(Icon, {
    name: "info",
    size: 20,
    fill: false,
    color: "var(--teal-800)"
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 300,
      flex: '0 0 auto',
      borderRight: '1px solid var(--divider)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      height: 68,
      padding: '0 16px',
      borderBottom: '1px solid var(--divider)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      lineHeight: 1.15
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontSize: 'var(--fs-h4)',
      fontWeight: 700
    }
  }, d.vehicles.length * 4 - 2), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontSize: 'var(--fs-body-sm)',
      color: 'var(--ink-500)'
    }
  }, "Vehicles")), /*#__PURE__*/React.createElement("span", {
    style: {
      marginLeft: 'auto',
      display: 'inline-flex',
      gap: 6
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    icon: "swap_vert",
    variant: "outline",
    label: "Sort"
  }), /*#__PURE__*/React.createElement(IconButton, {
    icon: "filter_alt",
    variant: "outline",
    label: "Filter"
  }))), d.vehicles.map(v => /*#__PURE__*/React.createElement("div", {
    key: v.plate,
    style: {
      height: CV_ROW_H,
      borderBottom: '1px solid var(--divider)',
      display: 'flex',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(VehicleRow, {
    plate: v.plate,
    driver: v.driver,
    seats: v.seats,
    driverAvatar: '../../assets/' + v.avatar + '.png',
    vehicleThumb: '../../assets/' + v.thumb + '.png',
    style: {
      width: '100%'
    }
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0,
      overflowX: 'auto'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: CV_HOURS.length * CV_COL,
      position: 'relative'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: 34,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontSize: 'var(--fs-body)',
      fontWeight: 700,
      borderBottom: '1px solid var(--divider)'
    }
  }, "Monday 20/12/2023"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      height: 34,
      borderBottom: '1px solid var(--divider)'
    }
  }, CV_HOURS.map(h => /*#__PURE__*/React.createElement("div", {
    key: h,
    style: {
      width: CV_COL,
      flex: '0 0 auto',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontSize: 'var(--fs-body-sm)',
      color: 'var(--ink-800)',
      borderRight: '1px solid var(--divider)'
    }
  }, String(h).padStart(2, '0'), ":00"))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative'
    }
  }, d.vehicles.map((v, ri) => /*#__PURE__*/React.createElement("div", {
    key: v.plate,
    style: {
      height: CV_ROW_H,
      borderBottom: '1px solid var(--divider)',
      display: 'flex',
      position: 'relative'
    }
  }, CV_HOURS.map(h => /*#__PURE__*/React.createElement("div", {
    key: h,
    style: {
      width: CV_COL,
      flex: '0 0 auto',
      borderRight: '1px solid var(--divider)'
    }
  })), d.blocks.filter(b => b[0] === ri).map((b, bi) => /*#__PURE__*/React.createElement("div", {
    key: bi,
    style: {
      position: 'absolute',
      top: 6,
      height: CV_ROW_H - 16,
      ...cvPos(b[1], b[2])
    }
  }, /*#__PURE__*/React.createElement(SchedulerBlock, {
    tone: b[3],
    cancelled: b[5],
    client: "Google",
    site: "WEN",
    service: "Shuttle Bus",
    seats: 22,
    driver: "Kevin Lee",
    route: "Shuttle",
    vehicleType: 'Bus  29s  ' + b[4],
    onClick: () => setOpenBlock(ri + '-' + bi),
    style: {
      height: '100%'
    }
  }))))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 0,
      bottom: 0,
      left: 1.9 * CV_COL,
      width: 2,
      background: 'var(--red-500)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: -4,
      left: -3,
      width: 8,
      height: 8,
      borderRadius: '50%',
      background: 'var(--red-500)'
    }
  })))))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      borderTop: '1px solid var(--divider)',
      background: 'var(--surface-page)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 300,
      flex: '0 0 auto',
      padding: '16px',
      borderRight: '1px solid var(--divider)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body)'
    }
  }, "Unassigned Trips"), /*#__PURE__*/React.createElement(IconButton, {
    icon: "chevron_left",
    variant: "outline",
    size: 28,
    label: "Scroll left"
  }), /*#__PURE__*/React.createElement(IconButton, {
    icon: "chevron_right",
    variant: "outline",
    size: 28,
    label: "Scroll right"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-h4)',
      fontWeight: 700,
      marginTop: 6
    }
  }, d.unassigned.length)), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0,
      overflow: 'hidden',
      position: 'relative',
      height: 176
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: CV_HOURS.length * CV_COL,
      position: 'relative',
      height: '100%'
    }
  }, d.unassigned.map((u, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      position: 'absolute',
      top: 8 + i % 2 * 84,
      height: 76,
      ...cvPos(u[0], u[1])
    }
  }, /*#__PURE__*/React.createElement(SchedulerBlock, {
    tone: "unassigned",
    client: "Google",
    site: "WEN",
    service: "Shuttle Bus",
    seats: 22,
    driver: "Kevin Lee",
    route: "Shuttle",
    vehicleType: "Bus  29s  08:00 - 09:30",
    style: {
      height: '100%'
    }
  }))))))), openBlock ? /*#__PURE__*/React.createElement("div", {
    onClick: () => setOpenBlock(null),
    style: {
      position: 'fixed',
      inset: 0,
      background: 'rgba(22,22,22,.28)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 60
    }
  }, /*#__PURE__*/React.createElement("div", {
    onClick: e => e.stopPropagation(),
    style: {
      width: 360,
      background: 'var(--white)',
      borderRadius: 'var(--radius-xl)',
      boxShadow: 'var(--shadow-popover)',
      padding: 20
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-body-lg)',
      fontWeight: 700
    }
  }, "Google | WEN | Shuttle Bus"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 6,
      marginTop: 12,
      color: 'var(--teal-600)',
      fontWeight: 700
    }
  }, "#0042434-1 ", /*#__PURE__*/React.createElement(Icon, {
    name: "chevron_right",
    size: 18
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      marginTop: 14,
      fontSize: 'var(--fs-body)'
    }
  }, "22 ", /*#__PURE__*/React.createElement(Icon, {
    name: "accessible",
    size: 16,
    color: "var(--ink-600)"
  }), " Kevin Lee"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      marginTop: 10,
      fontSize: 'var(--fs-body)'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "repeat",
    size: 18,
    color: "var(--teal-600)"
  }), " Shuttle"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      marginTop: 10,
      fontSize: 'var(--fs-body)'
    }
  }, /*#__PURE__*/React.createElement("span", null, "Bus"), /*#__PURE__*/React.createElement("span", null, "29s"), /*#__PURE__*/React.createElement("span", null, "13:30 - 15:30")), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 16,
      display: 'flex',
      flexDirection: 'column',
      gap: 10
    }
  }, [['arrow_upward', 'Boon Lay Ave', 'var(--orange-500)'], ['swap_vert', 'Jurong West Central', 'var(--teal-600)'], ['arrow_downward', 'Jurong West Ave', 'var(--green-600)']].map(([ic, t, c]) => /*#__PURE__*/React.createElement("span", {
    key: t,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 10,
      fontSize: 'var(--fs-body)'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: ic,
    size: 18,
    color: c,
    weight: 700
  }), t))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 20,
      display: 'flex',
      justifyContent: 'flex-end'
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "tertiary",
    size: "sm",
    onClick: () => setOpenBlock(null)
  }, "Close")))) : null);
}
Object.assign(window, {
  Scheduler
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/fleet_console/Scheduler.jsx", error: String((e && e.message) || e) }); }

// ui_kits/fleet_console/TripHistory.jsx
try { (() => {
const {
  SearchInput,
  ViewToggle,
  FilterChip,
  Button,
  Card,
  TripListCard,
  Timeline,
  LogList,
  KeyValueList,
  SpeedLegend,
  StatusBadge,
  Avatar,
  Icon,
  IconButton,
  MapOverlayCard,
  Select
} = window.ConvoyDesignSystem_cacf45;
function CvLineChart({
  series,
  width = 700,
  height = 210,
  yMax = 120,
  color = 'var(--teal-600)'
}) {
  const padL = 44,
    padB = 28,
    padT = 12,
    padR = 12;
  const w = width - padL - padR,
    h = height - padB - padT;
  const pts = series.map((s, i) => [padL + i / (series.length - 1) * w, padT + h - s[1] / yMax * h]);
  const path = pts.map(p => p[0].toFixed(1) + ',' + p[1].toFixed(1)).join(' ');
  return /*#__PURE__*/React.createElement("svg", {
    viewBox: '0 0 ' + width + ' ' + height,
    preserveAspectRatio: "none",
    style: {
      display: 'block',
      width: '100%',
      height: height
    }
  }, [0, 20, 40, 60, 80, 100, 120].map(t => {
    const y = padT + h - t / yMax * h;
    return /*#__PURE__*/React.createElement("g", {
      key: t
    }, /*#__PURE__*/React.createElement("line", {
      x1: padL,
      x2: width - padR,
      y1: y,
      y2: y,
      stroke: "var(--ink-050)",
      strokeWidth: "1"
    }), /*#__PURE__*/React.createElement("text", {
      x: padL - 10,
      y: y + 4,
      textAnchor: "end",
      fontSize: "11",
      fill: "var(--ink-400)",
      fontFamily: "var(--font-sans)"
    }, t));
  }), /*#__PURE__*/React.createElement("polyline", {
    points: path,
    fill: "none",
    stroke: color,
    strokeWidth: "2",
    strokeLinejoin: "round"
  }), pts.map((p, i) => /*#__PURE__*/React.createElement("circle", {
    key: i,
    cx: p[0],
    cy: p[1],
    r: "4",
    fill: color
  })), series.map((s, i) => /*#__PURE__*/React.createElement("text", {
    key: i,
    x: pts[i][0],
    y: height - 8,
    textAnchor: "middle",
    fontSize: "11",
    fill: "var(--ink-400)",
    fontFamily: "var(--font-sans)"
  }, s[0])));
}
function TripHistory() {
  const d = window.CVData;
  const [selected, setSelected] = React.useState(0);
  const [view, setView] = React.useState('split');
  const [filters, setFilters] = React.useState({
    date: true,
    client: true
  });
  const toggle = k => setFilters({
    ...filters,
    [k]: !filters[k]
  });
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minHeight: 0,
      overflow: 'auto',
      padding: 'var(--page-gutter)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 16,
      marginBottom: 16
    }
  }, /*#__PURE__*/React.createElement("h1", {
    style: {
      margin: 0,
      fontSize: 'var(--fs-h3)',
      fontWeight: 700,
      letterSpacing: 'var(--ls-wide)'
    }
  }, "TRIP HISTORY"), /*#__PURE__*/React.createElement("span", {
    style: {
      marginLeft: 'auto',
      display: 'inline-flex',
      alignItems: 'center',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(SearchInput, {
    placeholder: "Search",
    width: 260
  }), /*#__PURE__*/React.createElement(ViewToggle, {
    value: view,
    onChange: setView,
    options: [{
      value: 'split',
      icon: 'view_agenda',
      label: 'Split view'
    }, {
      value: 'table',
      icon: 'list_alt',
      label: 'Table view'
    }]
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      marginBottom: 16,
      flexWrap: 'wrap'
    }
  }, /*#__PURE__*/React.createElement(FilterChip, {
    icon: "calendar_month",
    active: filters.date,
    onClick: () => toggle('date')
  }, "May 15 - May 30"), /*#__PURE__*/React.createElement(FilterChip, {
    icon: "work",
    active: filters.client,
    count: filters.client ? 2 : undefined,
    onClick: () => toggle('client')
  }, "Client"), /*#__PURE__*/React.createElement(FilterChip, {
    icon: "directions_bus"
  }, "Vehicle"), /*#__PURE__*/React.createElement(FilterChip, {
    icon: "info"
  }, "Trip Status"), /*#__PURE__*/React.createElement(FilterChip, {
    icon: "schedule"
  }, "On-Time Status"), /*#__PURE__*/React.createElement("span", {
    style: {
      marginLeft: 'auto'
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "ghost",
    size: "sm",
    icon: "autorenew",
    iconPosition: "left",
    onClick: () => setFilters({
      date: false,
      client: false
    }),
    style: {
      color: 'var(--ink-800)'
    }
  }, "Reset Filters"))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '292px minmax(0,1fr)',
      gap: 16,
      alignItems: 'start'
    }
  }, /*#__PURE__*/React.createElement(Card, {
    padding: 0
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      padding: '14px 18px',
      borderBottom: '1px solid var(--divider)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body)'
    }
  }, "Sort by:"), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 4,
      fontSize: 'var(--fs-body)',
      fontWeight: 700,
      color: 'var(--teal-800)',
      cursor: 'pointer'
    }
  }, "Trip ID ", /*#__PURE__*/React.createElement(Icon, {
    name: "expand_more",
    size: 20,
    color: "var(--teal-800)"
  }))), d.trips.map((t, i) => /*#__PURE__*/React.createElement(TripListCard, {
    key: i,
    tripId: t.id,
    status: t.status,
    statusTone: t.status === 'Cancelled' ? 'danger' : 'success',
    client: t.client,
    site: t.site,
    date: t.date,
    time: t.time,
    vehicle: t.vehicle,
    onTime: t.onTime,
    vehicleName: "White Toyota Hiace",
    vehicleId: "VID9922222",
    vehicleThumb: "../../assets/photo-vehicle-van.png",
    selected: i === selected,
    onClick: () => setSelected(i)
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 16,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement(Card, {
    padding: 0
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      height: 360,
      background: 'url(../../assets/map-route-replay.png) center / cover'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      right: 16,
      top: 16
    }
  }, /*#__PURE__*/React.createElement(MapOverlayCard, {
    radius: "var(--radius-md)",
    padding: 0
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '4px 14px 10px'
    }
  }, /*#__PURE__*/React.createElement(KeyValueList, {
    variant: "rows",
    items: [{
      label: 'Time',
      value: '07:10',
      strong: false
    }, {
      label: 'Vehicle',
      value: 'SLK0004A',
      strong: false
    }, {
      label: 'Driver',
      value: 'Benjamin Loo',
      strong: false
    }, {
      label: 'Speed',
      value: '62km/h',
      strong: false
    }, {
      label: 'Passenger Count',
      value: '22',
      strong: false
    }, {
      label: 'Lat Long',
      value: /*#__PURE__*/React.createElement("a", {
        href: "#latlong"
      }, "1.4543545, 1.6745767"),
      strong: false
    }]
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 16,
      bottom: 16,
      width: 330
    }
  }, /*#__PURE__*/React.createElement(SpeedLegend, null)), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      right: 16,
      bottom: 16
    }
  }, /*#__PURE__*/React.createElement(MapOverlayCard, {
    radius: "var(--radius-xl)"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 14,
      padding: '12px 16px'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body-lg)',
      fontWeight: 700
    }
  }, "TID260921"), /*#__PURE__*/React.createElement(Icon, {
    name: "repeat",
    size: 20,
    color: "var(--teal-600)"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-body)'
    }
  }, "Monday 22/05/2025"), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 6,
      fontSize: 'var(--fs-body)',
      fontWeight: 700
    }
  }, "22 ", /*#__PURE__*/React.createElement(Icon, {
    name: "accessible",
    size: 18,
    color: "var(--ink-600)"
  })), /*#__PURE__*/React.createElement(StatusBadge, {
    tone: "success"
  }, "Completed"))))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '18px 20px',
      borderRight: '1px solid var(--divider)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-label)',
      fontWeight: 700,
      marginBottom: 14
    }
  }, "Vehicle"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: "../../assets/photo-vehicle-hiace.png",
    alt: "",
    style: {
      width: 46,
      height: 46,
      borderRadius: '50%',
      objectFit: 'cover'
    }
  }), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-body-lg)',
      fontWeight: 700
    }
  }, "SBA 1234A"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-body)'
    }
  }, "White Toyota HiAce High Roof"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-body)',
      color: 'var(--ink-500)',
      marginTop: 2
    }
  }, "#VID9922222 \xA0|\xA0 29 seats")))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '18px 20px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-label)',
      fontWeight: 700,
      marginBottom: 14
    }
  }, "Crew Information"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14,
      alignItems: 'flex-start'
    }
  }, /*#__PURE__*/React.createElement(Avatar, {
    src: "../../assets/avatar-hu-jia-jie.png",
    name: "Hu Jia Jie",
    size: 46
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-body-lg)',
      fontWeight: 700
    }
  }, "Hu Jia Jie"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-body)'
    }
  }, "+65 9932 9922")), /*#__PURE__*/React.createElement(StatusBadge, {
    tone: "info",
    style: {
      border: '1px solid var(--teal-200)',
      background: 'var(--white)',
      color: 'var(--teal-600)'
    }
  }, "Driver")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'flex-end',
      marginTop: 12
    }
  }, /*#__PURE__*/React.createElement("a", {
    href: "#crew",
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 6,
      fontWeight: 600
    }
  }, "View All Crew Members ", /*#__PURE__*/React.createElement(Icon, {
    name: "arrow_forward",
    size: 18
  })))))), /*#__PURE__*/React.createElement(Card, {
    title: "Trip Schedule Record",
    actions: /*#__PURE__*/React.createElement(IconButton, {
      icon: "edit",
      label: "Edit record"
    })
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-body)',
      marginBottom: 18
    }
  }, "Distance Traveled: ", /*#__PURE__*/React.createElement("b", null, "12 km")), /*#__PURE__*/React.createElement(Timeline, {
    stops: [{
      kind: 'start',
      time: '06:35',
      title: 'On the way'
    }, {
      index: 1,
      time: '07:00',
      title: '234 Boon Lay Ave',
      coords: '1.4958495, 1.12323434',
      direction: 'up',
      lines: ['Boon Lay Ave Shopping Centre pickup point', 'Pickup point of Boon Lay Shopping Centre', {
        label: 'Arrival',
        value: '06:55'
      }, {
        label: 'Departure',
        value: '07:01'
      }, {
        label: 'Boarded',
        value: '5'
      }, {
        label: 'Passenger Count',
        value: '5'
      }]
    }, {
      index: 2,
      time: '07:20',
      title: '445A Jurong West Central',
      coords: '1.4958499, 1.12323439',
      direction: 'up',
      lines: ['Jurong West Central', 'In front of 7eleven', {
        label: 'Skipped',
        value: '07:05'
      }, {
        label: 'Passenger Count',
        value: '5'
      }]
    }, {
      index: 3,
      time: '07:40',
      title: '123 Jurong West Ave',
      coords: '1.4958499, 1.12323467',
      direction: 'down',
      lines: ['Jurong West Ave', 'Next to Jurong West public bus stop', {
        label: 'Arrival',
        value: '07:35'
      }, {
        label: 'Alighted',
        value: '5'
      }, {
        label: 'Passenger Count',
        value: '0'
      }]
    }]
  })), /*#__PURE__*/React.createElement(Card, {
    title: "Speed History"
  }, /*#__PURE__*/React.createElement(CvLineChart, {
    series: d.speedHistory,
    width: 780,
    height: 210
  })), /*#__PURE__*/React.createElement(Card, {
    title: "Trip Information"
  }, /*#__PURE__*/React.createElement(KeyValueList, {
    columns: 2,
    items: [{
      label: 'Route Name',
      value: 'WEN Oneway'
    }, {
      label: 'Client',
      value: 'Google Pte Ltd'
    }, {
      label: 'Date',
      value: '22/02/2023'
    }, {
      label: 'Capacity Required',
      value: '40'
    }, {
      label: 'Site',
      value: 'WEN'
    }, {
      label: 'Label',
      value: 'WEN'
    }, {
      label: 'Seat reservation required',
      value: '',
      badge: /*#__PURE__*/React.createElement(Icon, {
        name: "cancel",
        size: 17,
        color: "var(--red-500)"
      })
    }, {
      label: 'Approved rider required',
      value: '',
      badge: /*#__PURE__*/React.createElement(Icon, {
        name: "cancel",
        size: 17,
        color: "var(--red-500)"
      })
    }, {
      label: 'Passenger Count',
      value: '',
      badge: /*#__PURE__*/React.createElement(Icon, {
        name: "check_circle",
        size: 17,
        color: "var(--green-600)"
      })
    }, {
      label: 'Recurring',
      value: '',
      badge: /*#__PURE__*/React.createElement(Icon, {
        name: "check_circle",
        size: 17,
        color: "var(--green-600)"
      })
    }, {
      label: 'Notes to Driver',
      value: 'N/A'
    }, {
      label: 'Internal Notes',
      value: 'This is internal note'
    }, {
      label: 'Booking ID',
      value: 'BID9129034920'
    }, {
      label: "Driver's Feedback",
      value: 'Trip was completed successfully'
    }]
  })), /*#__PURE__*/React.createElement(Card, {
    title: "Point of Contact"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-label)',
      fontWeight: 700,
      marginBottom: 12
    }
  }, "Requestor"), /*#__PURE__*/React.createElement(KeyValueList, {
    columns: 3,
    items: [{
      label: 'Name',
      value: 'Alex Hwang'
    }, {
      label: 'Email',
      value: 'alex.h@gmail.com'
    }, {
      label: 'Mobile Number',
      value: '678339382'
    }]
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--fs-label)',
      fontWeight: 700,
      margin: '22px 0 12px'
    }
  }, "Guest"), /*#__PURE__*/React.createElement(KeyValueList, {
    columns: 3,
    items: [{
      label: 'Name',
      value: 'Benji Tran'
    }, {
      label: 'Email',
      value: 'benji.t@gmail.com'
    }, {
      label: 'Mobile Number',
      value: '678339468'
    }]
  })), /*#__PURE__*/React.createElement(Card, {
    title: "Trip Log"
  }, /*#__PURE__*/React.createElement(LogList, {
    entries: d.tripLog
  })))));
}
Object.assign(window, {
  TripHistory,
  CvLineChart
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/fleet_console/TripHistory.jsx", error: String((e && e.message) || e) }); }

// ui_kits/fleet_console/data.js
try { (() => {
window.CVData = {
  user: {
    name: 'Alex Chan',
    email: 'alex@simpledrive.sg'
  },
  tenant: 'SIMPLEDRIVE',
  rail: [{
    id: 'dashboard',
    icon: 'dashboard',
    label: 'Dashboard'
  }, {
    id: 'trips',
    icon: 'assignment',
    label: 'Trips & Bookings'
  }, {
    id: 'monitoring',
    icon: 'desktop_windows',
    label: 'Monitoring'
  }, {
    id: 'fleet',
    icon: 'directions_bus',
    label: 'Fleet'
  }, {
    id: 'clients',
    icon: 'apartment',
    label: 'Clients & Sites'
  }, {
    id: 'training',
    icon: 'school',
    label: 'Training'
  }, {
    id: 'jobs',
    icon: 'work',
    label: 'Jobs'
  }, {
    id: 'reports',
    icon: 'insert_chart',
    label: 'Reports'
  }, {
    id: 'billing',
    icon: 'calculate',
    label: 'Billing'
  }, {
    id: 'compliance',
    icon: 'policy',
    label: 'Compliance'
  }, {
    id: 'alerts',
    icon: 'notification_important',
    label: 'Alerts'
  }],
  railFooter: [{
    id: 'settings',
    icon: 'settings',
    label: 'Settings'
  }, {
    id: 'menu',
    icon: 'menu',
    label: 'More'
  }],
  liveVehicles: [{
    badge: 'Arrived',
    tone: 'success',
    at: 'at Point 1',
    time: '08:30',
    plate: 'STU0019L',
    driver: 'Lin Yi Xi',
    seats: 29
  }, {
    badge: 'On the way',
    tone: 'warning',
    at: 'to Point 1',
    time: '08:30',
    plate: 'STU0019L',
    driver: 'Adha Bi Ali',
    seats: 16
  }, {
    badge: 'Offline',
    tone: 'neutral',
    at: '',
    time: '08:30',
    plate: 'SLK0004A',
    driver: 'Adha Bi Ali',
    seats: 16
  }, {
    badge: 'Arrived',
    tone: 'success',
    at: 'at Point 1',
    time: '08:30',
    plate: 'SJP0005H',
    driver: 'Benneth W.',
    seats: 49
  }, {
    badge: 'On the way',
    tone: 'warning',
    at: 'to Point 3',
    time: '08:30',
    plate: 'SJC0010A',
    driver: 'Hu Jia Jie',
    seats: 16
  }, {
    badge: 'On the way',
    tone: 'warning',
    at: 'to Last Point',
    time: '08:30',
    plate: 'SJA0007T',
    driver: 'Keith Lee',
    seats: 41
  }, {
    badge: 'Arrived',
    tone: 'success',
    at: 'at Last Point',
    time: '08:30',
    plate: 'SJA0007T',
    driver: 'Alex Huang',
    seats: 49
  }, {
    badge: 'Available',
    tone: 'info',
    at: '',
    time: '08:30',
    plate: 'SUV0008L',
    driver: 'Alex Huang',
    seats: 49
  }],
  vehicles: [{
    plate: 'SUV0008L',
    driver: 'Alex Huang',
    avatar: 'avatar-alex-huang',
    thumb: 'thumb-vehicle-suv',
    seats: 49
  }, {
    plate: 'SJA0007T',
    driver: 'Keith Lee',
    avatar: 'avatar-keith-lee',
    thumb: 'thumb-vehicle-bus-1',
    seats: 41
  }, {
    plate: 'SJC0010A',
    driver: 'Hu Jia Jie',
    avatar: 'avatar-hu-jia-jie',
    thumb: 'thumb-vehicle-minibus',
    seats: 16
  }, {
    plate: 'SJP0005H',
    driver: 'Benneth W.',
    avatar: 'avatar-benneth-w',
    thumb: 'thumb-vehicle-bus-2',
    seats: 49
  }, {
    plate: 'SLK0004A',
    driver: 'Adha Bin Ali',
    avatar: 'avatar-adha-bin-ali',
    thumb: 'thumb-vehicle-bus-3',
    seats: 16
  }, {
    plate: 'STU0019L',
    driver: 'Lin Yi Xi',
    avatar: 'avatar-lin-yi-xi',
    thumb: 'thumb-vehicle-bus-4',
    seats: 29
  }],
  // scheduler blocks: [rowIndex, startHour, endHour, tone, window, route, cancelled]
  blocks: [[0, 8, 9.5, 'confirmed', '08:00 - 09:30', 'Bedok - Woodlands'], [0, 10, 12, 'scheduled', '10:00 - 12:00', 'Woodlands - Bedok'], [0, 13.5, 15.5, 'scheduled', '13:30 - 15:30', 'Bedok - Woodlands'], [0, 15.5, 17, 'scheduled', '15:30 - 17:00', 'Woodlands - Bedok'], [1, 8, 9.5, 'confirmed', '08:00 - 09:30', 'Bedok - Woodlands'], [1, 10, 11.5, 'conflict', '08:00 - 09:30', 'Bedok - Woodlands'], [1, 16, 18, 'scheduled', '16:00 - 18:30', 'Bedok - Woodlands'], [2, 8, 9.5, 'confirmed', '08:00 - 09:30', 'Bedok - Woodlands'], [2, 10.5, 12, 'confirmed', '10:30 - 12:00', 'Woodlands - Bedok'], [2, 13.5, 15.5, 'scheduled', '13:30 - 15:30', 'Boon Lay Ave - Jurong West Ave'], [2, 16, 18, 'scheduled', '16:00 - 18:30', 'Woodlands - Bedok'], [3, 8.5, 10, 'scheduled', '08:00 - 09:30', 'Bedok - Woodlands'], [3, 10, 11.5, 'pending', '08:00 - 09:30', 'Bedok - Woodlands'], [3, 13.5, 15.5, 'scheduled', '13:35 - 15:30', 'Bedok - Woodlands'], [3, 16.5, 18.5, 'scheduled', '16:30 - 18:30', 'Bedok - Woodlands'], [4, 8, 9.5, 'confirmed', '08:00 - 09:30', 'Bedok - Woodlands'], [4, 10.5, 12, 'confirmed', '10:30 - 12:00', 'Woodlands - Bedok'], [4, 13.5, 15.5, 'pending', '08:00 - 09:30', 'Bedok - Woodlands', true], [4, 16, 18, 'scheduled', '16:00 - 18:30', 'Bedok - Woodlands'], [5, 8, 9.5, 'confirmed', '08:00 - 09:30', 'Bedok - Woodlands'], [5, 10, 11.5, 'confirmed', '10:00 - 11:30', 'Bedok - Woodlands'], [5, 13.5, 15.5, 'scheduled', '13:30 - 15:30', 'Bedok - Woodlands'], [5, 16, 18, 'scheduled', '16:00 - 18:30', 'Woodlands - Bedok']],
  unassigned: [[9, 10.5], [10, 12], [13.5, 15], [19, 20.5], [8.5, 10], [10.5, 12], [13, 14.5], [17.5, 19]],
  trips: [{
    id: 'TID260921',
    status: 'Completed',
    client: 'Google Pte Ltd',
    site: 'WEN',
    date: '22/05/2025',
    time: '07:00',
    vehicle: 'SBA 5678B',
    onTime: 'On time'
  }, {
    id: 'TID260922',
    status: 'Completed',
    client: 'Google Pte Ltd',
    site: 'WEN',
    date: '22/05/2025',
    time: '07:00',
    vehicle: 'SBA 5678B',
    onTime: 'On time'
  }, {
    id: 'TID260923',
    status: 'Completed',
    client: 'Google Pte Ltd',
    site: 'WEN',
    date: '22/05/2025',
    time: '07:00',
    vehicle: 'SBA 5678B',
    onTime: 'On time'
  }, {
    id: 'TID260924',
    status: 'Cancelled',
    client: 'Grab Singapore',
    site: 'ONE',
    date: '21/05/2025',
    time: '17:35',
    vehicle: 'SJA 0007T',
    onTime: 'Late'
  }],
  tripLog: [{
    message: '5 passengers alighted at Jurong West Ave',
    timestamp: 'Feb 22, 2023 at 07:35 AM'
  }, {
    message: 'Bus SBA3546 arrived at Jurong West Ave',
    timestamp: 'Feb 22, 2023 at 07:35 AM'
  }, {
    message: 'Bus SBA3546 skipped Jurong West Central. No passenger required to dropoff.',
    timestamp: 'Feb 22, 2023 at 07:05 AM'
  }, {
    message: 'Bus SBA3546 departed from Boon Lay Ave',
    timestamp: 'Feb 22, 2023 at 07:01 AM'
  }, {
    message: '5 passengers boarded at Boon Lay Ave',
    timestamp: 'Feb 22, 2023 at 06:55 AM'
  }, {
    message: 'Bus SBA3546 arrived Boon Lay Ave',
    timestamp: 'Feb 22, 2023 at 06:55 AM'
  }, {
    message: 'Bus SBA3546 was on the way to Boon Lay Ave',
    timestamp: 'Feb 22, 2023 at 06:35 AM'
  }],
  dailyRider: [['Apr 2023', 130], ['May 2023', 78], ['Jun 2023', 80], ['Jul 2023', 129], ['Aug 2023', 128], ['Sep 2023', 132], ['Oct 2023', 128], ['Nov 2023', 140], ['Dec 2023', 89], ['Jan 2024', 89], ['Feb 2024', 100], ['Mar 2024', 128], ['Apr 2024', 124]],
  speedHistory: [['06:30', 28], ['06:40', 43], ['06:50', 58], ['07:00', 58], ['07:10', 58], ['07:20', 58], ['07:30', 57], ['07:40', 33], ['07:50', 72], ['08:00', 8]]
};
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/fleet_console/data.js", error: String((e && e.message) || e) }); }

__ds_ns.Button = __ds_scope.Button;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.DataTable = __ds_scope.DataTable;

__ds_ns.KeyValueList = __ds_scope.KeyValueList;

__ds_ns.LogList = __ds_scope.LogList;

__ds_ns.Sparkline = __ds_scope.Sparkline;

__ds_ns.SpeedLegend = __ds_scope.SpeedLegend;

__ds_ns.StatCard = __ds_scope.StatCard;

__ds_ns.Timeline = __ds_scope.Timeline;

__ds_ns.Avatar = __ds_scope.Avatar;

__ds_ns.Chip = __ds_scope.Chip;

__ds_ns.CountChip = __ds_scope.CountChip;

__ds_ns.FilterChip = __ds_scope.FilterChip;

__ds_ns.MetaPill = __ds_scope.MetaPill;

__ds_ns.StatusBadge = __ds_scope.StatusBadge;

__ds_ns.StatusSegments = __ds_scope.StatusSegments;

__ds_ns.Tooltip = __ds_scope.Tooltip;

__ds_ns.MapOverlayCard = __ds_scope.MapOverlayCard;

__ds_ns.SchedulerBlock = __ds_scope.SchedulerBlock;

__ds_ns.TripListCard = __ds_scope.TripListCard;

__ds_ns.VehicleRow = __ds_scope.VehicleRow;

__ds_ns.Checkbox = __ds_scope.Checkbox;

__ds_ns.ColorField = __ds_scope.ColorField;

__ds_ns.DateField = __ds_scope.DateField;

__ds_ns.FieldLabel = __ds_scope.FieldLabel;

__ds_ns.FileDrop = __ds_scope.FileDrop;

__ds_ns.Input = __ds_scope.Input;

__ds_ns.PhoneField = __ds_scope.PhoneField;

__ds_ns.Radio = __ds_scope.Radio;

__ds_ns.SearchInput = __ds_scope.SearchInput;

__ds_ns.SegmentedControl = __ds_scope.SegmentedControl;

__ds_ns.Select = __ds_scope.Select;

__ds_ns.Switch = __ds_scope.Switch;

__ds_ns.TagInput = __ds_scope.TagInput;

__ds_ns.Textarea = __ds_scope.Textarea;

__ds_ns.TogglePill = __ds_scope.TogglePill;

__ds_ns.YesNoToggle = __ds_scope.YesNoToggle;

__ds_ns.Breadcrumb = __ds_scope.Breadcrumb;

__ds_ns.NavFlyout = __ds_scope.NavFlyout;

__ds_ns.NavRail = __ds_scope.NavRail;

__ds_ns.Stepper = __ds_scope.Stepper;

__ds_ns.Tabs = __ds_scope.Tabs;

__ds_ns.TopBar = __ds_scope.TopBar;

__ds_ns.ViewToggle = __ds_scope.ViewToggle;

})();
