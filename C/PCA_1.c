#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define N 5     // Number of samples
#define D 2     // Dimensions (2D input)

// Center data by subtracting column-wise mean
void center_data(double data[N][D]) {
    double mean[D] = {0};

    for (int j = 0; j < D; j++) {
        for (int i = 0; i < N; i++) {
            mean[j] += data[i][j];
        }
        mean[j] /= N;
    }

    for (int j = 0; j < D; j++) {
        for (int i = 0; i < N; i++) {
            data[i][j] -= mean[j];
        }
    }
}

// Compute covariance matrix of centered data (D x D)
void compute_covariance(double data[N][D], double cov[D][D]) {
    for (int i = 0; i < D; i++) {
        for (int j = 0; j < D; j++) {
            cov[i][j] = 0;
            for (int k = 0; k < N; k++) {
                cov[i][j] += data[k][i] * data[k][j];
            }
            cov[i][j] /= (N - 1);
        }
    }
}

// Power iteration to get dominant eigenvector of 2x2 matrix
void power_iteration(double matrix[D][D], double eigenvector[D], int iterations) {
    // Start with a random vector
    eigenvector[0] = 1.0;
    eigenvector[1] = 1.0;

    for (int it = 0; it < iterations; it++) {
        double temp[D] = {0};
        for (int i = 0; i < D; i++) {
            for (int j = 0; j < D; j++) {
                temp[i] += matrix[i][j] * eigenvector[j];
            }
        }

        // Normalize
        double norm = sqrt(temp[0]*temp[0] + temp[1]*temp[1]);
        for (int i = 0; i < D; i++) {
            eigenvector[i] = temp[i] / norm;
        }
    }
}

// Project data onto a principal component
void project_data(double data[N][D], double eigenvector[D], double projection[N]) {
    for (int i = 0; i < N; i++) {
        projection[i] = 0;
        for (int j = 0; j < D; j++) {
            projection[i] += data[i][j] * eigenvector[j];
        }
    }
}

int main() {
    double data[N][D] = {
        {2.5, 2.4},
        {0.5, 0.7},
        {2.2, 2.9},
        {1.9, 2.2},
        {3.1, 3.0}
    };

    center_data(data);

    double cov[D][D];
    compute_covariance(data, cov);

    double principal_component[D];
    power_iteration(cov, principal_component, 100);

    double projection[N];
    project_data(data, principal_component, projection);

    printf("Top principal component: [%.4f, %.4f]\n", principal_component[0], principal_component[1]);
    printf("Projected data:\n");
    for (int i = 0; i < N; i++) {
        printf("%.4f\n", projection[i]);
    }

    return 0;
}
