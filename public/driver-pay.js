// Driver pay engine: rate plans, pay schemes and the salary simulator. window.DriverPay
(function () {
  const DOW = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
  const tm = t => { const [h, m] = String(t || '00:00').split(':').map(Number); return (h || 0) * 60 + (m || 0); };
  const hm = m => String(Math.floor(m / 60) % 24).padStart(2, '0') + ':' + String(Math.round(m % 60)).padStart(2, '0');
  const iso = (y, m, d) => y + '-' + String(m).padStart(2, '0') + '-' + String(d).padStart(2, '0');
  const addD = (s, n) => { const x = new Date(s + 'T00:00:00Z'); x.setUTCDate(x.getUTCDate() + n); return x.toISOString().slice(0, 10); };
  const dow = s => new Date(s + 'T00:00:00Z').getUTCDay();
  const lbl = (s, ph) => ph[s] ? 'ph' : DOW[dow(s)];
  const uid = () => Math.random().toString(36).slice(2, 9);
  const r2 = x => Math.round(x * 100) / 100;
  const money = n => 'S$' + Number(n || 0).toLocaleString('en-SG', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const num = n => String(Math.round(n * 100) / 100);

  function period(plan, d, mins, ph) {
    let day = d; if (mins >= 1440) { day = addD(d, 1); mins -= 1440; }
    const today = lbl(day, ph), yest = lbl(addD(day, -1), ph), hits = [];
    (plan.periods || []).forEach(p => (p.timeRanges || []).forEach(r => { const a = tm(r.startTime); let b = tm(r.endTime); if (b === 1439) b = 1440;
      if (a < b) { if (p.days.includes(today) && mins >= a && mins < b) hits.push(p); }
      else { if (p.days.includes(today) && mins >= a) hits.push(p); if (p.days.includes(yest) && mins < b) hits.push(p); } }));
    return hits.find(p => p.isOverride) || hits[0] || null;
  }
  const inSched = (d, sc, ph, J, incPH) => { if (ph[d] && !incPH) return false; const w = dow(d); if (sc === 'all-days' || (w >= 1 && w <= 5)) return true; if (sc === 'mon-sat') return w === 6; if (sc === 'mon-fri-sun') return w === 0; if (sc === '6-days') { if (w === 6) return true; const s = addD(d, -1); return !!ph[s] || !((J || {})[s] || []).length; } return false; };

  function seedPlans(vts) {
    const wk = ['mon', 'tue', 'wed', 'thu', 'fri'], base = s => s <= 6 ? [12, 8] : s <= 13 ? [14, 10] : s <= 23 ? [16, 12] : s <= 29 ? [18, 14] : [22, 16];
    const R = add => Object.fromEntries((vts || []).map(v => { const b = base(+v.seats || 0); return [v.value, { trip: b[0] + add, hourly: b[1] + add }]; }));
    return [{ id: 'rp-std', name: 'Standard', description: 'Weekday, peak, night and weekend rates', vehicleTypes: (vts || []).map(v => v.value), periods: [
      { id: uid(), name: 'Off Peak', days: wk, timeRanges: [{ id: uid(), startTime: '07:00', endTime: '19:00' }], rates: R(0) },
      { id: uid(), name: 'Peak', days: wk, timeRanges: [{ id: uid(), startTime: '05:00', endTime: '07:00' }, { id: uid(), startTime: '19:00', endTime: '21:00' }], rates: R(2) },
      { id: uid(), name: 'Night', days: wk, timeRanges: [{ id: uid(), startTime: '21:00', endTime: '05:00' }], rates: R(3) },
      { id: uid(), name: 'Weekend and PH', days: ['sat', 'sun', 'ph'], timeRanges: [{ id: uid(), startTime: '00:00', endTime: '23:59' }], isOverride: true, rates: R(4) }] }];
  }
  function cover(plan, L, mins) { const PREV = { mon: 'sun', tue: 'mon', wed: 'tue', thu: 'wed', fri: 'thu', sat: 'fri', sun: 'sat', ph: 'ph' }, hits = [];
    (plan.periods || []).forEach(p => (p.timeRanges || []).forEach(r => { const a = tm(r.startTime); let b = tm(r.endTime); if (b === 1439) b = 1440;
      if (a < b) { if (p.days.includes(L) && mins >= a && mins < b) hits.push(p); } else { if (p.days.includes(L) && mins >= a) hits.push(p); if (p.days.includes(PREV[L]) && mins < b) hits.push(p); } }));
    return hits.find(p => p.isOverride) || hits[0] || null; }
  function blankScheme(planId) {
    return { id: 'ps-' + uid(), name: '', description: '', isDefault: false, schemeType: 'basic_plus_trips',
      basicSalary: 0, basicCoversDailyTrips: false, basicCoveredDailyTrips: 1, basicCoveredSchedule: 'mon-fri', disposalCountsAsTrips: false,
      hasGuarantee: false, guaranteedAmount: 2200, onTop: { ph: false, sat: false, sun: false },
      hasPostGuaranteeBoost: false, postGuaranteeBoostType: 'percentage', postGuaranteeBoostValue: 50,
      hasRejectionPenalty: false, rejectionPenaltyAllowedJobs: 0, rejectionPenaltyFallbackBasic: 0, rejectionPenaltyKeepsIncentives: true,
      monthlyPayAmount: 2200, monthlyMinimumType: 'daily', monthlyDailyTripsCommitment: 6, monthlyTripsCommitment: 150, monthlyExpectedSchedule: 'mon-fri',
      shiftSalary: 0, shiftStartTime: '08:00', shiftEndTime: '18:00', shiftWorkingDays: ['mon', 'tue', 'wed', 'thu', 'fri'], shiftOvertimePayType: 'trip_rates', shiftOvertimeHourlyRate: 0,
      baseRatePlanId: planId || '', schoolRoutesPay: false, routeBands: [{ to: 40, amt: 200 }, { to: 70, amt: 300 }, { to: '', amt: 350 }], schoolRoutesCount: false, schoolRoutesInG: true, hasDailyVolumeIncentive: false, dailyVolumeIncludesInGuarantee: false,
      dailyVolumeTiers: [{ id: uid(), fromTripStart: 7, toTripEnd: 10, boostType: 'flat', boostValue: 2 }, { id: uid(), fromTripStart: 11, toTripEnd: null, boostType: 'flat', boostValue: 3 }],
      hasWeeklyTargetIncentive: false, weeklyTargetIncludesInGuarantee: false, weeklyTargetTiers: [{ id: uid(), targetTrips: 20, incentiveType: 'lump_sum', incentiveValue: 50 }],
      hasMonthlyTargetIncentive: false, monthlyTargetIncludesInGuarantee: false, monthlyTargetTiers: [{ id: uid(), targetTrips: 100, incentiveType: 'lump_sum', incentiveValue: 200 }] };
  }
  function seedSchemes(planId) {
    return [Object.assign(blankScheme(planId), { id: 'ps-std', name: 'Basic + Trips', description: 'Basic pay with 1 trip a day included, topped up to S$2,200', isDefault: true,
      basicSalary: 500, basicCoversDailyTrips: true, hasGuarantee: true, onTop: { ph: true, sat: false, sun: false }, hasPostGuaranteeBoost: true, postGuaranteeBoostValue: 20,
      hasRejectionPenalty: true, rejectionPenaltyAllowedJobs: 1, hasDailyVolumeIncentive: true, hasWeeklyTargetIncentive: true, hasMonthlyTargetIncentive: true })];
  }
  function sampleJobs(ym, ph) {
    const y = +ym.slice(0, 4), m = +ym.slice(5, 7), nd = new Date(Date.UTC(y, m, 0)).getUTCDate(), out = {}; let firstWk = null, sat = null, sun = null;
    for (let i = 1; i <= nd; i++) { const d = iso(y, m, i), w = dow(d), L = [];
      if (ph[d]) { if (w >= 1 && w <= 5) { L.push({ id: uid(), type: 'trip', startTime: '07:00', tv: 1 }, { id: uid(), type: 'trip', startTime: '13:00', tv: 1 }); } }
      else if (w >= 1 && w <= 5) { ['06:00', '07:00', '13:00', '15:00', '16:00'].forEach(t => L.push({ id: uid(), type: 'trip', startTime: t, tv: w === 3 && t === '07:00' ? 1.5 : 1 })); if (!firstWk) { firstWk = d; L.push({ id: uid(), type: 'disposal', startTime: '17:00', endTime: '23:00' }); } }
      else if (w === 6 && !sat) { sat = d; L.push({ id: uid(), type: 'disposal', startTime: '08:00', endTime: '15:00' }); }
      else if (w === 0 && !sun) { sun = d; L.push({ id: uid(), type: 'disposal', startTime: '08:00', endTime: '15:00' }); }
      if (L.length) out[d] = L; }
    return out;
  }

  function simulate(o) {
    const S = o.scheme, P = o.plan || { periods: [] }, vt = o.vt, ph = o.ph || {}, ym = o.ym, J = o.jobs || {}, exc = S.onTop || {}, rtB = (S.routeBands || [{ to: 40, amt: 200 }, { to: 70, amt: 300 }, { to: '', amt: 350 }]).map(b => ({ to: b.to === '' || b.to == null ? Infinity : +b.to, amt: +b.amt || 0 })).sort((a, b) => a.to - b.to), bandAmt = m => ((rtB.find(b => m <= b.to) || rtB[rtB.length - 1]) || { amt: 0 }).amt, rtL = ((o.routes || {}).list || []).map(r => +r.min || 0), rtN = rtL.length, rtAmts = rtL.map(bandAmt), rtAmt = rtN ? rtAmts.reduce((a, b) => a + b, 0) / rtN : 0;
    const y = +ym.slice(0, 4), m = +ym.slice(5, 7), nd = new Date(Date.UTC(y, m, 0)).getUTCDate(), dates = Array.from({ length: nd }, (_, i) => iso(y, m, i + 1));
    const T = S.schemeType, pen = !!S.hasRejectionPenalty && (+o.rejected || 0) > (+S.rejectionPenaltyAllowedJobs || 0), inc = !pen || S.rejectionPenaltyKeepsIncentives !== false;
    const base = T === 'basic_plus_trips' ? +S.basicSalary || 0 : pen ? +S.rejectionPenaltyFallbackBasic || 0 : T === 'monthly_with_minimum' ? +S.monthlyPayAmount || 0 : +S.shiftSalary || 0;
    const G = +S.guaranteedAmount || 0, hasG = T === 'basic_plus_trips' && !!S.hasGuarantee && !pen;
    const isExc = d => hasG && ((exc.ph && ph[d]) || (exc.sat && dow(d) === 6) || (exc.sun && dow(d) === 0));
    const fb = pen && T !== 'basic_plus_trips', shiftOn = (d, mins) => T === 'shift_based' && !fb && !ph[d] && (S.shiftWorkingDays || []).includes(DOW[dow(d)]) && mins >= tm(S.shiftStartTime) && mins < tm(S.shiftEndTime);
    const rtS = ((o.routes || {}).list || []).map(r => r.start || '07:00'), hol = (o.routes || {}).hol || [], inHol = d => !!(hol[0] && d >= hol[0] && d <= (hol[1] || hol[0])), JJ = Object.assign({}, J);
    if (rtN && !S.schoolRoutesPay) dates.forEach(d => { const w = dow(d); if (w >= 1 && w <= 5 && !ph[d] && !inHol(d)) JJ[d] = (J[d] || []).concat(rtS.map(st => ({ type: 'trip', startTime: st, tv: 1, route: true }))); });
    const TB = {}, DB = {}, WKS = [], MOS = []; let exCore = 0, exVol = 0, exPg = 0, exTrip = 0, exDisp = 0; const TBX = {}, DBX = {}; let wStart = dates[0]; let tripPay = 0, dispPay = 0, dInc = 0, wInc = 0, mInc = 0, pgInc = 0, onTop = 0, basis = base, trips = 0, hrs = 0, gCount = 0, wTrips = 0, cov = 0, cum = base, nPayable = 0;
    const days = {}, periodStats = {};
    const avail = (d, dayCount) => { if (fb) return 0;
      if (T === 'basic_plus_trips') return S.basicCoversDailyTrips && inSched(d, S.basicCoveredSchedule, ph, J, S.basicCoverPH) ? Math.max(0, (+S.basicCoveredDailyTrips || 0) - dayCount) : 0;
      if (T === 'monthly_with_minimum') return S.monthlyMinimumType === 'monthly' ? Math.max(0, (+S.monthlyTripsCommitment || 0) - gCount) : inSched(d, S.monthlyExpectedSchedule, ph, J, S.monthlyCoverPH) ? Math.max(0, (+S.monthlyDailyTripsCommitment || 0) - dayCount) : 0;
      return 0; };
    const pgBoost = (amt, units, curBasis) => { if (!inc || !S.hasPostGuaranteeBoost || !hasG || curBasis < G || units <= 0) return 0; const v = +S.postGuaranteeBoostValue || 0, t = S.postGuaranteeBoostType;
      return t === 'percentage' ? amt * v / 100 : t === 'flat' ? v * units : Math.max(0, v * units - amt); };
    dates.forEach(d => {
      if (dow(d) === 1) wTrips = 0; if (dow(d) === 1 || d === dates[0]) wStart = d;
      const L = (JJ[d] || []).slice().sort((a, b) => tm(a.startTime) - tm(b.startTime)), lines = [], ex = isExc(d); let dayCount = 0, sub = 0, dayBasis = 0, dTrips = 0;
      const sd = !inHol(d), nC = rtN && dow(d) >= 1 && dow(d) <= 5 && !ph[d] ? (S.schoolRoutesPay ? (S.schoolRoutesCount || sd ? rtN : 0) : (!sd && S.schoolRoutesCount ? rtN : 0)) : 0;
      if (nC) { const c0 = Math.min(nC, avail(d, 0)); cov += c0; dayCount = nC; dTrips = nC; trips += nC; wTrips += nC; gCount += nC; lines.push({ t: 'Routes', d: nC + (nC === 1 ? ' school route' : ' school routes') + (sd ? ' counted as trips, paid by the route retainer' : ' counted in the school holidays, not driven') + (c0 ? ', ' + c0 + ' included in base pay' : ''), a: money(0), n: '' }); }
      const ev = [];
      L.forEach(j => { if (j.type === 'trip') ev.push({ k: 'trip', s: tm(j.startTime), j }); else { const s = tm(j.startTime); let e = tm(j.endTime || '23:59'); if (e <= s) e += 1440; for (let h = s; h < e; h = Math.min(e, h + 60)) ev.push({ k: 'hr', s: h, e: Math.min(e, h + 60) }); } });
      ev.sort((a, b) => a.s - b.s); let blk = null;
      const flush = () => { if (!blk) return; const b = blk; blk = null; lines.push({ t: hm(b.s) + ' to ' + hm(b.e), d: 'Disposal | ' + b.pn + (b.cov ? ' | ' + num(b.cov) + ' h included' : '') + (b.pg ? ' | +' + money(b.pg) + ' after guarantee' : '') + (ex ? ' | on top' : ''), a: money(b.amt), n: num(b.hrs - b.cov) + ' h x ' + money(b.rate) }); };
      ev.forEach(x => {
        if (x.k === 'trip') { flush(); const j = x.j, tv = j.tv == null || j.tv === '' || isNaN(+j.tv) ? 1 : Math.max(0, +j.tv), p = period(P, d, x.s, ph), rate = p && p.rates[vt] ? +p.rates[vt].trip || 0 : 0, pn = p ? p.name : 'No period';
          periodStats[pn] = (periodStats[pn] || 0) + tv;
          const c = shiftOn(d, x.s) ? tv : Math.min(tv, avail(d, dayCount)), pay = tv - c, core = rate * pay; if (pay > 0) { const B = ex ? TBX : TB; B[rate] = (B[rate] || 0) + pay; } let vol = 0;
          if (inc && S.hasDailyVolumeIncentive && pay > 0) { const n = Math.floor(dayCount) + 1, tr = (S.dailyVolumeTiers || []).find(t => n >= +t.fromTripStart && (t.toTripEnd == null || t.toTripEnd === '' || n <= +t.toTripEnd));
            if (tr) vol = tr.boostType === 'flat' ? +tr.boostValue * pay : tr.boostType === 'percentage' ? rate * (+tr.boostValue) / 100 * pay : Math.max(0, (+tr.boostValue - rate) * pay); }
          const pg = pgBoost(core + vol, pay, basis + dayBasis), amt = core + vol + pg;
          tripPay += core; dInc += vol; pgInc += pg; sub += amt; cov += c; if (pay > 0) nPayable += pay;
          if (ex) { onTop += amt; exCore += core; exTrip += core; exVol += vol; exPg += pg; } else dayBasis += core + (S.dailyVolumeIncludesInGuarantee ? vol : 0);
          dayCount += tv; dTrips += tv; trips += tv; wTrips += tv; gCount += tv;
          lines.push({ t: j.startTime, d: (j.route ? 'School route | ' : '') + (c >= tv ? 'Included in base pay' : pn + (tv !== 1 ? ' | trip value ' + num(tv) : '') + (c > 0 ? ' | ' + num(c) + ' included' : '') + (vol ? ' | +' + money(vol) + ' daily volume' : '') + (pg ? ' | +' + money(pg) + ' after guarantee' : '') + (ex ? ' | on top' : '')), a: money(amt), n: c >= tv ? '' : num(pay) + ' x ' + money(rate) }); }
        else { const p = period(P, d, x.s, ph), step = (x.e - x.s) / 60, inShift = shiftOn(d, x.s % 1440), pn = p ? p.name : 'No period';
          const rate = T === 'shift_based' && !fb && S.shiftOvertimePayType === 'hourly_rate' ? +S.shiftOvertimeHourlyRate || 0 : p && p.rates[vt] ? +p.rates[vt].hourly || 0 : 0;
          let c = 0; if (inShift) c = step; else if (S.disposalCountsAsTrips && T !== 'shift_based') { c = Math.min(step, avail(d, dayCount)); dayCount += c; gCount += c; }
          const pay = step - c, core = rate * pay, pg = pgBoost(core, pay, basis + dayBasis), amt = core + pg; if (pay > 0) { const B = ex ? DBX : DB; B[rate] = (B[rate] || 0) + pay; }
          dispPay += core; pgInc += pg; sub += amt; hrs += step; cov += c; if (ex) { onTop += amt; exCore += core; exDisp += core; exPg += pg; } else dayBasis += core;
          if (blk && blk.pn === pn && blk.rate === rate && !!blk.cov === !!c && blk.e === x.s) { blk.e = x.e; blk.hrs += step; blk.cov += c; blk.amt += amt; blk.pg += pg; } else { flush(); blk = { s: x.s, e: x.e, pn, rate, hrs: step, cov: c, amt, pg }; } } });
      flush();
      if (inc && S.hasWeeklyTargetIncentive && dow(d) === 0 && dow(wStart) === 1) { const tr = (S.weeklyTargetTiers || []).filter(t => wTrips >= +t.targetTrips).sort((a, b) => b.targetTrips - a.targetTrips)[0]; WKS.push({ from: wStart, to: d, trips: wTrips, target: tr ? +tr.targetTrips : null, first: Math.min(...(S.weeklyTargetTiers || []).map(t => +t.targetTrips || 0)), amt: tr ? (tr.incentiveType === 'lump_sum' ? +tr.incentiveValue : wTrips * (+tr.incentiveValue)) : 0 });
        if (tr) { const a = tr.incentiveType === 'lump_sum' ? +tr.incentiveValue : wTrips * (+tr.incentiveValue); if (a > 0) { wInc += a; sub += a; if (S.weeklyTargetIncludesInGuarantee) dayBasis += a; lines.push({ t: 'Week', d: 'Weekly target | ' + num(wTrips) + ' trips, target ' + tr.targetTrips, a: money(a), n: '' }); } } }
      if (inc && S.hasMonthlyTargetIncentive && d === dates[dates.length - 1]) { const tr = (S.monthlyTargetTiers || []).filter(t => trips >= +t.targetTrips).sort((a, b) => b.targetTrips - a.targetTrips)[0]; MOS.push({ trips, target: tr ? +tr.targetTrips : null, first: Math.min(...(S.monthlyTargetTiers || []).map(t => +t.targetTrips || 0)), amt: tr ? (tr.incentiveType === 'lump_sum' ? +tr.incentiveValue : trips * (+tr.incentiveValue)) : 0 });
        if (tr) { const a = tr.incentiveType === 'lump_sum' ? +tr.incentiveValue : trips * (+tr.incentiveValue); if (a > 0) { mInc += a; sub += a; if (S.monthlyTargetIncludesInGuarantee) dayBasis += a; lines.push({ t: 'Month', d: 'Monthly target | ' + num(trips) + ' trips, target ' + tr.targetTrips, a: money(a), n: '' }); } } }
      basis += dayBasis; cum += sub; days[d] = { lines, sub: r2(sub), cum: r2(cum), trips: dTrips, ex, ph: ph[d] || '' };
    });
    const rtPay = S.schoolRoutesPay ? rtN * rtAmt : 0; if (S.schoolRoutesInG !== false) basis += rtPay; const topUp = hasG && basis < G ? G - basis : 0, total = base + rtPay + tripPay + dispPay + dInc + wInc + mInc + pgInc + topUp;
    const BL = T === 'basic_plus_trips' ? 'Basic Salary' : pen ? 'Fallback Basic Salary' : T === 'monthly_with_minimum' ? 'Monthly Pay' : 'Shift Salary';
    const rows = [[BL, money(base)], ['Trips Counted', num(trips) + ' trips'], cov > 0 && ['Included in Base Pay', num(cov) + (T === 'shift_based' ? ' trips or hours in shift' : ' trips or hours')], rtPay > 0 && ['School Route Pay', money(rtPay) + ', ' + rtN + ' x ' + money(rtAmt)], ['Trip Pay', money(tripPay)], hrs > 0 && ['Disposal Hours', num(hrs) + ' h'], hrs > 0 && ['Disposal Pay', money(dispPay)],
      dInc > 0 && ['Daily Volume Incentives', '+' + money(dInc)], wInc > 0 && ['Weekly Target Incentives', '+' + money(wInc)], mInc > 0 && ['Monthly Target Incentives', '+' + money(mInc)], pgInc > 0 && ['After-Guarantee Boost', '+' + money(pgInc)],
      hasG && ['Counted Towards Guarantee', money(basis) + ' of ' + money(G)], hasG && onTop > 0 && ['Paid on Top of Guarantee', money(onTop)], topUp > 0 && ['Guarantee Top-Up', '+' + money(topUp)], pen && ['Rejection Penalty', 'Triggered. ' + (T === 'basic_plus_trips' ? 'No guarantee' : 'Paid as Basic + Trips') + (inc ? ', incentives kept' : ', no incentives')]].filter(Boolean).map(([k, v]) => ({ k, v }));
    return { total: r2(total), base: r2(base), tripPay: r2(tripPay), dispPay: r2(dispPay), inc: r2(dInc + wInc + mInc + pgInc), dInc: r2(dInc), wInc: r2(wInc), mInc: r2(mInc), pgInc: r2(pgInc), cov: r2(cov), weeks: WKS, months: MOS, exCore: r2(exCore), exTrip: r2(exTrip), exDisp: r2(exDisp), tripByX: Object.entries(TBX).map(([r, u]) => ({ rate: +r, units: r2(u) })).sort((a, b) => b.units - a.units), dispByX: Object.entries(DBX).map(([r, u]) => ({ rate: +r, units: r2(u) })).sort((a, b) => b.units - a.units), exVol: r2(exVol), exPg: r2(exPg), tripBy: Object.entries(TB).map(([r, u]) => ({ rate: +r, units: r2(u) })).sort((a, b) => b.units - a.units), dispBy: Object.entries(DB).map(([r, u]) => ({ rate: +r, units: r2(u) })).sort((a, b) => b.units - a.units), rtPay: r2(rtPay), rtN, rtAmt, rtAmts, topUp: r2(topUp), onTop: r2(onTop), basis: r2(basis), trips, hrs, pen, rows, days, dates, periodStats, nPayable };
  }
  window.DriverPay = { seedPlans, seedSchemes, blankScheme, sampleJobs, simulate, money, DOW, dow, addD, uid, tm, period, cover };
})();
