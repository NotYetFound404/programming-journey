#include <stdio.h>
#include <stdlib.h>
#include <math.h>

// Matrix structure
typedef struct {
    int rows;
    int cols;
    double *data;
} Matrix;

// Include the MLE implementation
// (previously defined code would go here)
typedef struct {
    double *beta;         // Coefficient vector
    double sigma_sq;      // Error variance
} Parameters;

typedef struct {
    double *grad_beta;    // Gradient for beta
    double grad_sigma_sq; // Gradient for sigma²
} Gradient;

typedef struct {
    Matrix info_matrix;   // Fisher information matrix
    double info_sigma_sq; // Fisher info for sigma²
} FisherInformation;

// Result structure to return
typedef struct {
    Parameters params;    // Final parameter estimates
    int iterations;       // Number of iterations performed
    double log_lik;       // Final log-likelihood value
    Matrix covariance;    // Covariance matrix (inverse of Fisher information)
    int converged;        // Whether the algorithm converged
} MLE_Result;

// Helper function to create a matrix
Matrix create_matrix(int rows, int cols) {
    Matrix mat;
    mat.rows = rows;
    mat.cols = cols;
    mat.data = (double*)malloc(rows * cols * sizeof(double));
    return mat;
}

// Helper function to free a matrix
void free_matrix(Matrix mat) {
    free(mat.data);
}

// Initialize parameters with reasonable starting values
Parameters initialize_parameters(int p) {
    Parameters params;
    params.beta = (double*)malloc(p * sizeof(double));
    for (int i = 0; i < p; i++) {
        params.beta[i] = 0.0;  // Start with zeros for beta
    }
    params.sigma_sq = 1.0;     // Start with unit variance
    return params;
}

// Calculate log-likelihood for linear regression
double log_likelihood(Matrix X, Matrix y, Parameters params) {
    int n = X.rows;
    int p = X.cols;

    // Calculate residuals: e = y - X*beta
    double *residuals = (double*)malloc(n * sizeof(double));
    for (int i = 0; i < n; i++) {
        residuals[i] = y.data[i];
        for (int j = 0; j < p; j++) {
            residuals[i] -= X.data[i * p + j] * params.beta[j];
        }
    }

    // Calculate sum of squared residuals
    double ssr = 0.0;
    for (int i = 0; i < n; i++) {
        ssr += residuals[i] * residuals[i];
    }

    // Calculate log-likelihood
    double ll = -0.5 * n * log(2 * M_PI) - 0.5 * n * log(params.sigma_sq) -
                0.5 * ssr / params.sigma_sq;

    free(residuals);
    return ll;
}

// Calculate gradient for parameters
Gradient calculate_gradient(Matrix X, Matrix y, Parameters params) {
    int n = X.rows;
    int p = X.cols;

    Gradient grad;
    grad.grad_beta = (double*)malloc(p * sizeof(double));
    for (int j = 0; j < p; j++) {
        grad.grad_beta[j] = 0.0;
    }

    // Calculate residuals: e = y - X*beta
    double *residuals = (double*)malloc(n * sizeof(double));
    for (int i = 0; i < n; i++) {
        residuals[i] = y.data[i];
        for (int j = 0; j < p; j++) {
            residuals[i] -= X.data[i * p + j] * params.beta[j];
        }
    }

    // Calculate gradient for beta: grad_beta = X'(y - X*beta)/sigma²
    for (int j = 0; j < p; j++) {
        for (int i = 0; i < n; i++) {
            grad.grad_beta[j] += X.data[i * p + j] * residuals[i];
        }
        grad.grad_beta[j] /= params.sigma_sq;
    }

    // Calculate gradient for sigma²:
    // grad_sigma_sq = -n/(2*sigma²) + (y - X*beta)'(y - X*beta)/(2*sigma⁴)
    double ssr = 0.0;
    for (int i = 0; i < n; i++) {
        ssr += residuals[i] * residuals[i];
    }
    grad.grad_sigma_sq = -n / (2.0 * params.sigma_sq) +
                         ssr / (2.0 * params.sigma_sq * params.sigma_sq);

    free(residuals);
    return grad;
}

// Calculate Fisher information matrix
FisherInformation calculate_fisher_info(Matrix X, Parameters params) {
    int n = X.rows;
    int p = X.cols;

    FisherInformation info;

    // For linear regression with normal errors:
    // Fisher info for beta is X'X/sigma²
    info.info_matrix = create_matrix(p, p);
    for (int i = 0; i < p; i++) {
        for (int j = 0; j < p; j++) {
            double sum = 0.0;
            for (int k = 0; k < n; k++) {
                sum += X.data[k * p + i] * X.data[k * p + j];
            }
            info.info_matrix.data[i * p + j] = sum / params.sigma_sq;
        }
    }

    // Fisher info for sigma² is n/(2*sigma⁴)
    info.info_sigma_sq = n / (2.0 * params.sigma_sq * params.sigma_sq);

    return info;
}

