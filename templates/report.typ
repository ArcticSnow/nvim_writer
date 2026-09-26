#set document(title: "%{title}", author: "%{author}")
#set page(
  margin: 2.5cm,
  numbering: "1",
  header: align(right, text(size: 9pt, fill: gray)[%{title}]),
)
#set text(font: "New Computer Modern", size: 11pt, lang: "en")
#set heading(numbering: "1.")
#set par(justify: true)

#align(center)[
  #text(size: 20pt, weight: "bold")[%{title}]
  #v(0.3em)
  #text(size: 11pt, fill: gray)[%{author} --- %{date}]
]

#v(1.5em)
#outline()
#pagebreak()

= Summary

= Findings

= Recommendations
