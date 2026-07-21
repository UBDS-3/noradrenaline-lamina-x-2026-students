library(shiny)
library(bslib)

# User interface
ui <- page_sidebar(
  title = "My first Lamina X app",
  sidebar = sidebar(
    "Selectors", position = "left", 
      sliderInput(
        inputId = "bins",
        label = "Number of bins:",
        min = 1,
        max = 100,
        value = 50,
      )
    ),
    plotOutput(outputId = "distPlot")
)

# Define server logic

server <- function(input, output) {
  output$distPlot <- renderPlot({
    x <- faithful$waiting
    bins <- seq(min(x), max(x), 
                length.out = input$bins + 1)
    hist(x, breaks = bins, 
         col = "blue", 
         border = "white",
         xlab = "Waiting time",
         main = "Histogram of waiting times")
    }
  )
}

# Run the app
shinyApp(ui = ui, server = server)
