#set page(width: 960pt, height: 540pt, margin: 40pt)
#set text(font: "New Computer Modern", size: 24pt, lang: "en")

#let slide(title: none, body) = {
  if title != none {
    text(size: 32pt, weight: "bold")[#title]
    v(1em)
  }
  body
}

#slide(title: "%{title}")[
  #text(size: 18pt, fill: gray)[%{author} --- %{date}]
]

#pagebreak()

#slide(title: "Overview")[
  - Point one
  - Point two
  - Point three
]

#pagebreak()

#slide(title: "Thank you")[]