// Invert a matrix using Gauss-Jordan elimination
Matrix invert_matrix(Matrix A) {
    int n = A.rows;
    Matrix inv = create_matrix(n, n);

    // Create augmented matrix [A|I]
    Matrix aug = create_matrix(n, 2*n);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            aug.data[i * (2*n) + j] = A.data[i * n + j];
        }
        aug.data[i * (2*n) + n + i] = 1.0;
    }

    // Gauss-Jordan elimination
    for (int i = 0; i < n; i++) {
        // Find pivot (largest element in column)
        int pivot_row = i;
        double max_val = fabs(aug.data[i * (2*n) + i]);
        for (int k = i + 1; k < n; k++) {
            if (fabs(aug.data[k * (2*n) + i]) > max_val) {
                max_val = fabs(aug.data[k * (2*n) + i]);
                pivot_row = k;
            }
        }

        // Swap rows if needed
        if (pivot_row != i) {
            for (int j = 0; j < 2*n; j++) {
                double temp = aug.data[i * (2*n) + j];
                aug.data[i * (2*n) + j] = aug.data[pivot_row * (2*n) + j];
                aug.data[pivot_row * (2*n) + j] = temp;
            }
        }

        // Scale pivot row
        double pivot = aug.data[i * (2*n) + i];
        for (int j = 0; j < 2*n; j++) {
            aug.data[i * (2*n) + j] /= pivot;
        }

        // Eliminate other rows
        for (int k = 0; k < n; k++) {
            if (k != i) {
                double factor = aug.data[k * (2*n) + i];
                for (int j = 0; j < 2*n; j++) {
                    aug.data[k * (2*n) + j] -= factor * aug.data[i * (2*n) + j];
                }
            }
        }
    }

    // Extract inverse
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            inv.data[i * n + j] = aug.data[i * (2*n) + n + j];
        }
    }

    free_matrix(aug);
    return inv;
}

// Update parameters using Fisher scoring (Newton-Raphson with Fisher information)
Parameters update_parameters(Parameters current, FisherInformation info, Gradient grad) {
    Parameters new;
    int p = info.info_matrix.rows;
    new.beta = (double*)malloc(p * sizeof(double));

    // Invert Fisher information matrix for beta
    Matrix info_inv = invert_matrix(info.info_matrix);

    // Update beta: beta_new = beta_old + info_inv * grad_beta
    for (int i = 0; i < p; i++) {
        new.beta[i] = current.beta[i];
        for (int j = 0; j < p; j++) {
            new.beta[i] += info_inv.data[i * p + j] * grad.grad_beta[j];
        }
    }

    // Update sigma²: sigma²_new = sigma²_old + grad_sigma_sq / info_sigma_sq
    new.sigma_sq = current.sigma_sq + grad.grad_sigma_sq / info.info_sigma_sq;

    // Ensure sigma² remains positive
    if (new.sigma_sq <= 0) {
        new.sigma_sq = current.sigma_sq / 2.0;  // Fallback strategy
    }

    free_matrix(info_inv);
    return new;
}

// Check convergence
int has_converged(Parameters old, Parameters new, double tol) {
    int p = 0;
    // Get the size of the beta array by looking at how many elements have been allocated
    while (old.beta[p] != '\0' && p < 100) {  // Safety check to prevent infinite loop
        p++;
    }

    // Check convergence of beta
    for (int i = 0; i < p; i++) {
        if (fabs(new.beta[i] - old.beta[i]) > tol) {
            return 0;
        }
    }

    // Check convergence of sigma²
    if (fabs(new.sigma_sq - old.sigma_sq) > tol) {
        return 0;
    }

    return 1;
}

// Free memory for Parameters
void free_parameters(Parameters params) {
    free(params.beta);
}

// Free memory for Gradient
void free_gradient(Gradient grad) {
    free(grad.grad_beta);
}

// Free memory for FisherInformation
void free_fisher_info(FisherInformation info) {
    free_matrix(info.info_matrix);
}

// Main MLE function
MLE_Result mle_iterative(Matrix X, Matrix y) {
    Parameters current = initialize_parameters(X.cols);
    Parameters new;
    int iter = 0;
    int max_iter = 1000;
    double tolerance = 1e-6;

    do {
        // Calculate gradient and Fisher information
        Gradient grad = calculate_gradient(X, y, current);
        FisherInformation info = calculate_fisher_info(X, current);

        // Update parameters
        new = update_parameters(current, info, grad);

        // Check convergence
        if (has_converged(current, new, tolerance)) {
            free_gradient(grad);
            free_fisher_info(info);
            break;
        }

        // Free memory for old parameters
        free_parameters(current);
        current = new;

        // Free memory for gradient and information
        free_gradient(grad);
        free_fisher_info(info);

        iter++;
    } while (iter < max_iter);

    // Calculate final log-likelihood and covariance matrix
    double final_ll = log_likelihood(X, y, new);
    FisherInformation final_info = calculate_fisher_info(X, new);
    Matrix covariance = invert_matrix(final_info.info_matrix);

    // Package results
    MLE_Result result;
    result.params = new;
    result.iterations = iter;
    result.log_lik = final_ll;
    result.covariance = covariance;
    result.converged = (iter < max_iter);

    // Clean up
    free_fisher_info(final_info);

    return result;
}

