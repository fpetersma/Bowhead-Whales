# A function that calculates the density
.density_GAM <- function(x, gam_fit, par) {
  # Description:
  #   Takes in a matrix of (x, y)-coordinates and calculates the density at 
  #   every one of them. So far only working for matrices of M x 2 format, for
  #   M is mesh size. 
  
  # Inputs:
  #   x - x & y coordinates of the grid and any additional spatial covariates
  #   f - the specified relation between D and the spatial covariates
  #   param - a vector of parameters corresponding to the provided density
  #     relation.
  
  # Outputs:
  #   D - a vector of densities per unit area
  
  # Match order to parameters
  gam_fit$coefficients <- par
  
  eta <- predict(gam_fit, data = model.matrix(gam_fit))
  
  D <- exp(eta) # linear in the exponent to ensure positive density
  
  if (any(D < 0)) {
    stop("Negative estimates for density!")
  }
  
  return(as.vector(D))
}



.gJano <- function(snr, par, det_function) {
  # Description:
  #   
  
  # Inputs:
  #   
  # Outputs:
  
  U <- par["U"]
  B <- par["B"]
  Q <- par["Q"]
  L <- 0
  
  # Input checks
  if (U < 0 | U > 1) {stop("The upper limit U should be between 0 and 1!")}
  if (B <= 0) {stop("The inflection point parameter B should be positive!")}
  if (Q <= 1) {stop("The growth parameter Q should be larger than 1!")}
  
  
  g <- U - (U - L) * exp(-(B / 1000) * (snr ^ Q)) # B divided by 1000 to improve convergence

  return(g)
}

.gHN <- function(distances, par) {
  g0 <- par["g0"]
  sigma <- par["sigma"]
  
  if (g0 <= 0) {stop("The g0 parameter B should be positive!")}
  if (sigma <= 0) {stop("The range parameter sigma should be positive!")}
  
  g <- g0 * exp(- distances ^ 2 / (2 * sigma ^ 2))
  
  return(g)
}

# # Using row operations DONT USE, COLWISE VERSIN IS FASTER
# .detected <- function(probs, min_no_detections) {
#   
#   # Description:
#   
#   # Inputs:
#   
#   # Outputs:
#   
#   K <- ncol(probs)
#   
#   # Create all combinations of detections and non-detections
#   dummies <- as.matrix(expand.grid(rep(list(1:0), K)))
#   
#   # Only keep row with less than three detections
#   dummies <- dummies[rowSums(dummies) < min_no_detections, ]
#   
#   # Calculate the probabilities of detection animals less than the min_no_detections
#   temp <- apply(probs, 1, function(p1) {
#     p0 <- 1 - p1
#     out <- matrix(rep(p0, nrow(dummies)), nrow(dummies), byrow = TRUE)
#     temp <- matrix(rep(p1, nrow(dummies)), nrow(dummies), byrow = TRUE)
#     out[as.logical(dummies)] <- temp[as.logical(dummies)]
#     # Take the product of all probabilities
#     return(sum(apply(out, 1, prod)))
#   
#   })
#   # Calculate probability that it was detected at least twice
#   p. <- 1 - temp
#   
#   # When probabiltiies of detection are really small, the probability of not
#   # seen is 1, such that 1 - 1 - P(seen once) < 0. This is of course impossible,
#   # a probability can never be negative, so I now simply set everything < 0
#   # equal to zero. Not sure if this is a very nice way to handle this.
#   p.[p. < 0] <- 0
#   
#   return(p.)
# }

# Using column operations (should be faster)
.detected <- function(probs, min_no_detections) {
  
  # Description:
  
  # Inputs:
  
  # Outputs:
  
  probs <- t(probs)
  
  K <- nrow(probs)
  
  # Create all combinations of detections and non-detections
  dummies <- t(expand.grid(rep(list(1:0), K)))
  
  # Only keep row with less than 'min_no_detections' detections
  dummies <- dummies[, Rfast::colsums(dummies) < min_no_detections]
  
  # Calculate the probabilities of detection animals less than the min_no_detections
  temp <- apply(probs, 2, function(p1) {
    p0 <- 1 - p1
    out <- matrix(rep(p0, ncol(dummies)), nrow = nrow(dummies), byrow = FALSE)
    p1_m <- matrix(rep(p1, ncol(dummies)), nrow = nrow(dummies), byrow = FALSE)
    out[as.logical(dummies)] <- p1_m[as.logical(dummies)]
    # Take the product of all probabilities
    return(sum(Rfast::colprods(out)))
    
  })
  # Calculate probability that it was detected at least twice
  p. <- 1 - temp
  
  # When probabiltiies of detection are really small, the probability of not
  # seen is 1, such that 1 - 1 - P(seen once) < 0. This is of course impossible,
  # a probability can never be negative, so I now simply set everything < 0
  # equal to zero. Not sure if this is a very nice way to handle this.
  p.[p. < 0] <- 0
  
  return(p.)
}
