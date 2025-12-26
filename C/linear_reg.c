#include <stdio.h>

void linear_regression(double x[], double y[], int n, double *a, double *b) {
    double sum_x = 0.0, sum_y = 0.0;
    double sum_xy = 0.0, sum_x2 = 0.0;

    for (int i = 0; i < n; i++) {
        sum_x += x[i];
        sum_y += y[i];
        sum_xy += x[i] * y[i];
        sum_x2 += x[i] * x[i];
    }

    double mean_x = sum_x / n;
    double mean_y = sum_y / n;

    *b = (sum_xy - n * mean_x * mean_y) / (sum_x2 - n * mean_x * mean_x);
    *a = mean_y - (*b) * mean_x;
}

int main() {
    double x[] = {1, 2, 3, 4, 5};
    double y[] = {2, 4, 5, 4, 5};
    int n = 5;

    double a, b;
    linear_regression(x, y, n, &a, &b);

    printf("Fitted line: y = %.2f + %.2f * x\n", a, b);
    return 0;
}
