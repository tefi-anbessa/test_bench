import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "basis",
    "config",
    "supply",
    "current",
    "power",
    "pf",
    "vector",
    "voltageReference"
  ]

  connect() {
    this.recalculate()
  }

  // ----------------------------
  // Events
  // ----------------------------

  recalculate() {
    const V = this.voltage()
    const I = this.val(this.currentTarget)
    const P = this.val(this.powerTarget)
    const pf = this.val(this.pfTarget)
    const S = this.val(this.vectorTarget)

    const basis = this.basisTarget.value

    let newI = I
    let newP = P
    let newPf = pf
    let newS = S

    switch (basis) {
      case "summation":
        return

      case "power_pf":
        newS = this.apparentPowerFromPowerPf(P, pf)
        newI = this.currentFromApparent(newS, V)
        break

      case "vector_pf":
        newP = this.realPowerFromVectorPf(S, pf)
        newI = this.currentFromApparent(S, V)
        break

      case "current_pf":
        newS = this.apparentPowerFromCurrent(I, V)
        newP = this.realPowerFromApparent(newS, pf)
        break

      case "current_power":
        newS = this.apparentPowerFromCurrent(I, V)
        newPf = this.powerFactorFromReal(P, newS)
        break
    }

    this.set(this.currentTarget, newI)
    this.set(this.powerTarget, newP)
    this.set(this.pfTarget, newPf)
    this.set(this.vectorTarget, newS)
  }

  // ----------------------------
  // Voltage handling (IMPORTANT FIX)
  // ----------------------------

  voltage() {
    const V = this.val(this.supplyTarget)
    const ref = this.voltageReferenceTarget?.value

    // IMPORTANT:
    // We do NOT convert voltage silently anymore.
    // We rely on config-specific formulas instead.
    return V
  }

  // ----------------------------
  // Electrical formulas (config-aware)
  // ----------------------------

  apparentPowerFromCurrent(I, V) {
    const config = this.configTarget.value

    switch (config) {
      case "three_3c":
        return Math.sqrt(3) * V * I   // V is L-L

      case "three_4c":
        return 3 * V * I              // V is L-N

      default:
        return V * I
    }
  }

  realPowerFromApparent(S, pf) {
    return S * pf
  }

  apparentPowerFromPowerPf(P, pf) {
    if (pf === 0) return 0
    return P / pf
  }

  realPowerFromVectorPf(S, pf) {
    return S * pf
  }

  currentFromApparent(S, V) {
    const config = this.configTarget.value

    switch (config) {
      case "three_3c":
        return S / (Math.sqrt(3) * V)

      case "three_4c":
        return S / (3 * V)

      default:
        return S / V
    }
  }

  powerFactorFromReal(P, S) {
    if (S === 0) return 0
    return P / S
  }

  // ----------------------------
  // Helpers
  // ----------------------------

  val(el) {
    return parseFloat(el.value) || 0
  }

  set(el, value) {
    if (!el || el.disabled) return
    if (!isFinite(value)) return
    el.value = value.toFixed(4)
  }
}