// Function to create a simple linear regression dataset with known parameters
void create_sample_dataset(Matrix *X, Matrix *y, int n, double *true_beta, double true_sigma, int p) {
    // Initialize matrices
    *X = create_matrix(n, p);
    *y = create_matrix(n, 1);

    // Set seed for reproducibility
    srand(12345);

    // Generate predictors and response
    for (int i = 0; i < n; i++) {
        // First column is intercept
        X->data[i * p + 0] = 1.0;

        // Generate other predictors
        for (int j = 1; j < p; j++) {
            // Random values between -1 and 1
            X->data[i * p + j] = 2.0 * ((double)rand() / RAND_MAX) - 1.0;
        }

        // Calculate true mean
        double mean = 0.0;
        for (int j = 0; j < p; j++) {
            mean += X->data[i * p + j] * true_beta[j];
        }

        // Add normal error
        // Box-Muller transform for normal random variable
        double u1 = (double)rand() / RAND_MAX;
        double u2 = (double)rand() / RAND_MAX;
        double z = sqrt(-2.0 * log(u1)) * cos(2.0 * M_PI * u2);

        // Generate response
        y->data[i] = mean + true_sigma * z;
    }
}

// Main function to test the MLE implementation
int main() {
    // True parameters for data generation
    int n = 100;  // Sample size
    int p = 3;    // Number of predictors (including intercept)
    double true_beta[3] = {2.5, 1.5, -0.8};  // True coefficients
    double true_sigma = 1.2;  // True error std dev

    // Create sample dataset
    Matrix X, y;
    create_sample_dataset(&X, &y, n, true_beta, true_sigma, p);

    printf("Sample Dataset Created:\n");
    printf("- Sample size: %d\n", n);
    printf("- Predictors (including intercept): %d\n", p);
    printf("- True beta: [%.1f, %.1f, %.1f]\n", true_beta[0], true_beta[1], true_beta[2]);
    printf("- True sigma²: %.2f\n\n", true_sigma * true_sigma);

    // Print first few rows of data
    printf("First 5 rows of data:\n");
    printf("    X0    X1     X2      y\n");
    printf("-------------------------\n");
    for (int i = 0; i < 5 && i < n; i++) {
        printf("%6.2f %6.2f %6.2f %6.2f\n",
               X.data[i * p + 0], X.data[i * p + 1], X.data[i * p + 2], y.data[i]);
    }
    printf("\n");

    // Run MLE
    printf("Running MLE estimation...\n");
    MLE_Result result = mle_iterative(X, y);

    // Print results
    printf("\nMLE Results:\n");
    printf("- Converged: %s\n", result.converged ? "Yes" : "No");
    printf("- Iterations: %d\n", result.iterations);
    printf("- Log-likelihood: %.4f\n", result.log_lik);
    printf("- Estimated beta: [");
    for (int j = 0; j < p; j++) {
        printf("%.4f", result.params.beta[j]);
        if (j < p - 1) printf(", ");
    }
    printf("]\n");
    printf("- Estimated sigma²: %.4f\n\n", result.params.sigma_sq);

    // Print standard errors
    printf("Parameter Standard Errors:\n");
    for (int j = 0; j < p; j++) {
        double se = sqrt(result.covariance.data[j * p + j]);
        printf("- SE(beta_%d): %.4f\n", j, se);
    }
    printf("- SE(sigma²): %.4f\n\n", sqrt(1.0 / result.params.sigma_sq));

    // Compare with true values
    printf("Comparison with true values:\n");
    printf("Parameter   True    Estimate   Difference\n");
    printf("----------------------------------------\n");
    for (int j = 0; j < p; j++) {
        printf("beta_%d     %6.4f   %6.4f    %+6.4f\n",
               j, true_beta[j], result.params.beta[j],
               result.params.beta[j] - true_beta[j]);
    }
    printf("sigma²     %6.4f   %6.4f    %+6.4f\n",
           true_sigma * true_sigma, result.params.sigma_sq,
           result.params.sigma_sq - true_sigma * true_sigma);

    // Clean up
    free_matrix(X);
    free_matrix(y);
    free_parameters(result.params);
    free_matrix(result.covariance);

    return 0;
}