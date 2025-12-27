// var first = 0;
// var second = 10;

// int[] answer = new int[] { first, second };

// foreach(var value in answer){
//     Console.WriteLine(value);
// }


// //Palindrome base code
// int A = 1221;
// int Reversed = 0;
// // var test = A % Math.Pow(10, 2);
// // Console.WriteLine($"Test: {test}");
// for(var i=1; i<=4; i++)
// {
//     int Last = A % (int)Math.Pow(10, i);
//     if (i > 1)
//     {
//         Last = A % (int)Math.Pow(10, i) - A % (int)Math.Pow(10, i-1);
//     }
//     Last = Last / (int)Math.Pow(10, i-1);
//     Reversed = Last *(int)Math.Pow(10, 4-i) + Reversed; // + Reversed;
//     //Console.WriteLine(i);
//     Console.WriteLine($"Last: {Last}");
//     Console.WriteLine($"Reversed: {Reversed}");
// }
// bool answer = Reversed == A;
// Console.WriteLine($"Is Reversed equal to A: {answer}");


// // //Console.WriteLine(x);



// //Palindrome updated code v2.
// int A = -1221; //only works for i=4
// int Reversed = 0;
// bool? answer = null;
// if(A < 0) {
//     answer = false;

// } else {
// for(var i=1; i<=4; i++){
//     int Last = A % (int)Math.Pow(10, i);
//     if (i > 1){
//         Last = A % (int)Math.Pow(10, i) - A % (int)Math.Pow(10, i-1);
//     }
//     Last = Last / (int)Math.Pow(10, i-1);
//     Reversed = Last *(int)Math.Pow(10, 4-i) + Reversed;
// }
// answer = Reversed == A;
// }
// Console.WriteLine(answer);


//Palindrome updated code v3.
// int A = 1221; //only works for i=4
// int Reversed = 0;
// bool? answer = null;
// if(A < 0 | A == 0) {
//     answer = false;

// } else {
//     int temp = A;     // working copy
//     int digits = 0;
//     while (temp != 0)
//     {
//         digits++;
//         temp /= 10;
//     }
//     for(var i=1; i<=digits; i++){
//         int Last = A % (int)Math.Pow(10, i);
//         if (i > 1){
//             Last = A % (int)Math.Pow(10, i) - A % (int)Math.Pow(10, i-1);
//         }
//         Last = Last / (int)Math.Pow(10, i-1);
//         Reversed = Last *(int)Math.Pow(10, 4-i) + Reversed;
//     }
//     answer = Reversed == A;
// }
// Console.WriteLine(answer);

// Base Solution 1:
// public class PalindromeSol
// {
//     public bool IsPalindrome(int x)
//     {
//     int A = x; //only works for i=4
//     int Reversed = 0;
//     bool answer = false;
//     if(A < 0) {
//     answer = false;

//     } else {
//         if(A == 0){
//             answer = true;
//         }
//     int temp = A;     // working copy
//     int digits = 0;
//     while (temp != 0)
//     {
//     digits++;
//     temp /= 10;
//     }
//     for(var i=1; i<=digits; i++){
//     int Last = A % (int)Math.Pow(10, i);
//     if (i > 1){
//     Last = A % (int)Math.Pow(10, i) - A % (int)Math.Pow(10, i-1);
//     }
//     Last = Last / (int)Math.Pow(10, i-1);
//     Reversed = Last *(int)Math.Pow(10, digits-i) + Reversed;
//     }
//     answer = Reversed == A;
//     }
//         return answer;
//     }
// }



// //Palindrome adjusted
// int x = 121;
// int y = x; //Copy of X
// int reversed = 0;
// while (y != 0)
// {
//     Console.WriteLine($"y: {y}");
//     var lastDigit = y%10;
//     Console.WriteLine($"lastDigit: {lastDigit}");
//     reversed = reversed*10+lastDigit;
//     Console.WriteLine($"reversed: {reversed}");
//     y = y/10;
// }
// bool answer = x == reversed;
// Console.WriteLine($"answer: {answer}");

// // int i = 0;
// // while(i < 4)
// // {
// //     Console.WriteLine($"y: {y}");
// //     y = y % (int)Math.Pow(10, i);
// //     Console.WriteLine($"ith: {i}");
// //     i++;
// // }




// // for(var i=1; i<=4; i++)
// // {
// //     int Last = A % (int)Math.Pow(10, i);
// //     if (i > 1)
// //     {
// //         Last = A % (int)Math.Pow(10, i) - A % (int)Math.Pow(10, i-1);
// //     }
// //     Last = Last / (int)Math.Pow(10, i-1);
// //     Reversed = Last *(int)Math.Pow(10, 4-i) + Reversed; // + Reversed;
// //     //Console.WriteLine(i);
// //     Console.WriteLine($"Last: {Last}");
// //     Console.WriteLine($"Reversed: {Reversed}");
// // }
// // answer = Reversed == A;
// // Console.WriteLine($"Is Reversed equal to A: {answer}");