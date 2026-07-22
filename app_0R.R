library(shiny)
library(bslib)

# Define UI for app that draws a histogram ----
ui <- page_sidebar(
  # App title ----
  title = "First lamina x site!",
  # Sidebar panel for inputs ----
  sidebar = sidebar(
    # Input: Slider for the number of bins ----
    sliderInput(
      inputId = "bins",
      label = "Number of bins:",
      min = 1,
      max = 50,
      value = 30
    )
  ),
  # Output: Histogram ----
  plotOutput(outputId = "distPlot")

)


server <- function(input, output) {
  
  output$distPlot <- renderPlot({
    x <- faithful$waiting
    bins <- seq(min(x), max(x), length.out = input$bins+1)
    
    hist(x, breaks=bins,
         col="violet",
         border= "white",
         xlab= "waiting time in minutes",
         main= "histogram of waiting times")
    
    })
}
  
  
shinyApp(ui=ui, server=server)
  