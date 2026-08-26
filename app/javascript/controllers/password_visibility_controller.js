import { Controller } from "@hotwired/stimulus"

// Mostra o nasconde in chiaro il contenuto di un campo password.
//
// Non va usato direttamente nelle viste: il markup che lo collega ai target è centralizzato
// nel partial layouts/_password_field.html.erb.
//
// Le due icone sono entrambe nel DOM e si alternano con una classe CSS invece che con
// l'attributo hidden, che sugli elementi <svg> non è affidabile.
export default class extends Controller {
  static targets = ["input", "button", "showIcon", "hideIcon"]

  toggle() {
    const willReveal = this.inputTarget.type === "password"

    this.inputTarget.type = willReveal ? "text" : "password"

    // Password in chiaro: mostro l'occhio barrato, che indica l'azione di nascondere
    this.showIconTarget.classList.toggle("v2-password-icon--hidden", willReveal)
    this.hideIconTarget.classList.toggle("v2-password-icon--hidden", !willReveal)

    this.buttonTarget.setAttribute(
      "aria-label",
      willReveal ? "Nascondi la password" : "Mostra la password"
    )
  }
}
