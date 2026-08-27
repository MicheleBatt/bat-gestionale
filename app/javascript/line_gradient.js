// Plugin Chart.js che disegna una sfumatura sotto la linea nei soli grafici a linea.
// Il colore della sfumatura è quello della linea stessa, che sfuma verso il basso.

// Converte un colore CSS (#rgb, #rrggbb, rgb(), rgba()) in rgba() con l'opacità data.
// Restituisce null se il formato non è riconosciuto.
function withAlpha(color, alpha) {
  if (typeof color !== "string") return null

  const hex = color.trim().match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/i)
  if (hex) {
    let digits = hex[1]
    if (digits.length === 3) digits = digits.split("").map((d) => d + d).join("")
    const r = parseInt(digits.slice(0, 2), 16)
    const g = parseInt(digits.slice(2, 4), 16)
    const b = parseInt(digits.slice(4, 6), 16)
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  }

  const rgb = color.trim().match(/^rgba?\(\s*([\d.]+)[\s,]+([\d.]+)[\s,]+([\d.]+)/i)
  if (rgb) return `rgba(${rgb[1]}, ${rgb[2]}, ${rgb[3]}, ${alpha})`

  return null
}

// Con più serie sovrapposte le sfumature si sommano, quindi si tengono opacità più basse.
function alphaRange(datasetsCount) {
  return datasetsCount > 1 ? { top: 0.12, bottom: 0.04 } : { top: 0.2, bottom: 0.07 }
}

// Valore numerico di un punto, che chartkick passa come numero o come { x, y }.
function pointValue(point) {
  if (typeof point === "number") return point
  if (point && typeof point.y === "number") return point.y
  return null
}

// Escursione verticale dei dati di tutte le serie, in valori dell'asse y.
function dataExtent(chart) {
  let min = Infinity
  let max = -Infinity

  chart.data.datasets.forEach((dataset) => {
    (dataset.data || []).forEach((point) => {
      const value = pointValue(point)
      if (value === null || !isFinite(value)) return
      if (value < min) min = value
      if (value > max) max = value
    })
  })

  return isFinite(min) && isFinite(max) ? { min: min, max: max } : null
}

// La sfumatura è ancorata all'escursione dei dati e non all'altezza dell'area del
// grafico: così il tratto più basso della linea parte comunque da un colore visibile.
// Fuori da quell'intervallo il gradiente resta piatto sul colore dell'estremo.
function gradientBounds(chart, chartArea) {
  const scale = chart.scales.y
  const extent = scale ? dataExtent(chart) : null
  if (!extent) return { top: chartArea.top, bottom: chartArea.bottom }

  const top = scale.getPixelForValue(extent.max)
  const bottom = scale.getPixelForValue(extent.min)
  // Serie piatta: senza escursione il gradiente degenererebbe in una riga.
  if (!isFinite(top) || !isFinite(bottom) || bottom - top < 8) {
    return { top: chartArea.top, bottom: chartArea.bottom }
  }

  return { top: top, bottom: bottom }
}

const lineGradientPlugin = {
  id: "lineGradient",

  beforeUpdate(chart) {
    if (chart.config.type !== "line") return

    const datasets = chart.data.datasets
    const alpha = alphaRange(datasets.length)

    datasets.forEach((dataset) => {
      if (dataset.fill === false || dataset.fill === undefined) dataset.fill = "start"

      dataset.backgroundColor = (context) => {
        const { ctx, chartArea } = context.chart
        // Al primo giro l'area del grafico non è ancora calcolata.
        if (!chartArea) return null

        const from = withAlpha(dataset.borderColor, alpha.top)
        const to = withAlpha(dataset.borderColor, alpha.bottom)
        if (!from || !to) return null

        const bounds = gradientBounds(context.chart, chartArea)
        const gradient = ctx.createLinearGradient(0, bounds.top, 0, bounds.bottom)
        gradient.addColorStop(0, from)
        gradient.addColorStop(1, to)
        return gradient
      }
    })
  }
}

if (window.Chart) window.Chart.register(lineGradientPlugin)
