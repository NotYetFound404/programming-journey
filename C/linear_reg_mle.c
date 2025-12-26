#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define PI 3.141592653589793

typedef struct {
    double *data;
    int rows;
    int cols;
} Matrix;

typedef struct {
    double *coefficients;
    double sigma_squared;
    double log_likelihood;
} MLE_Result;

Matrix matrix_create(int rows, int cols) {
    Matrix m;
    m.rows = rows;
    m.cols = cols;
    m.data = (double *)malloc(rows * cols * sizeof(double));
    return m;
}

void matrix_free(Matrix m) {
    free(m.data);
}

Matrix matrix_transpose(Matrix m) {
    Matrix result = matrix_create(m.cols, m.rows);
    for (int i = 0; i < m.rows; i++) {
        for (int j = 0; j < m.cols; j++) {
            result.data[j * result.cols + i] = m.data[i * m.cols + j];
        }
    }
    return result;
}

Matrix matrix_multiply(Matrix a, Matrix b) {
    if (a.cols != b.rows) {
        printf("Matrix dimension mismatch!\n");
        exit(1);
    }
    Matrix result = matrix_create(a.rows, b.cols);
    for (int i = 0; i < a.rows; i++) {
        for (int j = 0; j < b.cols; j++) {
            result.data[i * result.cols + j] = 0;
            for (int k = 0; k < a.cols; k++) {
                result.data[i * result.cols + j] +=
                    a.data[i * a.cols + k] * b.data[k * b.cols + j];
            }
        }
    }
    return result;
}

Matrix matrix_inverse(Matrix m) {
    // Simplified version - for production use a robust library
    if (m.rows != m.cols || m.rows != 2) {
        printf("Only 2x2 matrix inversion implemented for simplicity\n");
        exit(1);
    }

    double det = m.data[0] * m.data[3] - m.data[1] * m.data[2];
    if (det == 0) {
        printf("Matrix is singular\n");
        exit(1);
    }

    Matrix inv = matrix_create(2, 2);
    inv.data[0] = m.data[3] / det;
    inv.data[1] = -m.data[1] / det;
    inv.data[2] = -m.data[2] / det;
    inv.data[3] = m.data[0] / det;

    return inv;
}

double calculate_log_likelihood(Matrix X, Matrix y, Matrix beta, double sigma_sq) {
    int n = y.rows;
    double log_likelihood = 0.0;

    // Calculate residuals: y - Xβ
    Matrix Xb = matrix_multiply(X, beta);
    double SSE = 0.0; // Sum of squared errors
    for (int i = 0; i < n; i++) {
        double residual = y.data[i] - Xb.data[i];
        SSE += residual * residual;
    }
    matrix_free(Xb);

    // Calculate log-likelihood
    log_likelihood = -n/2.0 * log(2 * PI * sigma_sq) - SSE/(2 * sigma_sq);

    return log_likelihood;
}

MLE_Result mle_linear_regression(Matrix X, Matrix y) {
    MLE_Result result;
    int n = X.rows;
    int p = X.cols;

    // Calculate β = (XᵀX)⁻¹Xᵀy
    Matrix Xt = matrix_transpose(X);
    Matrix XtX = matrix_multiply(Xt, X);
    Matrix XtX_inv = matrix_inverse(XtX);
    Matrix Xty = matrix_multiply(Xt, y);
    Matrix beta = matrix_multiply(XtX_inv, Xty);

    // Calculate σ² = (y - Xβ)ᵀ(y - Xβ)/n
    Matrix Xb = matrix_multiply(X, beta);
    double SSE = 0.0;
    for (int i = 0; i < n; i++) {
        double residual = y.data[i] - Xb.data[i];
        SSE += residual * residual;
    }
    double sigma_sq = SSE / n;

    // Calculate log-likelihood
    double log_likelihood = calculate_log_likelihood(X, y, beta, sigma_sq);

    // Store results
    result.coefficients = (double *)malloc(p * sizeof(double));
    for (int i = 0; i < p; i++) {
        result.coefficients[i] = beta.data[i];
    }
    result.sigma_squared = sigma_sq;
    result.log_likelihood = log_likelihood;

    // Clean up
    matrix_free(Xt);
    matrix_free(XtX);
    matrix_free(XtX_inv);
    matrix_free(Xty);
    matrix_free(beta);
    matrix_free(Xb);

    return result;
}

int main() {
    // Example data (intercept + one predictor)
    double x_data[] = {1, 1, 1, 1, 1,   // intercept column
                       1, 2, 3, 4, 5};  // predictor column
    double y_data[] = {2, 4, 5, 4, 5};

    // double x_data[] = {1, 2, 3, 4, 5};
    // double y_data[] = {2, 4, 5, 4, 5};

    Matrix X = matrix_create(5, 2);
    Matrix y = matrix_create(5, 1);

    // Fill matrices
    for (int i = 0; i < 5; i++) {
        X.data[i * 2] = x_data[i];
        X.data[i * 2 + 1] = x_data[i + 5];
        y.data[i] = y_data[i];
    }

    // Perform MLE
    MLE_Result result = mle_linear_regression(X, y);

    // Print results
    printf("MLE Results:\n");
    printf("Intercept (β0): %.4f\n", result.coefficients[0]);
    printf("Slope (β1): %.4f\n", result.coefficients[1]);
    printf("Error variance (σ²): %.4f\n", result.sigma_squared);
    printf("Log-likelihood: %.4f\n", result.log_likelihood);

    // Clean up
    free(result.coefficients);
    matrix_free(X);
    matrix_free(y);

    return 0;
}