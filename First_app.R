library(shiny)
library(bslib)

# define UI 

ui <- page_sidebar(
    title = "My first lamina X app",
    sidebar = (
        "some effects "
    ),
    sliderInput(
        inputId = "bins",
        label = "Number of bins",
        min = 1,
        max = 100,
        value = 50
    ),
    plotOutput(outputId = "distPlot"),
    value_box(
        title = "Value box",
        value = 100
    ),
    card("card")
    
)

# define server logic
server <- function(input, output) {
    output$distPlot <- renderPlot({
        x <- faithful$waiting
        bins <- seq(min(x), max(x), length.out = input$bins+1)
        hist(
            x, breaks = bins,
            xlab = "Waiting times for eruptions",
            main = "Histogram of waiting times"
            
        )
    })
    
}

shinyApp(ui = ui, server = server)