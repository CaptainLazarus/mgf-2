#include <stdio.h>

int power(int base, int exp) {
    int result = 1;
    while (exp > 0) {
        result *= base;
        exp--;
    }
    return result;
}

int main() {
    int n, originalNum, remainder, result = 0, n_digits = 0;

    printf("Enter an integer: ");
    scanf("%d", &n);

    originalNum = n;
    while (originalNum != 0) {
        originalNum /= 10;
        n_digits++;
    }

    originalNum = n;
    while (originalNum != 0) {
        remainder = originalNum % 10;
        result += power(remainder, n_digits);
        originalNum /= 10;
    }

    if (result == n)
        printf("%d is an Armstrong number.\n", n);
    else
        printf("%d is not an Armstrong number.\n", n);

    return 0;
}
