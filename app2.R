library(shiny)
library(bslib)

# Define User Interface
ui <- page_sidebar(
  title = "Title panel",
  sidebar = sidebar("Sidebar", position = "right"),
  value_box(
    title = "Value box",
    value = 100,
    showcase = bsicons::bs_icon("bar-chart"),
    theme = "teal"
  ),
  card("Card"),
  card("another card")
)

# Define server logic
server <- function(input, output) {
  
}

# Run the app
shinyApp(ui = ui, server = server)

