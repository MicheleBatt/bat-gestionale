import { Controller } from "@hotwired/stimulus"

// Mostra la causale per esteso quando si tocca la riga di un movimento, la cui
// causale in elenco è troncata. Il fumetto è visibile solo dove il CSS lo abilita.
export default class extends Controller {
  static targets = ["tooltip"]

  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
    document.addEventListener("click", this.closeOnOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  toggle() {
    const opening = !this.tooltipTarget.classList.contains("open")

    // Un solo fumetto aperto per volta: due sovrapposti sarebbero illeggibili
    this.closeAll()
    if (opening) this.tooltipTarget.classList.add("open")
  }

  closeOnOutsideClick(event) {
    if (this.element.contains(event.target)) return

    this.tooltipTarget.classList.remove("open")
  }

  closeAll() {
    document
      .querySelectorAll(".v2-dash-movement-tooltip.open")
      .forEach((tooltip) => tooltip.classList.remove("open"))
  }
}
