library(shiny)
library(bslib)

#User interface
ui <- page_sidebar(
  tittle = "My first Lamina X app",
  sidebar = sidebar("Some effects", position = "right"),
  sliderInput(
    "slider2",
    "Set value range",
    min = 0,
    max = 100,
    value = 50
  ),
  value_box(
    tittle = "Value box",
    value = 100,
    showcase = bsicons::bs_icon("bar-chart"),
    theme = "teal"
  ),
    card(),
    card("Another card")
    
  )


#Define server logic

server <- function(input, output){
  # output$distPlot <- renderPlot({
  #   x <- faithful$waiting
  #   bins <- seq(min(x), max(x), length.out = input$bins + 1)
  #   
  #   hist(x, breaks = bins, col = "#007bc2", border = "white",
  #        xlab = "Waiting time to next eruption (in mins)",
  #        main = "Histogram of waiting times")
  #   
  # })
  
}

#Run the app

shinyApp(ui = ui, server = server)

