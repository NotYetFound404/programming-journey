using System;

public class Pal
{
    public static void Main()
    {
        // Local test input
        int x = 555;

        PalindromeSol solution = new PalindromeSol();
        bool result = solution.IsPalindrome(x);

        Console.WriteLine(result); // Expected: True
    }
}

public class PalindromeSol
{
    public bool IsPalindrome(int x)
    {
        // Edge cases
        if (x < 0) return false; 
        if (x == 0) return true;

        int original = x;   // Preserve the original value
        int reversed = 0;   // Will hold the reversed number

        while (x != 0)
        {
            int lastDigit = x % 10;          // Extract last digit
            reversed = reversed * 10 + lastDigit; // Append digit
            x = x / 10;                      // Remove last digit
        }
        // Compare original number with its reverse
        return original == reversed;
    }

}
