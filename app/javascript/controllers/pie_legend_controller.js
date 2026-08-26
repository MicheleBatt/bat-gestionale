import { Controller } from "@hotwired/stimulus"

// Sposta la legenda di un grafico a torta sotto al disegno sugli schermi stretti,
// dove a lato resterebbe schiacciata contro il bordo. Stessa soglia e stesso
// comportamento dello script della pagina statistiche.
export default class extends Controller {
  connect() {
    this.adjust = this.adjust.bind(this)
    this.attempts = 0

    this.tryAdjust()
    window.addEventListener("resize", this.adjust)
  }

  disconnect() {
    window.removeEventListener("resize", this.adjust)
  }

  // Chartkick disegna il grafico dopo il collegamento del controller: si riprova
  // finché l'istanza di Chart.js non è disponibile, poi si smette.
  tryAdjust() {
    if (this.adjust() || this.attempts > 20) return

    this.attempts += 1
    setTimeout(() => this.tryAdjust(), 150)
  }

  adjust() {
    const canvas = this.element.querySelector("canvas")
    if (!canvas || typeof Chart === "undefined" || !Chart.getChart) return false

    const chart = Chart.getChart(canvas)
    if (!chart || chart.config.type !== "pie") return false

    const narrow = window.innerWidth <= 1200
    const legend = chart.options.plugins.legend

    legend.position = narrow ? "bottom" : "right"
    legend.align = "center"
    legend.maxWidth = narrow ? undefined : 300

    chart.update()
    return true
  }
}
