# Load required libraries
library(shiny)
library(data.table)
library(ggplot2)

# Load the dataset
data <- fread("energy_dataset.csv")

# Function to estimate energy project parameters based on closest initial investment
estimate_energy_project <- function(User_Initial_Investment_USD, User_Type_of_Renewable_Energy) {
  # Filter the dataset and select relevant columns
  subdata <- data[, .(Type_of_Renewable_Energy, Initial_Investment_USD, Financial_Incentives_USD,
                      GHG_Emission_Reduction_tCO2e, Air_Pollution_Reduction_Index, Jobs_Created)]
  
  # Filter subdata based on User_Type_of_Renewable_Energy
  subdata <- subdata[Type_of_Renewable_Energy == User_Type_of_Renewable_Energy]

  
  # Create empty lists to store estimated values
  Estimated_Financial_Incentives_USD <- numeric()
  Estimated_GHG_Emission_Reduction_tCO2e <- numeric()
  Estimated_Air_Pollution_Reduction_Index <- numeric()
  Estimated_Jobs_Created <- numeric()
  
  # Loop through each target variable and fit linear regression model
  for (target in c("Financial_Incentives_USD", "GHG_Emission_Reduction_tCO2e", 
                   "Air_Pollution_Reduction_Index", "Jobs_Created")) {
    # Fit linear regression model
    lm_model <- lm(as.formula(paste(target, "~ Initial_Investment_USD")), data = subdata)
    
    # Predict using the model for User_Initial_Investment_USD
    prediction <- predict(lm_model, newdata = data.table(Initial_Investment_USD = User_Initial_Investment_USD))
    
    # Store the predicted value based on the target variable
    switch(target,
           Financial_Incentives_USD = { Estimated_Financial_Incentives_USD <- prediction },
           GHG_Emission_Reduction_tCO2e = { Estimated_GHG_Emission_Reduction_tCO2e <- prediction },
           Air_Pollution_Reduction_Index = { Estimated_Air_Pollution_Reduction_Index <- prediction },
           Jobs_Created = { Estimated_Jobs_Created <- prediction }
    )
  }
  
  # Return estimated values as a list
  return(list(
    Estimated_Financial_Incentives_USD = Estimated_Financial_Incentives_USD,
    Estimated_GHG_Emission_Reduction_tCO2e = Estimated_GHG_Emission_Reduction_tCO2e,
    Estimated_Air_Pollution_Reduction_Index = Estimated_Air_Pollution_Reduction_Index,
    Estimated_Jobs_Created = Estimated_Jobs_Created
  ))
}

# Define UI for application
ui <- fluidPage(
  theme = "flatly",  # Apply a Bootstrap theme for improved styling
  
  titlePanel("Energy Project Estimation"),
  
  sidebarLayout(
    sidebarPanel(
      numericInput("investment", "Enter Initial Investment (USD):", value = 1000000),
      selectInput("renewable_type", "Select Type of Renewable Energy:",
                  choices = unique(data$Type_of_Renewable_Energy), selected = 1),
      actionButton("estimate_button", "Estimate", icon = icon("calculator"))
    ),
    
    mainPanel(
      h4("Estimated Project Parameters"),
      hr(),
      
      verbatimTextOutput("financial_output"),
      verbatimTextOutput("ghg_output"),
      verbatimTextOutput("air_pollution_output"),
      verbatimTextOutput("jobs_output"),
      
      plotOutput("financial_by_funding_plot")
    )
  )
)

# Define server logic
server <- function(input, output) {
  # Reactive expression to call estimate_energy_project function
  estimated_values <- reactive({
    req(input$estimate_button)  # Ensure button is clicked
    estimate_energy_project(input$investment, input$renewable_type)
  })
  
  # Display estimated values in the UI
  output$financial_output <- renderPrint({
    paste("Estimated Financial Incentives USD: $", round(estimated_values()$Estimated_Financial_Incentives_USD, 2))
  })
  
  output$ghg_output <- renderPrint({
    paste("Estimated GHG Emission Reduction: ", round(estimated_values()$Estimated_GHG_Emission_Reduction_tCO2e, 2), " tCO2e")
  })
  
  output$air_pollution_output <- renderPrint({
    paste("Estimated Air Pollution Reduction Index: ", round(estimated_values()$Estimated_Air_Pollution_Reduction_Index, 2))
  })
  
  output$jobs_output <- renderPrint({
    paste("Estimated Jobs Created: ", round(estimated_values()$Estimated_Jobs_Created, 0))
  })
  
  # Plot Financial Incentives USD by Funding Sources
  output$financial_by_funding_plot <- renderPlot({
    subdata <- data[data$Type_of_Renewable_Energy == input$renewable_type, ]
    ggplot(subdata, aes(x = Funding_Sources, y = Financial_Incentives_USD)) +
      geom_bar(stat = "summary", fun = "mean", fill = "#2c3e50") +
      labs(title = paste("Financial Incentives USD by Funding Sources for", input$renewable_type),
           x = "Funding Sources",
           y = "Financial Incentives USD") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
}

# Run the application
shinyApp(ui = ui, server = server)

