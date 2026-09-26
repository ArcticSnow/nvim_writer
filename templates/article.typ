#set document(title: "%{title}", author: "%{author}")
#set page(margin: 2.5cm, numbering: "1")
#set text(font: "New Computer Modern", size: 11pt, lang: "en")
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1")

#align(center)[
  #text(size: 17pt, weight: "bold")[%{title}]

  #v(0.3em)
  #text(size: 11pt)[%{author}] \
  #text(size: 10pt, fill: gray)[%{date}]
]

#v(1.5em)

= Introduction

= Body

= Conclusion

// Uncomment once you have a refs.bib in this folder and have cited
// something with <leader>bb:
// #bibliography("refs.bib")
