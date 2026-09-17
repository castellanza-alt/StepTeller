/* Step Teller — modello cadenza(velocità). Nessuna dipendenza.
   Curve standard: valori di letteratura per uomo ~178 cm (Inferred, non misurati su Will).
   La taratura personale corregge la curva con il rapporto misurato/standard. */
(function (root) {
  const DEF = {
    walk: [[2, 75], [3, 90], [4, 101], [5, 110], [6, 119], [7, 129], [8, 138]],
    run:  [[6, 152], [7, 156], [8, 159], [9, 162], [10, 165], [12, 170], [14, 176]]
  };
  const RANGE = { walk: [2, 8], run: [6, 14] };

  // interpolazione lineare a tratti; fuori dai punti prosegue con la pendenza dell'ultimo tratto
  function interp(pts, v) {
    if (pts.length === 1) return pts[0][1];
    let i = 0;
    while (i < pts.length - 2 && v > pts[i + 1][0]) i++;
    const [x0, y0] = pts[i], [x1, y1] = pts[i + 1];
    return y0 + (y1 - y0) * (v - x0) / (x1 - x0);
  }

  // rapporto misurato/standard: costante con 1 punto, lineare a tratti e piatto agli estremi con 2+
  function ratio(mode, v, cal) {
    const pts = ((cal && cal[mode]) || [])
      .filter(p => p && p[0] > 0 && p[1] > 0)
      .map(p => [p[0], p[1] / interp(DEF[mode], p[0])])
      .sort((a, b) => a[0] - b[0]);
    if (!pts.length) return 1;
    if (v <= pts[0][0]) return pts[0][1];
    if (v >= pts[pts.length - 1][0]) return pts[pts.length - 1][1];
    return interp(pts, v);
  }

  function cadence(mode, v, cal) { return interp(DEF[mode], v) * ratio(mode, v, cal); }
  function stepsFor(mode, v, minutes, cal) { return cadence(mode, v, cal) * minutes; }
  function minutesFor(mode, v, steps, cal) { return steps / cadence(mode, v, cal); }

  const api = { DEF, RANGE, interp, ratio, cadence, stepsFor, minutesFor };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  root.StepModel = api;
})(typeof self !== 'undefined' ? self : this);
